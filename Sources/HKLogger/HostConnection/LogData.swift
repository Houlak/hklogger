//
//  File.swift
//  
//
//  Created by Martín Lago on 25/4/23.
//

import Foundation

struct LogData: Encodable {
    let path: String
    let fileName: String
    let message: String
    var deviceInfo: String? = nil
    var createNewFile: Bool = false
}
