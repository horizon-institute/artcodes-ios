//
//  ImageProcessorRegistry.swift
//  Artcodes
//
//  Created by Kevin Glover on 19/09/2024.
//  Copyright © 2024 Horizon DER Institute. All rights reserved.
//

import Foundation

class ImageProcessorRegistry {
    @MainActor static let sharedInstance = ImageProcessorRegistry()
    private var factoryRegistry: [String: ImageProcessorFactory] = [:]
    
    private init() {
        registerFactory(IntensityFilterFactory())
        registerFactory(InvertFilterFactory())
        //registerFactory(WhiteBalanceFilterFactory())
        //registerFactory(HlsEditFilterFactory())
        
        registerFactory(RedRgbFilterFactory())
        registerFactory(GreenRgbFilterFactory())
        registerFactory(BlueRgbFilterFactory())
        
        registerFactory(CyanCmykFilterFactory())
        registerFactory(MagentaCmykFilterFactory())
        registerFactory(YellowCmykFilterFactory())
        registerFactory(BlackCmykFilterFactory())
        
        registerFactory(TileThresholdFactory())
        registerFactory(OtsuThresholdFactory())
        
        registerFactory(MarkerDetectorFactory())
        //registerFactory(MarkerEmbeddedChecksumDetectorFactory())
        //registerFactory(MarkerAreaOrderDetectorFactory())
        //registerFactory(MarkerEmbeddedChecksumAreaOrderDetectorFactory())
        
        // registerFactory(DebugMarkerDetectorFactory())
    }
    
    func registerFactory(_ factory: ImageProcessorFactory) {
        factoryRegistry[factory.name] = factory
    }
    
    func getProcessor(for string: String, with settings: DetectionSettings) -> ImageProcessor? {
        let processorDetails = ImageProcessorRegistry.parsePipelineString(string)
        let processorName = processorDetails["name"] as? String ?? string
        
        if let factory = factoryRegistry[processorName] {
            return factory.create(with: settings)
        }
        print("Missing image processor factory: '\(processorName)'")
        
        return nil
    }
    
    static func parsePipelineString(_ string: String) -> [String: Any] {
        // Implementation of parsing logic goes here
        return [:]
    }
    
    func parsePipelineString(_ pipelineString: String) -> [String: Any] {
        let regexString = "([^\\(\\)]+)(?:\\(([^\\(\\)]*)\\))?"
        let options: NSRegularExpression.Options = .caseInsensitive
        
        do {
            let regex = try NSRegularExpression(pattern: regexString, options: options)
            let match = regex.firstMatch(in: pipelineString, options: [], range: NSRange(location: 0, length: pipelineString.utf16.count))
            
            if let match = match {
                let pipelineItemName = (pipelineString as NSString).substring(with: match.range(at: 1))
                let pipelineArgsRange = match.range(at: 2)
                var pipelineArgsString = ""
                
                if pipelineArgsRange.length > 0 {
                    pipelineArgsString = (pipelineString as NSString).substring(with: pipelineArgsRange)
                }
                
                return ["name": pipelineItemName, "args": parseDictionary(from: pipelineArgsString)]
            }
        } catch {
            print(error.localizedDescription)
        }
        
        return ["name": "", "args": [:]]
    }
    
    func parseDictionary(from string: String?) -> [String: String] {
        var dictionary = [String: String]()
        
        guard let string = string else {
            return dictionary
        }
        
        let trimmedString = string.trimmingCharacters(in: .whitespaces)
        let argStrings = trimmedString.components(separatedBy: ",")
        
        for argStr in argStrings {
            let argArray = argStr.components(separatedBy: "=")
            if argArray.count == 1 {
                dictionary[argStr] = argStr
            } else if argArray.count >= 2 {
                let key = argArray[0].trimmingCharacters(in: .whitespaces)
                let value = argArray[1].trimmingCharacters(in: .whitespaces)
                dictionary[key] = value
            }
        }
        
        return dictionary
    }
}
