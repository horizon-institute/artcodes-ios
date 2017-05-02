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


private class MarkerDetectionRecord : Equatable
{
	static var instanceCount: Int = 0
	let instanceId: Int
	let code: String
	let marker: Marker
	var firstDetected: Date = Date(timeIntervalSince1970: 0)
	var lastDetected: Date = Date(timeIntervalSince1970: 0)
	var count: Int
	var markerImage: MarkerImage?
	
	static func newInstanceId() -> Int
	{
		let result: Int = instanceCount
		instanceCount+=1
		return result
	}
	
	required init(marker: Marker)
	{
		self.marker = marker
		self.code = marker.description
		self.count = 0
		self.instanceId = MarkerDetectionRecord.newInstanceId()
	}
	
	func clone(_ marker: Marker?) -> MarkerDetectionRecord
	{
		let clone: MarkerDetectionRecord = MarkerDetectionRecord(marker: marker ?? self.marker);
		clone.firstDetected = self.firstDetected;
		clone.lastDetected = self.lastDetected;
		clone.count = self.count;
		clone.markerImage = self.markerImage;
		return clone;
	}
	
	
	fileprivate var description: String { return "<#\(instanceId) \(code) x\(count)>" }
}

private func ==(lhs: MarkerDetectionRecord, rhs: MarkerDetectionRecord) -> Bool
{
	return lhs.instanceId == rhs.instanceId;
}

open class MultipleCodeActionDetectionHandler: MarkerDetectionHandler {
	
	weak var callback: ActionDetectionHandler?
	var experience: Experience
	var markerDrawer: MarkerDrawer?
	
	static let MULTIPLE: Int = 10
	static let REQUIRED: Int = 5
	static let MAX: Int = 20//REQUIRED*4
	var action: Action?
	var markerCounts: [String: Int] = [:]
	
	public init(callback: ActionDetectionHandler, experience: Experience, markerDrawer: MarkerDrawer?)
	{
		self.callback = callback
		self.experience = experience
		self.markerDrawer = markerDrawer
	}
	
	@objc open func onMarkersDetected(_ markers: [Marker], scene: SceneDetails)
	{
		self.addMarkers(markers, scene: scene)
		self.actOnMarkers()
	}
	
	
	var lastAddedToHistory: Date = Date(timeIntervalSince1970: 0)
	var shouldClearHistoryOnReset: Bool = true
	
	fileprivate var mDetectionHistory: [MarkerDetectionRecord] = []
	var mCodesDetected: [String] = []
	fileprivate var mActiveMarkerRecoreds: [String:MarkerDetectionRecord] = [:]
	
	@objc open func reset()
	{
		mActiveMarkerRecoreds.removeAll()
		mCodesDetected.removeAll()
		if (shouldClearHistoryOnReset)
		{
			mDetectionHistory.removeAll()
		}
		existingAction = nil
		existingThumbnails = nil
		existingFutureAction = nil
		self.callback?.onMarkerActionDetected(nil, possibleFutureAction: nil, imagesForFutureAction: [])
	}
	
	
	
