//
//  HKLoggerNetworking.swift
//
//
//  Created by Alejandra on 3/4/23.
//

import Foundation

struct HKLoggerNetworking: Codable {
    let method: String
    let path: String
    let request: NetworkingRequest
    let response: NetworkingResponse
    
    struct NetworkingRequest: Codable {
        let headers: [String: String]?
        let body: JSONValue?
    }
    
    struct NetworkingResponse: Codable {
        let statusCode: Int
        let headers: [String: String]?
        let body: JSONValue?
    }
}

enum JSONValue: Codable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case dictionary([String: JSONValue])
    case array([JSONValue])
    case null
    
    init(from decoder: Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(String.self) {
            self = .string(value)
        } else if let value = try? decoder.singleValueContainer().decode(Double.self) {
            self = .number(value)
        } else if let value = try? decoder.singleValueContainer().decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? decoder.singleValueContainer().decode([String: JSONValue].self) {
            self = .dictionary(value)
        } else if let value = try? decoder.singleValueContainer().decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .null
        }
    }
    
    public func encode(to encoder: Encoder) throws {
      if let map = self.toAny() as? [String: Any] {
        var container = encoder.container(keyedBy: JSONCodingKeys.self)
        try encodeValue(fromObjectContainer: &container, map: map)
      } else if let arr = self.toAny() as? [Any] {
          var container = encoder.unkeyedContainer()
          try encodeValue(fromArrayContainer: &container, arr: arr)
      } else {
        var container = encoder.singleValueContainer()

        if let value = self.toAny() as? String {
          try container.encode(value)
        } else if let value = self.toAny() as? Int {
          try container.encode(value)
        } else if let value = self.toAny() as? Double {
          try container.encode(value)
        } else if let value = self.toAny() as? Bool {
          try container.encode(value)
        } else {
          try container.encodeNil()
        }
      }
    }
    
    func encodeValue(fromArrayContainer container: inout UnkeyedEncodingContainer, arr: [Any]) throws {
      for value in arr {
        if let value = value as? String {
          try container.encode(value)
        } else if let value = value as? Int {
          try container.encode(value)
        } else if let value = value as? Double {
          try container.encode(value)
        } else if let value = value as? Bool {
          try container.encode(value)
        } else if let value = value as? [String: Any] {
          var keyedContainer = container.nestedContainer(keyedBy: JSONCodingKeys.self)
          try encodeValue(fromObjectContainer: &keyedContainer, map: value)
        } else if let value = value as? [Any] {
          var unkeyedContainer = container.nestedUnkeyedContainer()
          try encodeValue(fromArrayContainer: &unkeyedContainer, arr: value)
        } else {
          try container.encodeNil()
        }
      }
    }
    
    func encodeValue(fromObjectContainer container: inout KeyedEncodingContainer<JSONCodingKeys>, map: [String:Any]) throws {
      for k in map.keys {
        let value = map[k]
        let encodingKey = JSONCodingKeys(stringValue: k)

        if let value = value as? String {
          try container.encode(value, forKey: encodingKey)
        } else if let value = value as? Int {
          try container.encode(value, forKey: encodingKey)
        } else if let value = value as? Double {
          try container.encode(value, forKey: encodingKey)
        } else if let value = value as? Bool {
          try container.encode(value, forKey: encodingKey)
        } else if let value = value as? [String: Any] {
          var keyedContainer = container.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: encodingKey)
          try encodeValue(fromObjectContainer: &keyedContainer, map: value)
        } else if let value = value as? [Any] {
          var unkeyedContainer = container.nestedUnkeyedContainer(forKey: encodingKey)
          try encodeValue(fromArrayContainer: &unkeyedContainer, arr: value)
        } else {
          try container.encodeNil(forKey: encodingKey)
        }
      }
    }
}

extension JSONValue {
    
    func toAny() -> Any {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            return value
        case .bool(let value):
            return value
        case .null:
            return NSNull()
        case .array(let values):
            return values.map { $0.toAny() }
        case .dictionary(let values):
            return values.mapValues { $0.toAny() }
        }
    }
    
}
 
