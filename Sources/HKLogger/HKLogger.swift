import Foundation
#if canImport(UIKit)
import UIKit
#endif

/**
 HKLogger
 */
public final class HKLogger {
    
    public static let shared = HKLogger()
    
    // MARK: - Public Properties
    
    /// Indicates if the logs need to be stored on file
    public var saveLogsToFile = false
    /// Logs directory
    public var logsDirectoryName: URL? {
        didSet {
            guard let directory = logsDirectoryName else { return }
            logsPath = directory.appendingPathComponent(fileName)
        }
    }
    /// Indicates if the logs need to be stored in the host file system
    public var saveLogsToHost = false {
        didSet {
            #if !targetEnvironment(simulator)
                saveLogsInHostFromDevice = saveLogsToHost && environment == .debug
            #endif
        }
    }
    /// Development logs directory
    public var hostLogsDirectory: URL?
    /// Current environment
    public var environment: HKLoggerEnv = .debug
    /// Indicates if the metadata should be included in the printing messages
    public var includeMetadataOnConsole = false
    /// Indicates if the metadata should be included in the file's messages
    public var includeMetadataOnFile = false
    
    // MARK: - Private properties
    internal var logDeviceInfo = true
    internal var includeTimestamp = true
    internal let endingCharacter = "^^^"
    private var timestamp: String {
        return includeTimestamp
            ? "\(Date.now.stringyyyyMMddTHHmmss) - "
            : ""
    }
    internal var fileName: String {
        let targetName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") ?? "Logs"
        if let config = Bundle.main.object(forInfoDictionaryKey: "Config") {
            return "\(targetName)_\(config)"
        }
        return "\(targetName)"
    }
    
    internal var logsPath: URL?
    
    internal var hostLogsDirectoryName: URL? {
        guard
            let hostLogsDirectory = hostLogsDirectory
        else { return nil }
        return hostLogsDirectory.appendingPathComponent(fileName)
    }
    
    /// Save logs to host on a physical device
    internal let hostServer = try? Server()
    internal var saveLogsInHostFromDevice = false
    
    // MARK: - Initialization
    
    private init() {
        #if !targetEnvironment(simulator)
            hostServer?.start()
        #endif
    }
    
    /// Print the log message in console and/or add it to the logs file
    ///
    /// - Parameters:
    ///     - message: The message to be logged
    ///     - severity: The severity of the message (debug, info, warning, or error)
    ///     - fileName: The file where the log is generated
    ///     - funcionName: The function where the log is generated
    ///     - lineNumber: The line number where the log is generated
    public func log(
        message: String,
        severity: HKLoggerSeverityLevel,
        type: HKLoggerType = .default,
        fileName: StaticString = #file,
        functionName: StaticString = #function,
        lineNumber: Int = #line
    ) {
        printMessageIfNeeded(message, severity, type, fileName, functionName, lineNumber)
        do {
            try saveLogsToFileIfNeeded(message, severity, type, fileName, functionName, lineNumber)
        } catch let error as HKLoggerError {
            printMessageIfNeeded(error.debugMessage, .error, .default, fileName, functionName, lineNumber)
        } catch {
            printMessageIfNeeded(error.localizedDescription, .error, .default, fileName, functionName, lineNumber)
        }
    }
    
    /// Start monitoring network requests and responses
    public func startLoggingFromNetwork() -> URLSession? {
        if URLProtocol.registerClass(HKLoggerUrlProtocol.self) {
            let configuration = URLSessionConfiguration.default
            configuration.protocolClasses = [HKLoggerUrlProtocol.self]
            let session = URLSession(
            return configuration
        }
        
        return nil
    }
    
}

// MARK: - Life Cycle Config

public extension HKLogger {
    
    func configure() {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppTerminated(_:)),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        #endif
    }
    
}

// MARK: - Auxiliar Functions

internal extension HKLogger {
    
    /// Create a new log file representing a new session after the current has concluded
    @objc private func handleAppTerminated(_ notification: Notification) throws {
    
        log(
            message: "App execution has been terminated",
            severity: .info,
            type: .trace
        )
        
        if saveLogsToFile, let logsPath = logsPath {
            let lastIndex = findLastFileIndex(for: logsPath)
            FileManager.default.createFile(atPath: "\(logsPath.path)_\(lastIndex + 1).log", contents: nil)
        }
        
        if saveLogsToHost, let hostLogsDirectory = hostLogsDirectoryName {
            let lastIndex = findLastFileIndex(for: hostLogsDirectory)
            let path = "\(hostLogsDirectory.path)_\(lastIndex + 1).log"
            
            #if targetEnvironment(simulator)
                FileManager.default.createFile(atPath: path, contents: nil)
            #else
                let data = LogData(
                    path: hostLogsDirectory.path,
                    fileName: fileName,
                    message: "",
                    deviceInfo: logDeviceInfo ? getDeviceInfo() : nil,
                    createNewFile: true
                )
                hostServer?.send(data)
            #endif
        }
        
        logDeviceInfoIfNeeded()
    }
    
    @discardableResult
    func printMessageIfNeeded(
        _ message: String,
        _ severity: HKLoggerSeverityLevel = .debug,
        _ type: HKLoggerType = .default,
        _ fileName: StaticString = #file,
        _ functionName: StaticString = #function,
        _ lineNumber: Int = #line
    ) -> Bool {
        let formattedMessage = getFormattedMessageIfNeeded(for: type, message: message)
        let logMessage = getLogMessageForConsole(formattedMessage, severity, type, fileName, functionName, lineNumber)
        switch environment {
        case .debug:
            print(logMessage)
            return true
        default:
            return false
        }
    }
    