	func addMarkers(_ markers: [Marker], scene: SceneDetails)
	{
		let time: Date = Date()
	
		// Process markers detected on this frame
		for marker: Marker in markers
		{
			let code: String = marker.description
	
			//increase occurrence if this marker is already in the list.
			var markerDetectionRecord: MarkerDetectionRecord? = mActiveMarkerRecoreds[code];
			if (markerDetectionRecord == nil)
			{
				// New marker: add it to data structure
				markerDetectionRecord = MarkerDetectionRecord(marker: marker)
				mActiveMarkerRecoreds[code] = markerDetectionRecord
			}
			let countIncrease = 1
			// add to history (if it has passed the required occurrences on this frame)
			if (markerDetectionRecord!.count < MultipleCodeActionDetectionHandler.REQUIRED && markerDetectionRecord!.count + countIncrease >= MultipleCodeActionDetectionHandler.REQUIRED)
			{
				if (self.mDetectionHistory.isEmpty || time.timeIntervalSinceDate(self.lastAddedToHistory) >= 1 || code != self.mDetectionHistory[self.mDetectionHistory.count - 1].code)
				{
					if (markerDetectionRecord!.markerImage != nil)
					{
						// if second time this marker is detected
						// create new entry and leave old one in history
						markerDetectionRecord!.markerImage!.newDetection = false;
						markerDetectionRecord!.markerImage!.detectionActive = false;
						markerDetectionRecord = markerDetectionRecord!.clone(marker);
						mActiveMarkerRecoreds[code] = markerDetectionRecord
					}
					markerDetectionRecord!.firstDetected = time
					mDetectionHistory.append(markerDetectionRecord!)
					self.lastAddedToHistory = time
					mCodesDetected.append(markerDetectionRecord!.code)
				}
				markerDetectionRecord!.markerImage = self.markerDrawer!.drawMarker(marker, scene: scene)
				markerDetectionRecord!.markerImage!.newDetection = true;
			}
			else if (markerDetectionRecord!.markerImage != nil)
			{
				markerDetectionRecord!.markerImage!.newDetection = false;
			}
	
			// Existing marker record: increase its count
			markerDetectionRecord!.count = min(markerDetectionRecord!.count + countIncrease, MultipleCodeActionDetectionHandler.MAX);
			markerDetectionRecord!.lastDetected = time;
		}
	
		// Workout which markers have timed out:
		var toRemove: [String] = []
		let markerCodes = markers.map({$0.description})
		for markerRecord: MarkerDetectionRecord in mActiveMarkerRecoreds.values
		{
			if(!markerCodes.contains(markerRecord.marker.description))
			{
				if (markerRecord.count == MultipleCodeActionDetectionHandler.REQUIRED)
				{
					mCodesDetected.removeObject(markerRecord.code)
					if (markerRecord.markerImage != nil)
					{
						markerRecord.markerImage!.detectionActive = false;
						markerRecord.markerImage!.newDetection = false;
					}
				}
				else if (markerRecord.count <= 1)
				{
					toRemove.append(markerRecord.code);
					continue;
				}
				markerRecord.count = markerRecord.count - 1;
			}
		}
		for markerToRemove: String in toRemove
		{
			mActiveMarkerRecoreds.removeValue(forKey: markerToRemove)
		}
		mCodesDetected.sort()
	}
	
	func actOnMarkers()
	{
		let standardCode: String? = self.getStandardCode()
		let action: Action? = self.getActionFor(standardCode)
	
		let sequentialAction: Action? = self.getActionFor(getSequentialCode())
		let futureSequentialAction: Action? = self.getPossibleFutureSequentialActionFor(sequentialAction == nil ? action : sequentialAction, foundUsing: standardCode)
		if (sequentialAction != nil)
		{
			self.sendIfResultChanged(sequentialAction, futureAction: futureSequentialAction, thumbnails: self.getImagesForAction(futureSequentialAction))
			return
		}
	
		let groupAction: Action? = self.getActionFor(self.getGroupCode())
		let futureGroupAction: Action? = self.getPossibleFutureGroupActionFor(groupAction == nil ? action : groupAction)
		if (groupAction != nil)
		{
			self.sendIfResultChanged(groupAction, futureAction: futureGroupAction, thumbnails: self.getImagesForAction(futureGroupAction))
			return
		}
	
		let futureAction: Action? = futureSequentialAction != action ? futureSequentialAction : futureGroupAction
		self.sendIfResultChanged(action, futureAction: futureAction, thumbnails: self.getImagesForAction(futureAction))
	}
	
