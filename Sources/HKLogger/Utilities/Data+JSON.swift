//
//  Data+JSON.swift
//  
//
//  Created by Alejandra on 19/4/23.
//

import Foundation

extension Data {
    var toJSONValue: JSONValue? {
        return try? JSONDecoder().decode(JSONValue.self, from: self)
    }
}
