//
//  JSONCodingKeys.swift
//
//
//  Created by Alejandra on 19/4/23.
//

import Foundation

struct JSONCodingKeys: CodingKey {
    var stringValue: String

    init(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?

    init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}
