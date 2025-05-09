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

class TileThresholdFactory: ImageProcessorFactory {
    var name: String {
        return "tile"
    }
    
    func create(with settings: DetectionSettings) -> ImageProcessor {
        return TileThreshold(settings: settings)
    }
}

let CHANGE_TILES_AFTER_X_EMPTY_FRAMES = 5

class TileThreshold: ImageProcessor {
    let settings: DetectionSettings
    var framesSinceMarkerSeen: Int = CHANGE_TILES_AFTER_X_EMPTY_FRAMES
    var tiles: Int32 = 1
    
    init(settings: DetectionSettings) {
        self.settings = settings
    }
    
    func process(buffers: ImageBuffers) {
        let image = buffers.imageInGrey
        Imgproc.GaussianBlur(src: image, dst: image, ksize: Size2i(width: 3, height: 3), sigmaX: 0)
        
        if (self.settings.detected)
        {
            self.framesSinceMarkerSeen = 0;
        }
        else
        {
            self.framesSinceMarkerSeen += 1;
        }
        if (self.framesSinceMarkerSeen > CHANGE_TILES_AFTER_X_EMPTY_FRAMES)
        {
            self.tiles = (self.tiles % 9) + 1;
        }
        let tileHeight = image.size().height / self.tiles
        let tileWidth = image.size().width / self.tiles
        
        // Split image into tiles and apply threshold on each image tile separately.
        for tileRow in 0..<self.tiles {
            let startRow = tileRow * tileHeight
            var endRow: Int32
            if (tileRow < self.tiles - 1)
            {
                endRow = (tileRow + 1) * tileHeight
            }
            else
            {
                endRow = image.size().height
            }
            
            for tileCol in 0..<self.tiles {
                let startCol = tileCol * tileWidth
                let endCol: Int32
                if (tileCol < self.tiles - 1)
                {
                    endCol = (tileCol + 1) * tileWidth
                }
                else
                {
                    endCol = image.size().width
                }
                
                let tileMat = Mat(mat: image, rowRange: Range(start: startRow, end: endRow), colRange: Range(start: startCol, end: endCol))
                Imgproc.threshold(src: tileMat, dst: tileMat, thresh: 127, maxval: 255, type: .THRESH_OTSU)
            }
        }
        
        if(self.settings.displayThreshold == 0)
        {
            buffers.clearOverlay()
        }
        else
        {
            Imgproc.cvtColor(src: image, dst: buffers.overlay,code: .COLOR_GRAY2RGBA);
        }
    }
    
    var requiresBgraInput: Bool {
        return false
    }
}
