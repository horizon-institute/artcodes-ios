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


extension UIView
{
	func makeCirclePath(bounds: CGRect) -> CGPathRef
	{
		return UIBezierPath(roundedRect: bounds, cornerRadius: bounds.width).CGPath
	}
	
	func circleReveal(speed: CFTimeInterval)
	{
		let mask = CAShapeLayer()
		mask.path = makeCirclePath(CGRect(x: bounds.midX, y: bounds.midY, width: 0, height: 0))
		mask.fillColor = UIColor.blackColor().CGColor
		
		layer.mask = mask
		
		CATransaction.begin()
		let animation = CABasicAnimation(keyPath: "path")
		animation.duration = speed
		animation.fillMode = kCAFillModeForwards
		animation.removedOnCompletion = false
		
		let size = max(bounds.width, bounds.height)
		let newPath = makeCirclePath(CGRect(x: bounds.midX - (size / 2), y: bounds.midY - (size / 2), width: size, height: size))
		animation.fromValue = mask.path
		animation.toValue = newPath
		
		CATransaction.setCompletionBlock() {
			self.layer.mask = nil;
		}
		
		mask.addAnimation(animation, forKey:"path")
		CATransaction.commit()
		
		hidden = false
	}
	
	func circleHide(speed: CFTimeInterval, altView: UIView? = nil)
	{
		let mask = CAShapeLayer()
		let size = max(bounds.width, bounds.height)
		mask.path = makeCirclePath(CGRect(x: bounds.midX - (size / 2), y: bounds.midY - (size / 2), width: size, height: size))
		mask.fillColor = UIColor.blackColor().CGColor
		
		layer.mask = mask
		
		CATransaction.begin()
		let animation = CABasicAnimation(keyPath: "path")
		animation.duration = speed
		animation.fillMode = kCAFillModeForwards
		animation.removedOnCompletion = false
		
		let newPath = makeCirclePath(CGRect(x: bounds.midX, y: bounds.midY, width: 0, height: 0))
		
		animation.fromValue = mask.path
		animation.toValue = newPath
		
		CATransaction.setCompletionBlock() {
			self.hidden = true
			self.layer.mask = nil
			if let view = altView
			{
				view.hidden = false
			}
		}
		mask.addAnimation(animation, forKey:"path")
		CATransaction.commit()
	}
}