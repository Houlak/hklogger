//
//  KeyedEncodingContainerProtocol+Utils.swift
//
//
//  Created by Alejandra on 19/4/23.
//

import Foundation

extension KeyedEncodingContainerProtocol where Key == JSONCodingKeys {
    mutating func encode(_ value: [String: Any]) throws {
        try value.forEach({ (key, value) in
            let key = JSONCodingKeys(stringValue: key)
            switch value {
            case let value as Bool:
                try encode(value, forKey: key)
            case let value as Int:
                try encode(value, forKey: key)
            case let value as String:
                try encode(value, forKey: key)
            case let value as Double:
                try encode(value, forKey: key)
            case let value as CGFloat:
                try encode(value, forKey: key)
            case let value as [String: Any]:
                try encode(value, forKey: key)
            case let value as [Any]:
                try encode(value, forKey: key)
            case Optional<Any>.none:
                try encodeNil(forKey: key)
            default:
                throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath + [key], debugDescription: "Invalid JSON value"))
            }
        })
    }
}

extension KeyedEncodingContainerProtocol {
    mutating func encode(_ value: [String: Any]?, forKey key: Key) throws {
        guard let value = value
        else {
            throw EncodingError.invalidValue(value as Any, EncodingError.Context(codingPath: codingPath + [key], debugDescription: "Invalid JSON value"))
        }
        
        var container = self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        try container.encode(value)
    }
    
    mutating func encode(_ value: [Any]?, forKey key: Key) throws {
        guard let value = value
        else {
            throw EncodingError.invalidValue(value as Any, EncodingError.Context(codingPath: codingPath + [key], debugDescription: "Invalid JSON value"))
        }
        
        var container = self.nestedUnkeyedContainer(forKey: key)
        try container.encode(value)
    }
}
