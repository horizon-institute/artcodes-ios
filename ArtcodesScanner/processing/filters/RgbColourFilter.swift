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
import opencv2

enum BGRAChannel:Int {
    case Blue = 0
    case Green = 1
    case Red = 2
    case Alpha = 3
}

class RedRgbFilterFactory: ImageProcessorFactory {
    var name: String { return "redFilter" }
    func create(with settings: DetectionSettings) -> ImageProcessor {
        return RgbColourFilter(settings:settings, andChannel:.Red)
    }
}

class GreenRgbFilterFactory: ImageProcessorFactory {
    var name: String { return "greenFilter" }
    func create(with settings: DetectionSettings) -> ImageProcessor {
        return RgbColourFilter(settings:settings, andChannel:.Green)
    }
}

class BlueRgbFilterFactory: ImageProcessorFactory {
    var name: String { return "blueFilter" }
    func create(with settings: DetectionSettings) -> ImageProcessor {
        return RgbColourFilter(settings:settings, andChannel:.Blue)
    }
}


class RgbColourFilter: ImageProcessor {
    private var settings:DetectionSettings
    private var channel:BGRAChannel
    private var extraChannelBuffer:Mat?
    private var mix:IntVector?

    init(settings:DetectionSettings, andChannel channel:BGRAChannel) {
        self.settings = settings
        self.channel = channel
        self.extraChannelBuffer = nil
        self.mix = nil
    }

    var requiresBgraInput: Bool {
        return true
    }

    /*
    // avg 10-50ms on iPhone 6
    -(void) process:(ImageBuffers*) buffers
    {
        cv::vector<cv::Mat> bgra;
        cv::split(buffers.imageInBgr, bgra);
        // buffers.image = bgra.at(self.channel);
        [buffers setOutputAsImage:bgra.at(self.channel)];
    }
    */

    // avg <10ms on iPhone 6
    func process(buffers:ImageBuffers) {
        let colorImage = buffers.imageInBgr
        let greyOutputImage = buffers.outputBufferForGrey
        if self.extraChannelBuffer?.rows() == 0
        {
            if colorImage.channels() == 3
            {
                self.extraChannelBuffer = Mat(rows: colorImage.cols(), cols: colorImage.rows(), type: CvType.CV_8UC2)
            }
            else
            {
                self.extraChannelBuffer = Mat(rows: colorImage.cols(), cols: colorImage.rows(), type: CvType.CV_8UC3)
            }
        }

        if self.mix == nil
        {
            if colorImage.channels() == 3
            {
                if self.channel == .Red
                {
                    self.mix = IntVector([2, 0, 1, 1, 0, 2])
                }
                else if self.channel == .Green
                {
                    self.mix = IntVector([2, 1, 1, 0, 0, 2])
                }
                else if self.channel == .Blue
                {
                    self.mix = IntVector([2, 2, 1, 1, 0, 0])
                }
            }
            else if colorImage.channels() == 4
            {
                if self.channel == .Red
                {
                    self.mix = IntVector([2, 0, 1, 1, 0, 2, 3, 3])
                }
                else if self.channel == .Green
                {
                    self.mix = IntVector([2, 1, 1, 0, 0, 2, 3, 3])
                }
                else if self.channel == .Blue
                {
                    self.mix = IntVector([2, 2, 1, 1, 0, 0, 3, 3])
                }
            }
        }

        Core.mixChannels(src: [colorImage], dst: [greyOutputImage, self.extraChannelBuffer!], fromTo: self.mix!)
        
        buffers.setOutputAsImage(greyOutputImage)
    }
}
