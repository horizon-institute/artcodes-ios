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
	open var id: String?
	open var name: String?
	open var icon: String?
	open var image: String?
	open var experienceDescription: String?
	open var author: String?
	open var originalID: String?
	
	open var actions = [Action]()
	open var availabilities = [Availability]()
	open var pipeline = [String]()
	open var callback: (() -> Void)?
	
	open var requestedAutoFocusMode: String?
	
	open var canCopy: Bool?
	
	public override init()
	{
	}
	
	open func actionForCode(_ code: String) -> Action?
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
}
