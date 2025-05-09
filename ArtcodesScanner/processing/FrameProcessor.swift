/*
 * Artcodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2013-2015  The University of Nottingham
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU Affero General Public License as published
 *     by the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU Affero General Public License for more details.
 *
 *     You should have received a copy of the GNU Affero General Public License
 *     along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import UIKit
import AVFoundation
import opencv2

class FrameProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, UIAlertViewDelegate {
    
    var buffers: ImageBuffers!
    var settings: DetectionSettings!
    var isFocusing = false
    
    var pipeline: [ImageProcessor] = []
    var overlay: CALayer?
    let context = CIContext()
    
    func createPipeline(_ pipeline: [String], andSettings settings: DetectionSettings) {
        var newPipeline: [ImageProcessor] = []
        //var missingProcessors = false
        
        let imageProcessorRegistry = ImageProcessorRegistry.sharedInstance
        
        for pipelineString in pipeline {
            if let imageProcessor = imageProcessorRegistry.getProcessor(for: pipelineString, with: settings) {
                newPipeline.append(imageProcessor)
            } else {
                //missingProcessors = true
            }
        }
        
//        if missingProcessors {
//            let alert = UIAlertController(title: "Hmm...", message: "This experience may use features not available in this version of Artcodes. It might work fine but you can check the AppStore for updates.", preferredStyle: .alert)
//
//            alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
//
//            alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { action in
//                // Handle Update action (e.g., open App Store link)
//                if let url = URL(string: "itms-apps://itunes.apple.com/app/idYOUR_APP_ID") { // Replace YOUR_APP_ID
//                    UIApplication.shared.open(url)
//                }
//            }))
//            alert.show()
//        }
//        
        if newPipeline.isEmpty {
            // No pipeline supplied, use defaults:
            print("Using Default Pipeline")
            newPipeline.append(TileThreshold(settings: settings))
            newPipeline.append(MarkerDetector(settings: settings))
        }
        
        self.buffers = ImageBuffers()
        self.pipeline = newPipeline
        self.settings = settings
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !isFocusing {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
            
            if let mat = asMat(imageBuffer) {
                buffers.setNewFrame(mat)
                
                for imageProcessor in pipeline {
                    imageProcessor.process(buffers: buffers)
                }
                
                drawOverlay()
            }
            
            //End processing
            CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        }
    }
    
    func drawOverlay() {
        if let overlay = overlay {
            if buffers.hasOverlay {
                let dstImage = buffers.overlay.toCGImage()
                
                DispatchQueue.main.async {
                    overlay.contents = dstImage
                }
            } else {
                DispatchQueue.main.async {
                    overlay.contents = nil
                }
            }
        }
    }
    
    func asMat(_ imageBuffer: CVImageBuffer) -> Mat? {
        let image = CIImage(cvImageBuffer: imageBuffer)
        if let cgImage = context.createCGImage(image, from: image.extent) {
            return Mat(cgImage: cgImage)
        }
        
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let baseAddresses = CVPixelBufferGetBaseAddress(imageBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: baseAddresses,
            width: CVPixelBufferGetWidth(imageBuffer),
            height: CVPixelBufferGetHeight(imageBuffer),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(imageBuffer),
            space: colorSpace,
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue
        )
        if let quartzImage = context?.makeImage() {
            return Mat(cgImage: quartzImage)
        } else {
            return nil
        }
    }
}
