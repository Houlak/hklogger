import Foundation
import Network

struct LogData: Decodable {
    let path: String
    let fileName: String
    let message: String
    let deviceInfo: String?
    let createNewFile: Bool
}

/// Connects this with a specific server, in order to receive its messages
class Connection {

    var connection: NWConnection?
    let endpoint: NWEndpoint?

    init(endpoint: NWEndpoint) {
        self.endpoint = endpoint
        
        connection = NWConnection(to: endpoint, using: getParameters())
        start()
    }
    
    func getParameters() -> NWParameters {
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 2

        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        parameters.includePeerToPeer = true
        
        return parameters
    }

    func start() {
        guard let connection = connection else {
            return
        }
        
        connection.stateUpdateHandler = { newState in
            print("Connection state update: \(newState)")
            switch newState {
            case .ready:
                self.receiveMessage()
            case .failed(let error):
                print("\(connection) failed with \(error)")

                /// Cancel the connection upon a failure.
                connection.cancel()
                
                if self.endpoint != nil && error == NWError.posix(.ECONNABORTED) {
                    /// Reconnect if the user suspends the app on the nearby device.
                    let newConnection = NWConnection(to: (self.endpoint)!, using: self.getParameters())
                    self.connection = newConnection
                    self.start()
                }
            case .cancelled:
                self.connection = nil
            default:
                break
            }
        }
        connection.start(queue: .main)
    }

    func receiveMessage() {
        guard let connection = connection else {
            return
        }
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 100000) { data, context, isComplete, _ in
            if let data = data,
               let decodedData = try? JSONDecoder().decode(LogData.self, from: data) {
                let message = decodedData.message
                print("Connection received message: \(message)")
                
                self.processData(for: decodedData)
            }
            self.receiveMessage()
        }
    }
    
    func processData(for data: LogData) {
        guard let pathURL = URL(string: data.path) else { return }
        
        do {
            let lastIndex = findLastFileIndex(for: pathURL, fileName: data.fileName)
            let currentPath = "\(pathURL.path)_\(data.createNewFile ? lastIndex + 1 : lastIndex).log"
            
            if FileManager.default.fileExists(atPath: currentPath) {
                
                guard let url = URL(string: currentPath) else { return }
                let fh = try FileHandle(forWritingTo: url)
                fh.seekToEndOfFile()
                try fh.write(contentsOf: Data(data.message.utf8))
                fh.closeFile()
                
            } else {
                let logfilePath = "\(data.path)_1.log"
                
                var message = data.message
                if let deviceInfo = data.deviceInfo {
                    message.insert(contentsOf: deviceInfo, at: message.startIndex)
                }
                
                try message.write(toFile: logfilePath, atomically: true, encoding: .utf8)
            }
        } catch {
            print("Error saving the log file: \(error)")
        }
    }
    
    func findLastFileIndex(for path: URL, fileName: String) -> Int {
        var lastIndex = 1
        let fm = FileManager.default
        let directoryPath = path.deletingLastPathComponent().path
        var isDir: ObjCBool = true
        
        if fm.fileExists(atPath: directoryPath, isDirectory: &isDir) {
            let files = try! fm.contentsOfDirectory(atPath: directoryPath)
            
            for name in files {
                if name.hasPrefix("\(fileName)_"),
                   let stringIndex = name.split(separator: "_").last?.prefix(while: { $0.isNumber }),
                   let index = Int(stringIndex),
                   index > lastIndex {
                    lastIndex = index
                }
            }
        }
        
        return lastIndex
    }

}

/// Discover server for the type specified
class Browser {

    let browser: NWBrowser

    init() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        browser = NWBrowser(for: .bonjour(type: "_hklogger._tcp", domain: nil), using: parameters)
    }

    func start(handler: @escaping (NWBrowser.Result) -> Void) {
        browser.stateUpdateHandler = { newState in
            print("Browser state update: \(newState)")
            
            switch newState {
            case .failed(let error):
                print("Browser failed with \(error), restarting...")
                self.browser.cancel()
                self.start(handler: handler)
            default:
                break
            }
        }
        browser.browseResultsChangedHandler = { results, changes in
            for result in results {
                if case NWEndpoint.service = result.endpoint {
                    handler(result)
                }
            }
        }
        browser.start(queue: .main)
    }
}

/// Client class to initialize the browser and keep the connection with the server
class Client {

    let browser = Browser()

    var connection: Connection?

    func start() {
        browser.start { [weak self] result in
            print("Client handler result: \(result)")
            self?.connection = Connection(endpoint: result.endpoint)
        }
    }

}

let client = Client()
client.start()

RunLoop.current.run()
