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

import Foundation

@objc
open class Experience: NSObject
{
	@objc open var id: String?
	@objc open var name: String?
	@objc open var icon: String?
	@objc open var image: String?
	@objc open var experienceDescription: String?
	@objc open var author: String?
	@objc open var originalID: String?
	
	@objc open var actions = [Action]()
	open var availabilities = [Availability]()
	@objc open var pipeline = [String]()
	@objc open var callback: (() -> Void)?
	
	@objc open var requestedAutoFocusMode: String?
	
	open var canCopy: Bool?
	
	// variables for mid-2018 layout update
	open var openWithoutUserInput: Bool?
	@objc open var backgroundColor: String?
	@objc open var foregroundColor: String?
	@objc open var highlightBackgroundColor: String?
	@objc open var highlightForegroundColor: String?
	@objc open var scanScreenTextTitle: String?
	@objc open var scanScreenTextDesciption: String?
	
	open var fullscreen: Bool?
	
	
	public override init()
	{
	}
	
	@objc open func actionForCode(_ code: String) -> Action?
	{
		for action in self.actions
		{
			for codeToTest in action.codes
			{
				if code == codeToTest
				{
					return action;
				}
			}
		}
		return nil;
	}
	
	@objc
	open func isFullscreen() -> Bool
	{
		return self.fullscreen ?? false
	}
}
