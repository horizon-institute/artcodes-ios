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
	func loadURL(url: String?, aspect: Bool = false, progress: UIActivityIndicatorView? = nil)
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
								progress?.stopAnimating()
								
								if aspect
								{
									if let image = finalResult
									{
										let ratio = image.size.width / image.size.height
										
										let aspectConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Height, multiplier: ratio, constant: 0)
										self.addConstraint(aspectConstraint)
									}
								}
						}
					}
				}
				else
				{
					if aspect || progress != nil
					{
						self.af_setImageWithURL(nsurl, placeholderImage: nil, filter: nil, imageTransition: .None, completion:{ (response) -> Void in
							if let progressView = progress
							{
								progressView.stopAnimating()
							}
							if aspect
							{
								if let image = response.result.value
								{
									let ratio = image.size.width / image.size.height
									
									let aspectConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Height, multiplier: ratio, constant: 0)
									self.addConstraint(aspectConstraint)
								}
							}
						})
					}
					else
					{
						self.af_setImageWithURL(nsurl)
					}
				}
			}
		}
		else if let progressView = progress
		{
			progressView.stopAnimating()
		}
	}
}