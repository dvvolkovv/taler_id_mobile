package tirol.taler.taler_id_mobile

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import android.graphics.BitmapFactory
import com.cloudwebrtc.webrtc.video.LocalVideoTrack
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.segmentation.Segmentation
import com.google.mlkit.vision.segmentation.SegmentationMask
import com.google.mlkit.vision.segmentation.selfie.SelfieSegmenterOptions
import org.webrtc.JavaI420Buffer
import org.webrtc.VideoFrame
import java.io.ByteArrayOutputStream
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

    // Segmentation mask cache (reused across frames)
    private var lastMaskBitmap: Bitmap? = null
    private var frameCount = 0

    // Cached scaled background (avoid recreating every frame)
    private var scaledBackground: Bitmap? = null
    private var scaledBgWidth = 0
    private var scaledBgHeight = 0

    // Run segmentation every N frames; apply last mask on every frame
    private val SEGMENTATION_INTERVAL = 3

    // Reusable paint objects
    private val paint = Paint(Paint.FILTER_BITMAP_FLAG)
    private val maskPaint = Paint(Paint.FILTER_BITMAP_FLAG).apply {
        xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_IN)
    }

    // Reusable NV21 buffer
    private var nv21Buffer: ByteArray? = null
    private var jpegStream = ByteArrayOutputStream(64 * 1024)

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
            // Convert current frame to bitmap (at processing resolution)
            val bitmap = i420ToBitmap(i420, width, height)
            if (bitmap == null) {
                i420.release()
                return frame
            }

            // Run segmentation periodically (every Nth frame)
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

            // Apply effect: background + person (masked by segmentation) on every frame
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

    private fun updateMaskBitmap(mask: SegmentationMask, targetW: Int, targetH: Int) {
        val w = mask.width
        val h = mask.height
        val buf = mask.buffer
        buf.rewind()

        // Create alpha mask as ARGB bitmap (white with variable alpha = person confidence)
        val pixels = IntArray(w * h)
        for (i in pixels.indices) {
            val conf = (buf.float * 255).toInt().coerceIn(0, 255)
            pixels[i] = (conf shl 24) or 0x00FFFFFF
        }

        val rawMask = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        rawMask.setPixels(pixels, 0, w, 0, 0, w, h)

        // Scale to target dimensions
        lastMaskBitmap?.recycle()
        lastMaskBitmap = Bitmap.createScaledBitmap(rawMask, targetW, targetH, true)
        rawMask.recycle()
    }

    private fun applyEffectCanvas(source: Bitmap, mask: Bitmap, width: Int, height: Int): Bitmap {
        // Get background
        val bg = when (effectType) {
            EffectType.BLUR -> blurBitmap(source)
            EffectType.BACKGROUND -> getScaledBackground(width, height) ?: return source
        }

        // Compositing with Canvas:
        // 1. Start with background
        // 2. Layer person (source masked by segmentation) on top
        val result = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(result)

        // Draw background
        if (bg.width == width && bg.height == height) {
            canvas.drawBitmap(bg, 0f, 0f, paint)
        } else {
            canvas.drawBitmap(bg, Rect(0, 0, bg.width, bg.height), Rect(0, 0, width, height), paint)
        }

        // Draw person with mask
        val saveCount = canvas.saveLayer(0f, 0f, width.toFloat(), height.toFloat(), null)
        canvas.drawBitmap(source, 0f, 0f, paint)
        canvas.drawBitmap(mask, 0f, 0f, maskPaint) // DST_IN: keep source where mask has alpha
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
        val smallW = (source.width * 0.06f).toInt().coerceAtLeast(1)
        val smallH = (source.height * 0.06f).toInt().coerceAtLeast(1)
        val small = Bitmap.createScaledBitmap(source, smallW, smallH, true)
        val blurred = Bitmap.createScaledBitmap(small, source.width, source.height, true)
        small.recycle()
        return blurred
    }

    private fun i420ToBitmap(i420: VideoFrame.I420Buffer, width: Int, height: Int): Bitmap? {
        val nv21Size = width * height * 3 / 2
        val nv21 = if (nv21Buffer != null && nv21Buffer!!.size >= nv21Size) nv21Buffer!! else ByteArray(nv21Size).also { nv21Buffer = it }

        val yPlane = i420.dataY
        val uPlane = i420.dataU
        val vPlane = i420.dataV
        val strideY = i420.strideY
        val strideU = i420.strideU
        val strideV = i420.strideV

        // Copy Y plane
        if (strideY == width) {
            yPlane.position(0)
            yPlane.get(nv21, 0, width * height)
        } else {
            for (row in 0 until height) {
                yPlane.position(row * strideY)
                yPlane.get(nv21, row * width, width)
            }
        }

        // Interleave V and U for NV21
        val chromaW = width / 2
        val chromaH = height / 2
        var offset = width * height
        for (row in 0 until chromaH) {
            val vOff = row * strideV
            val uOff = row * strideU
            for (col in 0 until chromaW) {
                nv21[offset++] = vPlane.get(vOff + col)
                nv21[offset++] = uPlane.get(uOff + col)
            }
        }

        return try {
            val yuvImage = YuvImage(nv21, ImageFormat.NV21, width, height, null)
            jpegStream.reset()
            yuvImage.compressToJpeg(Rect(0, 0, width, height), 70, jpegStream)
            BitmapFactory.decodeByteArray(jpegStream.toByteArray(), 0, jpegStream.size())
        } catch (_: Exception) {
            null
        }
    }

    private fun bitmapToI420Buffer(bitmap: Bitmap, width: Int, height: Int): VideoFrame.I420Buffer {
        val argb = IntArray(width * height)
        bitmap.getPixels(argb, 0, width, 0, 0, width, height)

        val ySize = width * height
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
