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
import ArtcodesScanner
import CoreLocation

protocol ArtcodeServer
{
    var root: String { get }
    
    var accounts: [String:Account] { get }
    var starred: [String] { get set }
    var recent: [String] { get set }

    func url(for: String?) -> URL?
    func loadRecommended(near: CLLocationCoordinate2D?, closure: @escaping ([String: [String]]) -> Void)
    func loadExperience(uri: String, closure: @escaping (Result<Experience, Error>) -> Void)
    func accountFor(experience: Experience) -> Account
    func logInteraction(experience: Experience)
    func search(searchString: String, closure: @escaping ([String]) -> Void)
    func addAccount(name: String, email: String, token: String) -> Account
}