	var existingAction: Action? = nil
	var existingFutureAction: Action? = nil
	var existingThumbnails: [MarkerImage?]? = nil
	func sendIfResultChanged(_ action: Action?, futureAction: Action?, thumbnails: [MarkerImage?]?)
	{
		let actionsAreDifferent: Bool = !(existingAction==nil && action==nil) && ((existingAction==nil || action==nil) || (existingAction! != action!))
		let futureActionsAreDifferent: Bool = !(existingFutureAction==nil && futureAction==nil) && ((existingFutureAction==nil || futureAction==nil) || (existingFutureAction! != futureAction!))
		let thumbnailsAreDifferent: Bool = !(existingThumbnails==nil && thumbnails==nil) && ((existingThumbnails==nil || thumbnails==nil) || (!thumbnailsAreEqual(existingThumbnails!, list2: thumbnails!)))
		
		if (actionsAreDifferent || futureActionsAreDifferent || thumbnailsAreDifferent)
		{
			self.existingAction = action;
			self.existingThumbnails = thumbnails;
			self.existingFutureAction = futureAction;
			self.callback?.onMarkerActionDetected(action, possibleFutureAction: futureAction, imagesForFutureAction: thumbnails)
		}
	}
	
	func thumbnailsAreEqual(_ list1: [MarkerImage?], list2: [MarkerImage?]) -> Bool
	{
		// the standard equals operator gives a compile error on lists that may contain nil :(
		if (list1.count == list2.count)
		{
			for i in 0..<list1.count
			{
				if (list1[i] != list2[i])
				{
					return false
				}
			}
		}
		return true
	}
	
	func getImagesForAction(_ action: Action?) -> [MarkerImage?]?
	{
		if (action != nil)
		{
			var result: [MarkerImage?] = []
			if (action?.match == Match.any)
			{
				for code: String in (action?.codes)!
				{
					let record: MarkerDetectionRecord? = mActiveMarkerRecoreds[code]
					if (record != nil && record!.markerImage != nil && record!.markerImage!.detectionActive)
					{
						result.append(record!.markerImage!)
						return result
					}
				}
			}
			else if (action?.match == Match.all)
			{
				for code: String in action!.codes
				{
					let record: MarkerDetectionRecord? = mActiveMarkerRecoreds[code]
					if (record != nil && record!.markerImage != nil && record!.markerImage!.detectionActive)
					{
						result.append(record!.markerImage!)
					}
					else
					{
						result.append(nil)
					}
				}
				return result
			}
			else if (action?.match == Match.sequence)
			{
				let historyAsStrings: [String] = mDetectionHistory.map({$0.code})
				
				for numberOfCodesInHistory in (1...min(action!.codes.count, historyAsStrings.count)).reverse()
				{
					if (action!.codes[0..<numberOfCodesInHistory] == historyAsStrings[historyAsStrings.count-numberOfCodesInHistory..<historyAsStrings.count])
					{
						let start = mDetectionHistory.count - numberOfCodesInHistory
						for record: MarkerDetectionRecord in mDetectionHistory[start..<mDetectionHistory.count]
						{
							result.append(record.markerImage)
						}
						for _ in numberOfCodesInHistory..<action!.codes.count
						{
							result.append(nil)
						}
						break
					}
				}
				return result
			}
			return result
		}
		return nil
	}
	
	/**
	* Search for group codes (or "pattern groups") in the detected codes. This will only return
	* group codes set in the experience.
	* @return
	*/
	func getGroupCode() -> String?
	{
		// Search for pattern groups
		// By getting every combination of the currently detected markers and checking if they exist in the experience (biggest groups first, groups must include at least 2 markers)
		if (mCodesDetected.count > 1) {
			let combinations: Array<Set<String>> = self.combinationsOfStrings(mCodesDetected, maxCombinationSize: mCodesDetected.count, seperator: "+")
			for i in (1..<combinations.count).reversed()
			{
				var mostRecentGroupStr: String? = nil
				var mostRecentGroupAsArray: [String] = []
				for code: String in combinations[i]
				{
					let codeAsArray: [String] = split(code,seperator: "+")
					if (isValidCode(code) && markerDetectionTimesOverlap(codeAsArray) && getMostRecentDetectionTime(codeAsArray, excluding: mostRecentGroupAsArray).timeIntervalSince1970>getMostRecentDetectionTime(mostRecentGroupAsArray, excluding: codeAsArray).timeIntervalSince1970) {
						mostRecentGroupStr = code
						mostRecentGroupAsArray = codeAsArray
					}
				}
				if (mostRecentGroupStr != nil)
				{
					return mostRecentGroupStr
				}
			}
		}
		return nil
	}
	
