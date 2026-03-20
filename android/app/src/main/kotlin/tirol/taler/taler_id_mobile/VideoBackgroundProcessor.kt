package tirol.taler.taler_id_mobile

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.BlurMaskFilter
import android.graphics.Rect
import com.cloudwebrtc.webrtc.video.LocalVideoTrack
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.segmentation.Segmentation
import com.google.mlkit.vision.segmentation.SegmentationMask
import com.google.mlkit.vision.segmentation.selfie.SelfieSegmenterOptions
import org.webrtc.JavaI420Buffer
import org.webrtc.VideoFrame
import java.nio.ByteBuffer
import java.util.concurrent.TimeUnit

class VideoBackgroundProcessor : LocalVideoTrack.ExternalVideoFrameProcessing {

    enum class EffectType { BLUR, BACKGROUND }

    var effectType = EffectType.BLUR
    var backgroundBitmap: Bitmap? = null

    private val segmenter = Segmentation.getClient(
        SelfieSegmenterOptions.Builder()
            .setDetectorMode(SelfieSegmenterOptions.STREAM_MODE)
            .build()
    )

    // Segmentation mask (smoothed, reused across frames)
    private var lastMaskBitmap: Bitmap? = null
    private var frameCount = 0

    // Cached scaled background
    private var scaledBackground: Bitmap? = null
    private var scaledBgWidth = 0
    private var scaledBgHeight = 0

    // Run segmentation every N frames; apply last mask on every frame
    private val SEGMENTATION_INTERVAL = 3

