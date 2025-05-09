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
import Foundation
import opencv2

class ImageBuffers {
    private var bgrBuffer: Mat = Mat()
    private var greyBuffer: Mat = Mat()
    private var overlayBuffer: Mat = Mat()
    private var overlayUsed: Bool = false
    private var bgrBufferInit: Bool = false
    private var greyBufferInit: Bool = false
    private var currentBufferIsGrey: Bool = false

    func setNewFrame(_ newFrameImage: Mat) {
        if newFrameImage.channels() == 1 {
            greyBuffer = newFrameImage
            currentBufferIsGrey = true
            greyBufferInit = true
        } else if newFrameImage.channels() == 3 || newFrameImage.channels() == 4 {
            bgrBuffer = newFrameImage
            currentBufferIsGrey = false
            bgrBufferInit = true
        }
    }

    var imageInBgr: Mat {
        createBgrBufferIfNeeded()
        if currentBufferIsGrey && greyBufferInit {
            Imgproc.cvtColor(src: greyBuffer, dst: bgrBuffer, code: bgrBuffer.channels() == 3 ? ColorConversionCodes.COLOR_GRAY2BGR : ColorConversionCodes.COLOR_GRAY2BGRA)
        }
        currentBufferIsGrey = false
        return bgrBuffer
    }

    var imageInGrey: Mat {
        createGreyBufferIfNeeded()
        if !currentBufferIsGrey && bgrBufferInit {
            Imgproc.cvtColor(src: bgrBuffer, dst: greyBuffer, code: bgrBuffer.channels() == 3 ? ColorConversionCodes.COLOR_BGR2GRAY : ColorConversionCodes.COLOR_BGRA2GRAY)
        }
        currentBufferIsGrey = true
        return greyBuffer
    }

    var overlay: Mat {
        if overlayBuffer.rows() == 0 {
            overlayBuffer = Mat(rows: image.rows(), cols: image.cols(), type: CvType.CV_8UC4)
            overlayUsed = true
        } else if !overlayUsed {
            overlayBuffer.setTo(scalar: Scalar(0, 0, 0, 0))
            overlayUsed = true
        }
        return overlayBuffer
    }

    func clearOverlay() {
        overlayUsed = false
    }

    var hasOverlay: Bool {
        return overlayUsed
    }

    var image: Mat {
        if currentBufferIsGrey && greyBufferInit {
            return greyBuffer
        } else if bgrBufferInit {
            return bgrBuffer
        }
        return Mat()
    }

    var outputBufferForBgr: Mat {
        createBgrBufferIfNeeded()
        return bgrBuffer
    }

    var outputBufferForGrey: Mat {
        createGreyBufferIfNeeded()
        return greyBuffer
    }

    func setOutputAsImage(_ output: Mat) {
        if greyBufferInit && output.dataPointer() == greyBuffer.dataPointer() {
            currentBufferIsGrey = true
        } else if bgrBufferInit && output.dataPointer() == bgrBuffer.dataPointer() {
            currentBufferIsGrey = false
        } else {
            setNewFrame(output)
        }
    }

    private func createBgrBufferIfNeeded() {
        if !bgrBufferInit && greyBufferInit {
            bgrBuffer = Mat(rows: greyBuffer.rows(), cols: greyBuffer.cols(), type: CvType.CV_8UC3)
            bgrBufferInit = true
        }
    }

    private func createGreyBufferIfNeeded() {
        if !greyBufferInit && bgrBufferInit {
            greyBuffer = Mat(rows: bgrBuffer.rows(), cols: bgrBuffer.cols(), type: CvType.CV_8UC1)
            greyBufferInit = true
        }
    }
}