	fileprivate func split(_ string:String?, seperator:String) -> [String]
	{
		return string?.characters.split(separator: "+").map({String($0)}) ?? []
	}
	
	func getMostRecentDetectionTime(_ codes: [String]?, excluding: [String]?) -> Date
	{
		var mostRecentTime: Date = Date(timeIntervalSince1970: 0)
		if (codes != nil)
		{
			for codeStr in codes!
			{
				if (excluding == nil || !excluding!.contains(codeStr))
				{
					let code: MarkerDetectionRecord? = mActiveMarkerRecoreds[codeStr]
					if (code != nil && code!.lastDetected.timeIntervalSince1970 > mostRecentTime.timeIntervalSince1970)
					{
						mostRecentTime = code!.lastDetected
					}
				}
			}
		}
		return mostRecentTime
	}
	
	func markerDetectionTimesOverlap(_ codes: [String]) -> Bool
	{
		for i in 0..<codes.count-1
		{
			let code1: MarkerDetectionRecord = mActiveMarkerRecoreds[codes[i]]!
			var overlapFound = false
			for j in (i+1)..<codes.count
			{
				let code2: MarkerDetectionRecord = mActiveMarkerRecoreds[codes[j]]!
				overlapFound = doTimesOverlapForRecords(code1, record2: code2)
				if (overlapFound)
				{
					break;
				}
			}
			if (!overlapFound)
			{
				return false;
			}
		}
		return true;
	}
	
	fileprivate func doTimesOverlapForRecords(_ record1: MarkerDetectionRecord, record2: MarkerDetectionRecord) -> Bool
	{
		return (record1.firstDetected.timeIntervalSince1970 <= record2.lastDetected.timeIntervalSince1970) &&
			(record1.lastDetected.timeIntervalSince1970 >= record2.firstDetected.timeIntervalSince1970)
	}
	
	/**
	* Get all the combinations of objects up to a maximum size for the combination and add it to the result List.
	* E.g. combinationsOfStrings("132", 2, [], "x") changes the result array to [("1","2","3"),("1x2","1x3","2x3")] where () denotes a Set and [] denotes a List.
	*/
	func combinationsOfStrings(_ strings: [String], maxCombinationSize: Int, seperator: String) -> Array<Set<String>>
	{
		var result: Array<Set<String>> = []
		let strings = strings.sorted()
		var resultForN_1: Set<String>? = nil
		for i in 1...maxCombinationSize
		{
			resultForN_1 = combinationsOfStrings(strings, atCombinationSize: i, resultForN_1: resultForN_1, seperator: seperator)
			result.append(resultForN_1!)
		}
		return result
	}
	func combinationsOfStrings(_ strings: [String], atCombinationSize: Int, resultForN_1: Set<String>?, seperator: String) -> Set<String>
	{
		if (atCombinationSize == 1)
		{
			var resultForN: Set<String> = Set<String>()
			for code in strings
			{
				resultForN.insert(code)
			}
			return resultForN
		}
		else if (atCombinationSize == strings.count)
		{
			var resultForN: Set<String> = Set<String>()
			resultForN.insert(strings.joined(separator: seperator))
			return resultForN
		}
		else
		{
			var resultForN: Set<String> = Set<String>()
			for code: String in strings
			{
				for setMinus1s: String in resultForN_1!
				{
					let setMinus1: [String] = setMinus1s.characters.split(separator: seperator.characters.first!).map(String.init)
					if (!setMinus1.contains(code))
					{
						var aResult = [String](setMinus1);
						aResult.append(code);
						aResult.sort()
						resultForN.insert(aResult.joined(separator: seperator));
					}
				}
			}
	
			return resultForN
		}
	}
	