    func saveLogsToFileIfNeeded(
        _ message: String,
        _ severity: HKLoggerSeverityLevel = .debug,
        _ type: HKLoggerType = .default,
        _ fileName: StaticString = #file,
        _ functionName: StaticString = #function,
        _ lineNumber: Int = #line
    ) throws {
        guard
            let logsPath = logsPath
        else {
            return
        }
        
        do {
            let formattedMessage = getFormattedMessageIfNeeded(for: type, message: message)
            let logMessage = "\(getLogMessageForFile(formattedMessage, severity, type, fileName, functionName, lineNumber))\n"
            
            if saveLogsToFile {
                try writeFile(in: logsPath, message: logMessage)
            }
            
            if saveLogsToHost, let hostLogsDirectory = hostLogsDirectoryName {
                try writeFile(in: hostLogsDirectory, message: logMessage, saveOnHostFromDevice: saveLogsInHostFromDevice)
            }
            
        } catch {
            throw HKLoggerError.couldNotSaveToFile(logMessage: error.localizedDescription)
        }
    }
}

// MARK: - General Helpers

internal extension HKLogger {
    
    func getLogMessageForConsole(
        _ message: String,
        _ severity: HKLoggerSeverityLevel,
        _ type: HKLoggerType,
        _ fileName: StaticString,
        _ functionName: StaticString,
        _ lineNumber: Int
    ) -> String {
        return includeMetadataOnConsole
            ? "\(timestamp)\(severity.prefix) \(type.prefix) \(severity.icon) \(createLogMessageWithMetada(from: message, fileName, functionName, lineNumber))"
            : "\(timestamp)\(severity.prefix) \(type.prefix) \(severity.icon) \(message)"
    }
    
    func getLogMessageForFile(
        _ message: String,
        _ severity: HKLoggerSeverityLevel,
        _ type: HKLoggerType,
        _ fileName: StaticString,
        _ functionName: StaticString,
        _ lineNumber: Int
    ) -> String {
        return includeMetadataOnFile
            ? "\(timestamp)\(severity.prefix) \(type.prefix) \(createLogMessageWithMetada(from: message, fileName, functionName, lineNumber))\(endingCharacter)"
            : "\(timestamp)\(severity.prefix) \(type.prefix): \(message)\(endingCharacter)"
    }
    
    func createLogMessageWithMetada(
        from message: String,
        _ fileName: StaticString,
        _ functionName: StaticString,
        _ lineNumber: Int
    ) -> String {
        let file = "\(fileName)"
        return "[\(Thread.current.threadName)] [\(URL(fileURLWithPath: file).lastPathComponent)] [\(functionName)] [Line \(lineNumber)]: \(message)"
    }
    
    func writeFile(in directory: URL, message: String, saveOnHostFromDevice: Bool = false) throws {
        let currentFilePath = "\(directory.path)_\(findLastFileIndex(for: directory)).log"
        
        if saveOnHostFromDevice {
            let logData = LogData(
                path: directory.path,
                fileName: fileName,
                message: message,
                deviceInfo: logDeviceInfo ? getDeviceInfo() : nil
            )
            hostServer?.send(logData)
            
        } else if FileManager.default.fileExists(atPath: currentFilePath) {
            
            guard let url = URL(string: currentFilePath) else { return }
            let fh = try FileHandle(forWritingTo: url)
            fh.seekToEndOfFile()
            try fh.write(contentsOf: Data(message.utf8))
            fh.closeFile()
            
        } else {
            let logfilePath = "\(directory.path)_1.log"
            let content = logDeviceInfo ? "\(getDeviceInfo())\(message)" : message
            
            try content.write(toFile: logfilePath, atomically: true, encoding: .utf8)
        }
    }
    
    
    func getDeviceInfo() -> String {
        #if canImport(UIKit)
        let deviceModel = UIDevice.current.model
        let deviceName = UIDevice.current.name
        let systemName = UIDevice.current.systemName
        let systemVersion = UIDevice.current.systemVersion
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "Unknown"
        var deviceInfo = "**********************\n"
        deviceInfo.append("DeviceModel=\(deviceModel)\n")
        deviceInfo.append("DeviceName=\(deviceName)\n")
        deviceInfo.append("System=\(systemName)\n")
        deviceInfo.append("SystemVersion=\(systemVersion)\n")
        deviceInfo.append("AppVersion=\(appVersion)\n")
        deviceInfo.append("**********************\n")
        
        return deviceInfo
        #else
        return ""
        #endif
    }
    
    func logDeviceInfoIfNeeded() {
        if logDeviceInfo {
            let deviceInfo = getDeviceInfo()
            
            if saveLogsToFile, let logsPath = logsPath {
                try? writeFile(in: logsPath, message: deviceInfo)
            }
            
            if saveLogsToHost, let hostPath = hostLogsDirectoryName {
                try? writeFile(in: hostPath, message: deviceInfo, saveOnHostFromDevice: saveLogsInHostFromDevice)
            }
        }
    }
    
    func findLastFileIndex(for logsPath: URL) -> Int {
        var lastIndex = 1
        let fm = FileManager.default
        let directoryPath = logsPath.deletingLastPathComponent().path
        var isDir: ObjCBool = true
        
        if fm.fileExists(atPath: directoryPath, isDirectory: &isDir) {
            let files = try? fm.contentsOfDirectory(atPath: directoryPath)
            
            for name in files ?? [] {
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
    
    func getFormattedMessageIfNeeded(for type: HKLoggerType, message: String) -> String {
        switch type {
        case .networking:
            return type.message ?? message
        default:
            return message
        }
    }
}
