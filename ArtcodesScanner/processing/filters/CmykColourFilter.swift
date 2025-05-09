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

enum CmykChannel:Int {
    case Cyan = 0
    case Magenta = 1
    case Yellow = 2
    case Black = 3
}

class CyanCmykFilterFactory: ImageProcessorFactory {
    var name: String { return "cyanKFilter" }
    func create(with settings: DetectionSettings) -> ImageProcessor {
        return CmykColourFilter(settings:settings, andChannel:.Cyan)
    }
}

class MagentaCmykFilterFactory: ImageProcessorFactory {
    var name: String { return "magentaKFilter" }
    func create(with settings: DetectionSettings) -> ImageProcessor {
        return CmykColourFilter(settings:settings, andChannel:.Magenta)
    }
}

class YellowCmykFilterFactory: ImageProcessorFactory {
    var name: String { return "yellowKFilter" }
    func create(with settings: DetectionSettings) -> ImageProcessor {
        return CmykColourFilter(settings:settings, andChannel:.Yellow)
    }
}

class BlackCmykFilterFactory: ImageProcessorFactory {
    var name: String { return "blackKFilter" }
    func create(with settings: DetectionSettings) -> ImageProcessor {
        return CmykColourFilter(settings:settings, andChannel:.Black)
    }
}


class CmykColourFilter: ImageProcessor {
    let channel: CmykChannel
    let settings: DetectionSettings
    
    init(settings: DetectionSettings, andChannel channel: CmykChannel) {
        self.settings = settings
        self.channel = channel
    }
    
    func process(buffers: ImageBuffers) {
        let colorImage = buffers.imageInBgr
        //cv::Mat greyscaleImage(colorImage.rows, colorImage.cols, CV_8UC1);
        let greyscaleImage = buffers.outputBufferForGrey
        
        if (colorImage.channels() >= 3)
        {
            for i in 0..<colorImage.rows() {
                for j in 0..<colorImage.cols() {
                    let colourPixel: (UInt8, UInt8, UInt8) = colorImage.at(row: i, col: j).v3c
                    
                    let k = 255 - max(colourPixel.0, colourPixel.1, colourPixel.2)
                    
                    switch self.channel {
                        case .Black:
                            greyscaleImage.at(row:i, col:j).v = k
                        case .Cyan:
                            greyscaleImage.at(row:i, col:j).v = (255-colourPixel.0-k)
                        case .Magenta:
                            greyscaleImage.at(row:i, col:j).v = (255-colourPixel.1-k)
                        case .Yellow:
                            greyscaleImage.at(row:i, col:j).v = (255-colourPixel.2-k)
                    }
                }
            }
        }
        
        buffers.setOutputAsImage(greyscaleImage)
    }
    
    var requiresBgraInput: Bool {
        return true
    }
}