	/**
	* Search for sequential codes (or "pattern paths") in detection history. This method may
	* remove items from history that do not match the beginning of any sequential code in the
	* experience and will only return a code from the experience.
	* @return
	*/
	func getSequentialCode() -> String?
	{
			// Search for sequential actions in history
			// by creating history sub-lists and checking if any codes in the experience match.
			// e.g. if history=[A,B,C,D] check sub-lists [A,B,C,D], [B,C,D], [C,D].
			if (!mDetectionHistory.isEmpty)
			{
				var foundPrefix = false
				var start = 0
				
				var detectionHistoryAsStrings: [String] = mDetectionHistory.map({$0.code})
				while (start < mDetectionHistory.count)
				{
					let subList: [String] = Array(detectionHistoryAsStrings[start..<detectionHistoryAsStrings.count])
					let joinedString: String = subList.joined(separator: ">")
					if (subList.count != 1 && self.isValidCode(joinedString))
					{
						// Case 1: The history sublist is a sequential code in the experience.
						return joinedString
					}
					else if (!foundPrefix && !self.hasSequentialPrefix(joinedString))
					{
						// Case 2: No sequential codes in the experience start with the history sublist (as well as previous history sublists).
						// So remove the first part of it from history
						// This ensures that history never grows longer than the longest code
						detectionHistoryAsStrings.remove(at: 0)
						mDetectionHistory.remove(at: 0)
						start = 0
					}
					else
					{
						// Case 3: Sequential codes in the experience start with the history sublist (or a previous history sublist).
						foundPrefix = true
						start+=1
					}
				}
			}
		return nil
	}
	
	/**
	* Search for the single marker with the most occurrences that is in the experience, or just the highest occurrences if none are in the experience.
	* @return
	*/
	func getStandardCode() -> String?
	{
		var result: MarkerDetectionRecord? = nil
		var resultIsInExperience = false
		for code: String in mCodesDetected
		{
			let marker: MarkerDetectionRecord = mActiveMarkerRecoreds[code]!
			let markerIsInExperience: Bool = self.isValidCode(code)
			if (result==nil || (!resultIsInExperience && markerIsInExperience) || (resultIsInExperience==markerIsInExperience && ((marker.lastDetected.timeIntervalSince1970>result!.lastDetected.timeIntervalSince1970)||(marker.lastDetected.timeIntervalSince1970==result!.lastDetected.timeIntervalSince1970 && marker.firstDetected.timeIntervalSince1970>result!.firstDetected.timeIntervalSince1970)||(marker.lastDetected==result!.lastDetected && marker.firstDetected==result!.firstDetected && marker.count>result!.count))))
			{
				result = marker
				resultIsInExperience = markerIsInExperience
			}
		}
		
		return result?.code
	}
	
	fileprivate var validCodes: [String:Action]? = nil
	fileprivate var subGroupCodes: [String:Set<Action>]? = nil
	fileprivate var subSequenceCodes: [String:Set<Action>]? = nil
	
	func isValidCode(_ code: String) -> Bool
	{
		if (validCodes==nil)
		{
			self.createDataCache();
		}
		return validCodes![code] != nil
	}
	
	func hasSequentialPrefix(_ prefix: String) -> Bool
	{
		if (subSequenceCodes==nil)
		{
			self.createDataCache();
		}
		return subSequenceCodes![prefix] != nil
	}
	
	func getActionFor(_ code: String?) -> Action?
	{
		if (code == nil)
		{
			return nil
		}
		
		if (validCodes==nil)
		{
			self.createDataCache()
		}
		return validCodes![code!]
	}
	
