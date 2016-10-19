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
public enum Match: Int
{
	case any
	case all
	case sequence
}

@objc
public class Action: NSObject
{
	public var name: String?
	public var url: String?
	public var codes = [String]()
	public var match = Match.any
	public var actionDescription: String?
	public var image: String?
	public var owner: String?
	public var showDetail = false
	
	public var framesRequired: Int?
	public var framesAwarded: Int?
	public var minimumSize: Double?
	
	public func nsMinimumSize() -> NSNumber
	{
		if let nonNilValue = self.minimumSize
		{
			return nonNilValue
		}
		else
		{
			return 0
		}
	}
	
	public var displayURL: String?
	{
		if let httpRange = url?.rangeOfString("http://")
		{
			return url?.substringFromIndex(httpRange.endIndex)
		}
		else if  let httpsRange = url?.rangeOfString("https://")
		{
			return url?.substringFromIndex(httpsRange.endIndex)
		}
		return url
	}
	
	public override init()
	{
		
	}
}