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

let CHILD_NODE_INDEX = 2
let NEXT_SIBLING_NODE_INDEX = 0

class MarkerDetectorFactory: ImageProcessorFactory {
    var name: String {
        return "detect"
    }

    func create(with settings: DetectionSettings) -> ImageProcessor {
        return MarkerDetector(settings: settings)
    }
}

class MarkerDetector: ImageProcessor {
    var settings: DetectionSettings
    
    init(settings: DetectionSettings) {
        self.settings = settings
    }
    
    var requiresBgraInput: Bool {
        return false
    }
    
    func process(buffers: ImageBuffers) {
        let contours = NSMutableArray()
        let hierarchy = Mat()
        Imgproc.findContours(image: buffers.imageInGrey, contours: contours, hierarchy: hierarchy, mode: .RETR_TREE, method: .CHAIN_APPROX_SIMPLE)
        
        // detect markers
        if let contourArray = contours as? [[Point2i]] {
            let markers = findMarkers(hierarchy: hierarchy, contours: contourArray, buffers: buffers)
            
            print("Found markers \(markers.map({$0.name}))")
            
            settings.detected = markers.count > 0
            settings.handler.onMarkersDetected(markers: markers, scene: SceneDetails(contours: contours, hierarchy: hierarchy, sourceImageSize: ImageSize(mat: buffers.imageInGrey)))
        }
    }

    
    func findMarkers(hierarchy: Mat, contours: [[Point2i]], buffers: ImageBuffers) -> [Marker] {
        //let width = Double(buffers.image.cols())
        //let height = Double(buffers.image.rows())
        //let diagonalSize = sqrt(width * width + height * height)
        
        var markers: [Marker] = []
        
        for i in 0..<contours.count {
            let index = Int32(i)
            if let marker = createMarkerForNode(nodeIndex: index, hierarchy: hierarchy) {
                let markerKey = marker.name
                if settings.experience.actionForCode(code: markerKey) != nil {
                    if settings.validCodes.isEmpty || settings.validCodes.contains(markerKey) {
                        //let markerSize = area(contours[i])
                        markers.append(marker)
                    }
                }
            }
        }
        
        return markers
    }
    
    func getChild(at nodeIndex: Int32, hierarchy: Mat) -> Int32 {
        return Int32(hierarchy.get(row: 0, col: nodeIndex)[CHILD_NODE_INDEX])
    }
    
    func getNextSibling(at nodeIndex: Int32, hierarchy: Mat) -> Int32 {
        return Int32(hierarchy.get(row: 0, col: nodeIndex)[NEXT_SIBLING_NODE_INDEX])
    }
    
    func createMarkerForNode(nodeIndex: Int32, hierarchy: Mat) -> Marker? {
        var regions: [MarkerRegion] = []

        // Loop through the regions, verifying the value of each:
        var currentRegionIndex = getChild(at: nodeIndex, hierarchy: hierarchy)
        while currentRegionIndex >= 0 {
            let region = createRegionForNode(regionIndex: currentRegionIndex, hierarchy: hierarchy)
            if let region = region {
                if settings.ignoreEmptyRegions && region.value == 0 {
                    currentRegionIndex = getNextSibling(at: currentRegionIndex, hierarchy: hierarchy)
                    continue
                } else if regions.count >= settings.maxRegions {
                    // Too many regions.
                    return nil
                }
                regions.append(region)
            } else {
                return nil
            }
            currentRegionIndex = getNextSibling(at: currentRegionIndex, hierarchy: hierarchy)
        }
        
        if !regions.isEmpty {
            sortRegions(&regions)
            let marker = Marker(index: nodeIndex, regions: regions)
            if isValidRegionList(marker) {
                return marker
            }
        }
        return nil
    }

    func sortRegions(_ regions: inout [MarkerRegion]) {
        regions.sort { $0.value < $1.value }
    }

    func isValidRegionList(_ marker: Marker?) -> Bool {
        guard let marker = marker else {
            // No Code
            return false
        }
        
        if marker.regions.count < settings.minRegions {
            // Too Short
            return false
        } else if marker.regions.count > settings.maxRegions {
            // Too long
            return false
        }
        
        var numberOfEmptyRegions = 0
        for region in marker.regions {
            // Check if leaves are using in accepted range.
            if region.value > settings.maxRegionValue {
                return false // value is too Big
            } else if region.value == 0 {
                numberOfEmptyRegions += 1
                if numberOfEmptyRegions > settings.maxEmptyRegions {
                    return false // too many empty regions
                }
            }
        }
        
        return hasValidChecksum(marker: marker)
    }

    func hasValidChecksum(marker: Marker) -> Bool {
        if self.settings.checksum <= 1 {
            return true
        }
        var numberOfLeaves = 0
        for region in marker.regions {
            numberOfLeaves += region.value
        }
        return (numberOfLeaves % self.settings.checksum) == 0
    }