	func getPossibleFutureSequentialActionFor(_ found: Action?, foundUsing: String?) -> Action?
	{
		if (subSequenceCodes == nil)
		{
			createDataCache()
		}
		
		var minimumSize: Int = 1
		if (found != nil && found!.match != Match.any)
		{
			minimumSize = found!.codes.count + 1
		}
		
		if (mDetectionHistory.isEmpty)
		{
			return found
		}
		
		// if a single marker triggered found Action and it's not the last one in history then do not provide a possible future sequential action.
		if (found != nil && found?.match==Match.any && foundUsing != nil && mDetectionHistory.last != nil)
		{
			if (foundUsing != mDetectionHistory.last!.code)
			{
				return found;
			}
		}
		
		// seq
		if (found == nil || found?.match != Match.all)
		{
			let detectionHistoryAsStrings: [String] = mDetectionHistory.map({$0.code})
			for i in 0..<detectionHistoryAsStrings.count
			{
				let subHistory: [String] = Array(detectionHistoryAsStrings[i..<detectionHistoryAsStrings.count])
				let actions: Set<Action>? = subSequenceCodes![subHistory.joinWithSeparator(">")]
				if (actions != nil && !actions!.isEmpty)
				{
					var longestSequentialAction: Action? = nil
					for action: Action in actions!
					{
						if (action.codes.count >= minimumSize && (longestSequentialAction == nil || longestSequentialAction!.codes.count < action.codes.count))
						{
							longestSequentialAction = action
						}
					}
					if (longestSequentialAction != nil)
					{
						return longestSequentialAction
					}
				}
			}
		}
		
		return found
	}
	
	func getPossibleFutureGroupActionFor(_ found: Action?) -> Action?
	{
		if (subGroupCodes == nil)
		{
			createDataCache()
		}
		
		// group
		
		if (found == nil || found!.match != Match.sequence)
		{
			
			var detectedInFound: Set<String> = Set<String>()
			if (found != nil)
			{
				detectedInFound = Set<String>(found!.codes).intersect(mCodesDetected)
			}
			
			let groupFutureActions: Set<Action>? = subGroupCodes![mCodesDetected.joinWithSeparator("+")]
			if (groupFutureActions != nil && !groupFutureActions!.isEmpty)
			{
				var largestGroupAction: Action? = nil
				for action: Action in groupFutureActions!
				{
					if ((found==nil || detectedInFound.isSubsetOf(action.codes)) && (largestGroupAction == nil || largestGroupAction!.codes.count < action.codes.count))
					{
						largestGroupAction = action
					}
				}
				if (largestGroupAction != nil)
				{
					return largestGroupAction
				}
			}
		}
		
		// normal
		
		return found
	}
	
	fileprivate static func intersection(_ list1: [String], list2: [String]) -> [String]
	{
		let set1: Set<String> = Set<String>(list1)
		return Array(set1.intersection(list2))
	}
	
	fileprivate func createDataCache()
	{
		if (validCodes==nil)
		{
			validCodes = [:]
			subGroupCodes = [:]
			subSequenceCodes = [:]
			for action: Action in experience.actions
			{
				if (action.match == Match.any) // single
				{
					for code in action.codes
					{
						validCodes![code] = action
					}
				}
				else if (action.match == Match.all) // group
				{
					let code: String = action.codes.joinWithSeparator("+")
					validCodes![code] = action
					
					let subGroupsByLenght: Array<Set<String>> = combinationsOfStrings(action.codes, maxCombinationSize: action.codes.count, seperator: "+")
					for setOfGroups: Set<String> in subGroupsByLenght
					{
						for code: String in setOfGroups
						{
							var actions: Set<Action>? = subGroupCodes![code]
							if (actions != nil)
							{
								actions!.insert(action)
							}
							else
							{
								var actionsForSubGroup: Set<Action> = Set<Action>()
								actionsForSubGroup.insert(action);
								subGroupCodes![code] = actionsForSubGroup
							}
						}
					}
				}
				else if (action.match == Match.sequence)
				{
					let code: String = action.codes.joinWithSeparator(">")
					validCodes![code] = action
					for subCodeSize in 1..<action.codes.count
					{
						let code = Array(action.codes[0..<subCodeSize]).joinWithSeparator(">")
						var actions: Set<Action>? = subSequenceCodes![code]
						if (actions != nil)
						{
							actions?.insert(action)
						}
						else
						{
							var actionsForSubSequence: Set<Action> = Set<Action>()
							actionsForSubSequence.insert(action)
							subSequenceCodes![code] = actionsForSubSequence
						}
					}
				}
			}
		}
	}
}
