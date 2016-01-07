//
//  ArrayExtension.swift
//  artcodes
//
//  Created by Kevin Glover on 6 Oct 2015.
//  Copyright © 2015 Horizon. All rights reserved.
//

import Foundation
import AssetsLibrary
import Photos

extension Array
{
	mutating func removeObject<U: Equatable>(object: U)
	{
		var index: Int?
		for (idx, objectToCompare) in enumerate()
		{
			if let to = objectToCompare as? U
			{
				if object == to
				{
					index = idx
				}
			}
		}
		
		if index != nil
		{
			self.removeAtIndex(index!)
		}
	}
}

extension UIImageView
{
	func loadURL(url: String?, closure: ((UIImage?) -> Void)? = nil)
	{
		if let imageURL = url
		{
			if let nsurl = NSURL(string: imageURL)
			{
				if nsurl.scheme == "assets-library"
				{
					let fetch = PHAsset.fetchAssetsWithALAssetURLs([nsurl], options: nil)
					
					if let asset = fetch.firstObject as? PHAsset
					{
						let manager = PHImageManager.defaultManager()
						
						let initialRequestOptions = PHImageRequestOptions()
						initialRequestOptions.synchronous = true
						initialRequestOptions.resizeMode = .Fast
						initialRequestOptions.deliveryMode = .FastFormat

						manager.requestImageForAsset(asset,
							targetSize: PHImageManagerMaximumSize,
							contentMode: .AspectFit,
							options: initialRequestOptions) { (finalResult, _) in
								self.image = finalResult
								closure?(finalResult)
						}
					}
				}
				else
				{
					if closure != nil
					{
						self.af_setImageWithURL(nsurl, placeholderImage: nil, filter: nil, imageTransition: .None, completion:{ (response) -> Void in
							closure?(response.result.value)
						})
					}
					else
					{
						self.af_setImageWithURL(nsurl)
					}
				}
			}
		}
		else if closure != nil
		{
			closure?(nil)
		}
	}
}