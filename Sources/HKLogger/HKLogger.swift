import Foundation
import UIKit

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
    public var saveLogsToHost = false
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
    
    // MARK: - Initialization
    
    private init() {}
    
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
    ) throws {
        printMessageIfNeeded(message, severity, type, fileName, functionName, lineNumber)
        try saveLogsToFileIfNeeded(message, severity, type, fileName, functionName, lineNumber)
    }
}

// MARK: - Life Cycle Config

public extension HKLogger {
    
    func configure() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppTerminated(_:)),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
}

// MARK: - Auxiliar Functions

internal extension HKLogger {
    
    /// Create a new log file representing a new session after the current has concluded
    @objc private func handleAppTerminated(_ notification: Notification) throws {
        do {
            try log(
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
                FileManager.default.createFile(atPath: "\(hostLogsDirectory.path)_\(lastIndex + 1).log", contents: nil)
            }
            
            logDeviceInfoIfNeeded()

        } catch {
            throw HKLoggerError.couldNotSaveToFile(logMessage: error.localizedDescription)
        }
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
        let logMessage = getLogMessageForConsole(message, severity, type, fileName, functionName, lineNumber)
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
            let logMessage = "\(getLogMessageForFile(message, severity, type, fileName, functionName, lineNumber))\n"
            
            if saveLogsToFile {
                try writeFile(in: logsPath, message: logMessage)
            }
            
            if saveLogsToHost, let hostLogsDirectory = hostLogsDirectoryName {
                try writeFile(in: hostLogsDirectory, message: logMessage)
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
            : "\(timestamp)\(severity.prefix) \(type.prefix) \(message)\(endingCharacter)"
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
    
    func writeFile(in directory: URL, message: String) throws {
        let currentFilePath = "\(directory.path)_\(findLastFileIndex(for: directory)).log"
        
        if FileManager.default.fileExists(atPath: currentFilePath) {
            
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
    }
    
    func logDeviceInfoIfNeeded() {
        if logDeviceInfo {
            let deviceInfo = getDeviceInfo()
            
            if saveLogsToFile, let logsPath = logsPath {
                try? writeFile(in: logsPath, message: deviceInfo)
            }
            
            if saveLogsToHost, let hostPath = hostLogsDirectoryName {
                try? writeFile(in: hostPath, message: deviceInfo)
            }
        }
    }
    
    func findLastFileIndex(for logsPath: URL) -> Int {
        var lastIndex = 1
        let fm = FileManager.default
        let directoryPath = logsPath.deletingLastPathComponent().path
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
