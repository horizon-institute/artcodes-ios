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
import Alamofire
import SwiftyJSON

class AppEngineAccount: Account
{
    var email: String
    var token: String
    var name: String
    {
        return email
    }
    
    var id: String
    {
        return "google:\(email)"
    }
    
    init(email: String, token: String)
    {
        self.email = email
        self.token = token
    }
    
    func loadLibrary(closure: ([String]) -> Void)
    {
        let headers = [
            "Authorization": "Bearer \(token)"
        ]
        
        // TODO
        Alamofire.request(.GET, "https://aestheticodes.appspot.com/experiences", headers: headers).response { (request, response, data, error) -> Void in
            if let jsonData = data
            {
                let result = JSON(data: jsonData).arrayValue.map { $0.string!}
                closure(result)
            }
        }
    }
}