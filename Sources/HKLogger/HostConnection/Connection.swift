//
//  File.swift
//  
//
//  Created by Martín Lago on 25/4/23.
//

import Foundation
import Network

class Connection {

    var connection: NWConnection?

    init(connection: NWConnection) {
        self.connection = connection
        start()
    }

    func start() {
        guard let connection = connection else {
            return
        }
        
        connection.stateUpdateHandler = { newState in
            print("Connection state update: \(newState)")
            switch newState {
            case .failed:
                connection.cancel()
                self.connection = nil
                NotificationCenter.default.post(name: .connectionCancelled, object: nil)
            default:
                break
            }
        }
        connection.start(queue: .main)
    }

    func send(_ data: LogData) {
        guard let connection = connection else {
            return
        }
        
        guard let encodedData = try? JSONEncoder().encode(data) else { return }
        
        connection.send(
            content: encodedData,
            contentContext: .defaultMessage,
            isComplete: true,
            completion: .contentProcessed({ message in
                print("Send message completion: \(String(describing: message))")
            })
        )
    }
    
}
