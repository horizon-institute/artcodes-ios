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
import UIKit

//extension Array
//{
//	mutating func removeObject<U: Equatable>(object: U)
//	{
//		var index: Int?
//		for (idx, objectToCompare) in self	{
//			if let to = objectToCompare as? U
//			{
//				if object == to
//				{
//					index = idx
//				}
//			}
//		}
//		
//		if index != nil
//		{
//            self.remove(at: index!)
//		}
//	}
//}
//
//extension UIButton
//{
//	private func actionHandleBlock(action:(() -> Void)? = nil)
//	{
//		struct __ {
//			static var action :(() -> Void)?
//		}
//		if action != nil {
//			__.action = action
//		} else {
//			__.action?()
//		}
//	}
//	
//	@objc private func triggerActionHandleBlock()
//	{
//		self.actionHandleBlock()
//	}
//	
//    func actionHandle(controlEvents control :UIControl.Event, ForAction action:@escaping () -> Void) {
//        self.actionHandleBlock(action: action)
//        self.addTarget(self, action: #selector(UIButton.triggerActionHandleBlock), for: control)
//	}
//}

extension UIImageView
{
	func loadURL(url: String?, closure: ((UIImage?) -> Void)? = nil)
	{
		if let imageURL = url
		{
			if let nsurl = URL(string: imageURL)
			{
                if closure != nil
                {
                    self.af.setImage(withURL: nsurl, placeholderImage: nil, filter: nil, imageTransition: .noTransition, completion:{ (response) -> Void in
                        closure?(response.value)
                    })
                }
                else
                {
                    self.af.setImage(withURL: nsurl)
                }
			}
		}
		else if closure != nil
		{
			closure?(nil)
		}
	}
}


extension UIColor
{
	convenience init(hex3: UInt, alpha: CGFloat = 1)
	{
		self.init(red: CGFloat((hex3 & 0xF00) >> 8) / 15,
		          green: CGFloat((hex3 & 0x0F0) >> 4) / 15,
		          blue: CGFloat(hex3 & 0x0F) / 15,
		          alpha: alpha)
	}
	
	convenience init(hex6: UInt, alpha: CGFloat = 1)
	{
		self.init(red: CGFloat((hex6 & 0xFF0000) >> 16) / 255,
		        green: CGFloat((hex6 & 0x00FF00) >> 8) / 255,
		        blue: CGFloat(hex6 & 0x0000FF) / 255,
		        alpha: alpha)
	}
}

extension UIView
{
    func makeCirclePath(bounds: CGRect) -> CGPath
	{
        return UIBezierPath(roundedRect: bounds, cornerRadius: bounds.width).cgPath
	}
	
	func circleReveal(speed: CFTimeInterval)
	{
		let mask = CAShapeLayer()
        mask.path = makeCirclePath(bounds: CGRect(x: bounds.midX, y: bounds.midY, width: 0, height: 0))
        mask.fillColor = UIColor.black.cgColor
		
		layer.mask = mask
		
		CATransaction.begin()
		let animation = CABasicAnimation(keyPath: "path")
		animation.duration = speed
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
		
		let size = max(bounds.width, bounds.height)
        let newPath = makeCirclePath(bounds: CGRect(x: bounds.midX - (size / 2), y: bounds.midY - (size / 2), width: size, height: size))
		animation.fromValue = mask.path
		animation.toValue = newPath
		
		CATransaction.setCompletionBlock() {
			self.layer.mask = nil;
		}
		
        mask.add(animation, forKey:"path")
		CATransaction.commit()
		
        isHidden = false
	}
	
	func circleHide(speed: CFTimeInterval, altView: UIView? = nil)
	{
		let mask = CAShapeLayer()
		let size = max(bounds.width, bounds.height)
        mask.path = makeCirclePath(bounds: CGRect(x: bounds.midX - (size / 2), y: bounds.midY - (size / 2), width: size, height: size))
        mask.fillColor = UIColor.black.cgColor
		
		layer.mask = mask
		
		CATransaction.begin()
		let animation = CABasicAnimation(keyPath: "path")
		animation.duration = speed
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
		
        let newPath = makeCirclePath(bounds: CGRect(x: bounds.midX, y: bounds.midY, width: 0, height: 0))
		
		animation.fromValue = mask.path
		animation.toValue = newPath
		
		CATransaction.setCompletionBlock() {
            self.isHidden = true
			self.layer.mask = nil
			if let view = altView
			{
                view.isHidden = false
			}
		}
        mask.add(animation, forKey:"path")
		CATransaction.commit()
	}
}
