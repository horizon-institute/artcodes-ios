//
//  SceneDetails.swift
//  Artcodes
//
//  Created by Kevin Glover on 18/09/2024.
//  Copyright © 2024 Horizon DER Institute. All rights reserved.
//

import Foundation
import opencv2

class ImageSize {
    var width: Int
    var height: Int

    init(mat: Mat) {
        self.width = Int(mat.cols())
        self.height = Int(mat.rows())
    }
}

public class SceneDetails {
    var contours: NSMutableArray
    var hierarchy: Mat
    var sourceImageSize: ImageSize?

    init(contours: NSMutableArray, hierarchy: Mat, sourceImageSize: ImageSize) {
        self.contours = contours
        self.hierarchy = hierarchy
        self.sourceImageSize = sourceImageSize
    }
}
