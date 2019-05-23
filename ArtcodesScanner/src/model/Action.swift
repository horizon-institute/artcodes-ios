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
public enum ChecksumOption: Int
{
	case optional
	case required
	case excluded
}

@objc
open class Action: NSObject
{
	@objc open var name: String?
	@objc open var url: String?
	@objc open var codes = [String]()
	@objc open var match = Match.any
	open var checksumOption: ChecksumOption?
	@objc open var actionDescription: String?
	@objc open var image: String?
	@objc open var owner: String?
	@objc open var showDetail = false
	
	open var framesRequired: Int?
	open var framesAwarded: Int?
	open var minimumSize: Double?
	
	@objc open func nsMinimumSize() -> NSNumber
	{
		if let nonNilValue = self.minimumSize
		{
			return NSNumber(value: nonNilValue)
		}
		else
		{
			return 0
		}
	}
	
	@objc open func getChecksumOption() -> ChecksumOption
	{
		if let checksumOption = self.checksumOption
		{
			return checksumOption
		}
		else
		{
			return ChecksumOption.optional
		}
	}
	
	@objc open var displayURL: String?
	{
		if let httpRange = url?.range(of: "http://")
		{
			return url?.substring(from: httpRange.upperBound)
		}
		else if  let httpsRange = url?.range(of: "https://")
		{
			return url?.substring(from: httpsRange.upperBound)
		}
		return url
	}
	
	public override init()
	{
		
	}
}