    func createRegionForNode(regionIndex: Int32, hierarchy: Mat) -> MarkerRegion? {
        var currentDotIndex: Int32 = getChild(at: regionIndex, hierarchy: hierarchy)
        if currentDotIndex < 0 && !(self.settings.ignoreEmptyRegions || self.settings.maxEmptyRegions > 0) {
            // There are no dots, and empty regions are not allowed.
            return nil
        }
        
        // Count all the dots and check if they are leaf nodes in the hierarchy:
        var dotCount = 0
        while currentDotIndex >= 0 {
            if isValidLeaf(nodeIndex: currentDotIndex, hierarchy: hierarchy) {
                dotCount += 1
                // Get the next dot index:
                currentDotIndex = getNextSibling(at: currentDotIndex, hierarchy: hierarchy)
                if dotCount > self.settings.maxRegionValue {
                    // Too many dots
                    return nil
                }
            } else {
                // Not a leaf
                return nil
            }
        }
        
        return MarkerRegion(index: regionIndex, value: dotCount)
    }

    func isValidLeaf(nodeIndex: Int32, hierarchy: Mat) -> Bool {
        let index = getChild(at: nodeIndex, hierarchy: hierarchy)
        return index < 0
    }

    func drawMarker(marker: String, index: Int32, overlay: Mat, contours: [[Point2i]], andHierarchy hierarchy: Mat) {
        // Color to draw contours
        let markerColor = Scalar(0, 255, 255, 255)
        let regionColor = Scalar(0, 128, 255, 255)
        let outlineColor = Scalar(0, 0, 0, 255)
        
        if self.settings.displayOutline > 0 {
            var currentRegionIndex = getChild(at: index, hierarchy: hierarchy)
            // Loop through the regions, verifying the value of each:
            if self.settings.displayOutline == 2 {
                while currentRegionIndex >= 0 {
                    Imgproc.drawContours(image: overlay, contours: contours, contourIdx: currentRegionIndex, color: outlineColor, thickness: 3, lineType: .LINE_8, hierarchy: hierarchy, maxLevel: 0, offset: Point(x: 0, y: 0))
                    Imgproc.drawContours(image: overlay, contours: contours, contourIdx: currentRegionIndex, color: regionColor, thickness: 2, lineType: .LINE_8, hierarchy: hierarchy, maxLevel: 0, offset: Point(x: 0, y: 0))
                    
                    // Get next region:
                    currentRegionIndex = getNextSibling(at: currentRegionIndex, hierarchy: hierarchy)
                }
            }
            
            Imgproc.drawContours(image: overlay, contours: contours, contourIdx: index, color: outlineColor, thickness: 3, lineType: .LINE_8, hierarchy: hierarchy, maxLevel: 0, offset: Point(x: 0, y: 0))
            Imgproc.drawContours(image: overlay, contours: contours, contourIdx: index, color: markerColor, thickness: 2, lineType: .LINE_8, hierarchy: hierarchy, maxLevel: 0, offset: Point(x: 0, y: 0))
        }
        
        // Draw code:
        if self.settings.displayText == 1 {
            let contour = contours[Int(index)]
            var left = Int32.max
            var top = Int32.max
            for point in contour {
                left = min(left, point.x)
                top = min(top, point.y)
            }
            let tl = Point2i(x: left, y: top)
            Imgproc.putText(img: overlay, text: marker, org: tl, fontFace: .FONT_HERSHEY_SIMPLEX, fontScale: 0.5, color: outlineColor, thickness: 3)
            Imgproc.putText(img: overlay, text: marker, org: tl, fontFace: .FONT_HERSHEY_SIMPLEX, fontScale: 0.5, color: markerColor, thickness: 2)
        }
    }
    
    func area(_ points: [Point2i]) -> Double {
        if points.count <= 1 { return 0 }
        var j = points.count - 1
        var area = 0.0
        for i in 0..<points.count {
            area = area + abs(Double(points[j].x + points[i].x) * Double(points[j].y - points[i].y))
            j=i
        }

        return area * 0.5
    }
    
    func convertMatToPointArrays(mats: [Mat]) -> [[Point2i]] {
        return mats.map { mat in
            var points: [Point2i] = []
            let data = mat.dataPointer()
            for i in 0..<Int(mat.rows()) {
                let rowPtr = data.advanced(by: i * mat.step1())
                for j in 0..<Int(mat.cols()) {
                    let pointData = rowPtr.advanced(by: j * MemoryLayout<Point2i>.size)
                    let point = pointData.withMemoryRebound(to: Point2i.self, capacity: 1) { $0.pointee }
                    points.append(point)
                }
            }

            return points
        }
    }
}
