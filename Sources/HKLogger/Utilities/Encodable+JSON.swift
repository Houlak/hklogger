//
//  Encodable+JSON.swift
//
//
//  Created by Alejandra on 4/4/23.
//

import Foundation

extension Encodable {
    var asJSONDictionary: [String: String]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        var json: [String: String]?
        do {
            json = try JSONSerialization.jsonObject(
                with: data,
                options: [.fragmentsAllowed]
            ) as? [String: String]
        } catch {
            print("AS DICTIONARY ERROR: \(String(describing: error))")
        }
        return json
    }
    
    var asJSON: String {
        let jsonEncoder = JSONEncoder()
        
        jsonEncoder.outputFormatting = [.withoutEscapingSlashes, .prettyPrinted]
        guard let encodedData = try? jsonEncoder.encode(self)
        else {
            return ""
        }
        
        let jsonString = String(data: encodedData,
                                encoding: .utf8)
        
        return jsonString ?? ""
    }
}
