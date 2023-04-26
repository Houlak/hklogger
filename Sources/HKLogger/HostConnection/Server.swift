//
//  File.swift
//  
//
//  Created by Martín Lago on 25/4/23.
//

import Foundation
import Network

class Server {

    var listener: NWListener?

    var connection: Connection?

    init() throws {
        configureListener()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cancelConnection),
            name: .connectionCancelled,
            object: nil
        )
    }
    
    func configureListener() {
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 2

        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        parameters.includePeerToPeer = true
        
        do {
            listener = try NWListener(using: parameters)
        } catch {
            print("Error creating listener: \(error)")
        }
        
        listener?.service = NWListener.Service(name: "server", type: "_hklogger._tcp")
    }

    func start() {
        guard let listener = listener else {
            return
        }
        
        listener.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                print("Listener ready: \(newState)")
            case .failed(let error):
                print("Listener failed with: \(error)")
                listener.cancel()
                self.listener = nil
                self.connection = nil
                self.configureListener()
                self.start()
            default:
                break
            }
        }
        listener.newConnectionHandler = { [weak self] newConnection in
            guard let self = self,
                  self.connection == nil
            else {
                newConnection.cancel()
                return
            }
            
            print("Listener -  New connection: \(newConnection)")
            let connection = Connection(connection: newConnection)
            self.connection = connection
        }
        listener.start(queue: .main)
    }
    
    @objc func cancelConnection() {
        connection = nil
    }

    func send(_ data: LogData) {
        guard let connection = connection else { return }
        connection.send(data)
    }
    
}
