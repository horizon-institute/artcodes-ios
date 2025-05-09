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
import ArtcodesScanner

extension Experience
{
    var json: String?
    {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try! encoder.encode(self)
        return String(data: data, encoding: .utf8)
    }
    
    var jsonData: Data?
    {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        return try! encoder.encode(self)
    }
    
    func clone() -> Experience {
        let data = try! JSONEncoder().encode(self)
        return try! JSONDecoder().decode(Experience.self, from: data)
    }
    
    static func parse(_ data: Data) throws -> Experience? 
    {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom() {decoder in
            do {
                let date = try Date(from: decoder)
                return date
            } catch {
                let string = try decoder.singleValueContainer().decode(String.self)
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                if let date = formatter.date(from: string) {
                    return date
                }
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: string) {
                    return date
                }
                
                if let date = ISO8601DateFormatter().date(from: string) {
                    return date
                }
                return Date()
            }
        }
        return try decoder.decode(Experience.self, from: data)
    }
}
