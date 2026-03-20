import Foundation
import WebRTC
import Vision
import CoreImage
import flutter_webrtc

/// Processes WebRTC video frames using Vision framework person segmentation.
/// Conforms to flutter_webrtc's ExternalVideoProcessingDelegate to intercept frames.
@available(iOS 15.0, *)
class VideoBackgroundProcessor: NSObject, ExternalVideoProcessingDelegate {

  enum EffectType {
    case blur
    case background(CIImage)
  }

  var effect: EffectType = .blur

  private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
  private let segmentationRequest: VNGeneratePersonSegmentationRequest
  private var lastMask: CIImage?
  private var frameCount: Int = 0
  private var pixelBufferPool: CVPixelBufferPool?
  private var poolWidth: Int = 0
  private var poolHeight: Int = 0

  override init() {
    segmentationRequest = VNGeneratePersonSegmentationRequest()
    segmentationRequest.qualityLevel = .balanced
    segmentationRequest.outputPixelFormat = kCVPixelFormatType_OneComponent8
    super.init()
  }

  func onFrame(_ frame: RTCVideoFrame) -> RTCVideoFrame {
    guard let cvBuffer = frame.buffer as? RTCCVPixelBuffer else {
      return frame
    }

    let pixelBuffer = cvBuffer.pixelBuffer
    frameCount += 1

    // Run segmentation every 2nd frame, reuse mask for odd frames
    if frameCount % 2 == 0 || lastMask == nil {
      let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
      do {
        try handler.perform([segmentationRequest])
        if let result = segmentationRequest.results?.first {
          lastMask = CIImage(cvPixelBuffer: result.pixelBuffer)
        }
      } catch {
        print("[VideoEffects] Segmentation error: \(error.localizedDescription)")
      }
    }

    guard let mask = lastMask else { return frame }

    let inputImage = CIImage(cvPixelBuffer: pixelBuffer)
    let inputExtent = inputImage.extent

    // Scale mask to match input dimensions
    let scaleX = inputExtent.width / mask.extent.width
    let scaleY = inputExtent.height / mask.extent.height
    let scaledMask = mask.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

    // Create background image based on effect type
    let backgroundImage: CIImage
    switch effect {
    case .blur:
      backgroundImage = inputImage
        .clampedToExtent()
        .applyingGaussianBlur(sigma: 18)
        .cropped(to: inputExtent)
    case .background(let bgImage):
      // Scale background to match input
      let bgScaleX = inputExtent.width / bgImage.extent.width
      let bgScaleY = inputExtent.height / bgImage.extent.height
      backgroundImage = bgImage.transformed(
        by: CGAffineTransform(scaleX: bgScaleX, y: bgScaleY)
      )
    }

    // Blend: person (foreground) over background using mask
    guard let blendFilter = CIFilter(name: "CIBlendWithMask") else { return frame }
    blendFilter.setValue(inputImage, forKey: kCIInputImageKey)
    blendFilter.setValue(backgroundImage, forKey: kCIInputBackgroundImageKey)
    blendFilter.setValue(scaledMask, forKey: kCIInputMaskImageKey)

    guard let output = blendFilter.outputImage else { return frame }

    // Render to a new pixel buffer
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let format = CVPixelBufferGetPixelFormatType(pixelBuffer)

    guard let outputBuffer = getPooledBuffer(width: width, height: height, format: format) else {
      return frame
    }
    ciContext.render(output, to: outputBuffer)

    let newBuffer = RTCCVPixelBuffer(pixelBuffer: outputBuffer)
    return RTCVideoFrame(buffer: newBuffer, rotation: frame.rotation, timeStampNs: frame.timeStampNs)
  }

  private func getPooledBuffer(width: Int, height: Int, format: OSType) -> CVPixelBuffer? {
    // Recreate pool if dimensions changed (e.g. camera flip)
    if pixelBufferPool == nil || poolWidth != width || poolHeight != height {
      pixelBufferPool = nil
      let poolAttrs: [String: Any] = [
        kCVPixelBufferPoolMinimumBufferCountKey as String: 3
      ]
      let bufferAttrs: [String: Any] = [
        kCVPixelBufferWidthKey as String: width,
        kCVPixelBufferHeightKey as String: height,
        kCVPixelBufferPixelFormatTypeKey as String: format,
        kCVPixelBufferIOSurfacePropertiesKey as String: [:] as [String: Any]
      ]
      CVPixelBufferPoolCreate(nil, poolAttrs as CFDictionary, bufferAttrs as CFDictionary, &pixelBufferPool)
      poolWidth = width
      poolHeight = height
    }
    guard let pool = pixelBufferPool else { return nil }
    var output: CVPixelBuffer?
    CVPixelBufferPoolCreatePixelBuffer(nil, pool, &output)
    return output
  }

  func cleanup() {
    lastMask = nil
    frameCount = 0
    pixelBufferPool = nil
  }
}