    // Reusable paint objects
    private val paint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG)
    private val maskPaint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG).apply {
        xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_IN)
    }

    // Reusable pixel buffers (avoid allocation per frame)
    private var argbBuffer: IntArray? = null

    override fun onFrame(frame: VideoFrame): VideoFrame {
        frameCount++

        // No mask yet — pass through until first segmentation completes
        if (lastMaskBitmap == null && frameCount % SEGMENTATION_INTERVAL != 1) {
            return frame
        }

        val buffer = frame.buffer
        val width = buffer.width
        val height = buffer.height

        val i420 = buffer.toI420() ?: return frame

        try {
            // Direct I420 → ARGB conversion (no JPEG compression!)
            val bitmap = i420ToBitmapDirect(i420, width, height)

            // Run segmentation periodically
            if (frameCount % SEGMENTATION_INTERVAL == 1 || lastMaskBitmap == null) {
                try {
                    val inputImage = InputImage.fromBitmap(bitmap, 0)
                    val mask = Tasks.await(segmenter.process(inputImage), 150, TimeUnit.MILLISECONDS)
                    updateMaskBitmap(mask, width, height)
                } catch (_: Exception) {
                    // Use last mask
                }
            }

            val maskBmp = lastMaskBitmap
            if (maskBmp == null) {
                bitmap.recycle()
                i420.release()
                return frame
            }

            // Apply effect on every frame with current mask
            val result = applyEffectCanvas(bitmap, maskBmp, width, height)
            bitmap.recycle()

            val resultBuffer = bitmapToI420Buffer(result, width, height)
            result.recycle()

            i420.release()
            return VideoFrame(resultBuffer, frame.rotation, frame.timestampNs)
        } catch (e: Exception) {
            i420.release()
            return frame
        }
    }

    /**
     * Direct I420 → ARGB Bitmap conversion without JPEG compression.
     * Eliminates compression artifacts at edges.
     */
    private fun i420ToBitmapDirect(i420: VideoFrame.I420Buffer, width: Int, height: Int): Bitmap {
        val size = width * height
        val argb = if (argbBuffer != null && argbBuffer!!.size >= size) argbBuffer!! else IntArray(size).also { argbBuffer = it }

        val yPlane = i420.dataY
        val uPlane = i420.dataU
        val vPlane = i420.dataV
        val strideY = i420.strideY
        val strideU = i420.strideU
        val strideV = i420.strideV

        for (row in 0 until height) {
            val yRowOffset = row * strideY
            val uvRow = row / 2
            val uRowOffset = uvRow * strideU
            val vRowOffset = uvRow * strideV
            val pixelRowOffset = row * width

            for (col in 0 until width) {
                val yVal = (yPlane.get(yRowOffset + col).toInt() and 0xFF)
                val uVal = (uPlane.get(uRowOffset + col / 2).toInt() and 0xFF) - 128
                val vVal = (vPlane.get(vRowOffset + col / 2).toInt() and 0xFF) - 128

                // YUV to RGB (BT.601)
                val r = (yVal + ((359 * vVal) shr 8)).coerceIn(0, 255)
                val g = (yVal - ((88 * uVal + 183 * vVal) shr 8)).coerceIn(0, 255)
                val b = (yVal + ((454 * uVal) shr 8)).coerceIn(0, 255)

                argb[pixelRowOffset + col] = (0xFF shl 24) or (r shl 16) or (g shl 8) or b
            }
        }

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        bitmap.setPixels(argb, 0, width, 0, 0, width, height)
        return bitmap
    }

    private fun updateMaskBitmap(mask: SegmentationMask, targetW: Int, targetH: Int) {
        val w = mask.width
        val h = mask.height
        val buf = mask.buffer
        buf.rewind()

        // Create alpha mask with confidence values
        val pixels = IntArray(w * h)
        for (i in pixels.indices) {
            val conf = (buf.float * 255).toInt().coerceIn(0, 255)
            pixels[i] = (conf shl 24) or 0x00FFFFFF
        }

        val rawMask = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        rawMask.setPixels(pixels, 0, w, 0, 0, w, h)

        // Scale to target dimensions with bilinear filtering
        val scaled = Bitmap.createScaledBitmap(rawMask, targetW, targetH, true)
        rawMask.recycle()

        // Smooth the mask edges: draw with BlurMaskFilter for feathered edges
        val smoothed = Bitmap.createBitmap(targetW, targetH, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(smoothed)

        // First pass: draw the mask slightly eroded (to avoid halo)
        val smoothPaint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG)
        canvas.drawBitmap(scaled, 0f, 0f, smoothPaint)

        // Second pass: blur the edges by drawing a slightly blurred version on top
        // Use a small-radius stack blur approach: scale down and back up
        val blurScale = 0.5f
        val smallW = (targetW * blurScale).toInt().coerceAtLeast(1)
        val smallH = (targetH * blurScale).toInt().coerceAtLeast(1)
        val smallMask = Bitmap.createScaledBitmap(scaled, smallW, smallH, true)
        val blurredMask = Bitmap.createScaledBitmap(smallMask, targetW, targetH, true)
        smallMask.recycle()
        scaled.recycle()

        // Blend: use the blurred mask (smoother edges) as the final mask
        smoothed.recycle()
        lastMaskBitmap?.recycle()
        lastMaskBitmap = blurredMask
    }

    private fun applyEffectCanvas(source: Bitmap, mask: Bitmap, width: Int, height: Int): Bitmap {
        val bg = when (effectType) {
            EffectType.BLUR -> blurBitmap(source)
            EffectType.BACKGROUND -> getScaledBackground(width, height) ?: return source
        }

        val result = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(result)

        // Draw background
        if (bg.width == width && bg.height == height) {
            canvas.drawBitmap(bg, 0f, 0f, paint)
        } else {
            canvas.drawBitmap(bg, Rect(0, 0, bg.width, bg.height), Rect(0, 0, width, height), paint)
        }

        // Draw person (source masked by segmentation) on top
        val saveCount = canvas.saveLayer(0f, 0f, width.toFloat(), height.toFloat(), null)
        canvas.drawBitmap(source, 0f, 0f, paint)
        canvas.drawBitmap(mask, 0f, 0f, maskPaint)
        canvas.restoreToCount(saveCount)

        if (effectType == EffectType.BLUR) {
            bg.recycle()
        }

        return result
    }

    private fun getScaledBackground(width: Int, height: Int): Bitmap? {
        val bgBmp = backgroundBitmap ?: return null
        if (scaledBackground != null && scaledBgWidth == width && scaledBgHeight == height) {
            return scaledBackground
        }
        scaledBackground?.recycle()
        scaledBackground = Bitmap.createScaledBitmap(bgBmp, width, height, true)
        scaledBgWidth = width
        scaledBgHeight = height
        return scaledBackground
    }

    private fun blurBitmap(source: Bitmap): Bitmap {
        // Strong blur via aggressive downscale + upscale
        val smallW = (source.width * 0.05f).toInt().coerceAtLeast(1)
        val smallH = (source.height * 0.05f).toInt().coerceAtLeast(1)
        val small = Bitmap.createScaledBitmap(source, smallW, smallH, true)
        val blurred = Bitmap.createScaledBitmap(small, source.width, source.height, true)
        small.recycle()
        return blurred
    }

    private fun bitmapToI420Buffer(bitmap: Bitmap, width: Int, height: Int): VideoFrame.I420Buffer {
        val size = width * height
        val argb = if (argbBuffer != null && argbBuffer!!.size >= size) argbBuffer!! else IntArray(size).also { argbBuffer = it }
        bitmap.getPixels(argb, 0, width, 0, 0, width, height)

        val ySize = size
        val uvSize = (width / 2) * (height / 2)
        val yData = ByteBuffer.allocateDirect(ySize)
        val uData = ByteBuffer.allocateDirect(uvSize)
        val vData = ByteBuffer.allocateDirect(uvSize)

        for (y in 0 until height) {
            val rowOffset = y * width
            for (x in 0 until width) {
                val pixel = argb[rowOffset + x]
                val r = (pixel shr 16) and 0xFF
                val g = (pixel shr 8) and 0xFF
                val b = pixel and 0xFF

                yData.put((((66 * r + 129 * g + 25 * b + 128) shr 8) + 16).coerceIn(0, 255).toByte())

                if (y % 2 == 0 && x % 2 == 0) {
                    uData.put((((-38 * r - 74 * g + 112 * b + 128) shr 8) + 128).coerceIn(0, 255).toByte())
                    vData.put((((112 * r - 94 * g - 18 * b + 128) shr 8) + 128).coerceIn(0, 255).toByte())
                }
            }
        }

        yData.flip()
        uData.flip()
        vData.flip()

        return JavaI420Buffer.wrap(
            width, height,
            yData, width,
            uData, width / 2,
            vData, width / 2,
            null
        )
    }

    fun cleanup() {
        lastMaskBitmap?.recycle()
        lastMaskBitmap = null
        scaledBackground?.recycle()
        scaledBackground = null
        frameCount = 0
    }
}
