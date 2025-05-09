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

public struct Experience: Codable
{
    public var id: String
    public var name: String?
    public var icon: String?
    public var image: String?
    public var description: String?
    public var author: String?
    public var originalID: String?
    
    public var actions: [Action] = []
    public var availabilities: [Availability] = []
    public var pipeline: [String] = []
    public var callback: (() -> Void)?
    
    public var requestedAutoFocusMode: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case icon
        case image
        case description
        case author
        case originalID
        case actions
        case availabilities
        case pipeline
    }    
    
    public init() {
        self.id = ""
    }
    
    public init(id: String)
    {
        self.id = id
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.icon = try container.decodeIfPresent(String.self, forKey: .icon)
        self.image = try container.decodeIfPresent(String.self, forKey: .image)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.author = try container.decodeIfPresent(String.self, forKey: .author)
        self.originalID = try container.decodeIfPresent(String.self, forKey: .originalID)
        self.actions = try container.decodeIfPresent([Action].self, forKey: .actions) ?? []
        self.availabilities = try container.decodeIfPresent([Availability].self, forKey: .availabilities) ?? []
        self.pipeline = try container.decodeIfPresent([String].self, forKey: .pipeline) ?? []
    }
    
    public func actionForCode(code: String) -> Action?
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
