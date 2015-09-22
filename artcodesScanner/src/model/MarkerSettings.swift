//
//  MarkerSettings.swift
//  artcodes
//
//  Created by Kevin Glover on 14/09/2015.
//  Copyright © 2015 Horizon. All rights reserved.
//

import Foundation

@objc
public class MarkerSettings: NSObject
{
    public var minRegions = 5
    public var maxRegions = 5
    public var maxRegionValue = 6
    public var checksumModulo = 3
    public var embeddedChecksum = false

    public func isValid(marker: NSArray?, withEmbeddedChecksum embeddedChecksum: NSNumber?) -> Bool
    {
        if let markerCode = marker as? [Int]
        {
            if markerCode.count < minRegions
            {
                return false
            }
            
            if markerCode.count > maxRegions
            {
                return false
            }
            
            for value in markerCode
            {
                if value > maxRegionValue
                {
                    return false
                }
            }
            
            // TODO
            //if (embeddedChecksum == null && !hasValidChecksum(markerCodes))
            //{
            //	return false; // Region Total not Divisable by checksumModulo
            //}
            //else if (this.embeddedChecksum && embeddedChecksum != null && !hasValidEmbeddedChecksum(markerCodes, embeddedChecksum))
            //{
            //	return false; // Region Total not Divisable by embeddedChecksum
            //}
            //else if (!this.embeddedChecksum && embeddedChecksum != null)
            //{
            // Embedded checksum is turned off yet one was provided to this function (this should never happen unless the settings are changed in the middle of detection)
            //	return false; // Embedded checksum markers are not valid.
            //}
            
            return true
        }
        return false
    }
}