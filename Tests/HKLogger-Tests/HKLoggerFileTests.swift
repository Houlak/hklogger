//
//  HKLoggerFileTests.swift
//  HKLogger-Tests
//
//  Created by Bruno Lorenzo on 31/8/22.
//
import XCTest
@testable import HKLogger

final class HKLoggerFileTests: XCTestCase {
    
    let logger = HKLogger.shared
    
    override func setUp() {
        super.setUp()
        
        logger.saveLogsToFile = true
        logger.includeTimestamp = false
        logger.logDeviceInfo = false
        logger.logsDirectoryName = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        clearFiles()
    }
    
    override func tearDown() {
        super.tearDown()
    }
}

extension HKLoggerFileTests {
    
    func testDebugLogMessage() throws {
        let logMessage = "Testing Debug message"
        try logger.saveLogsToFileIfNeeded(logMessage)

        let fileURL = URL(string: "\(logger.logsPath!)_1.log")!
        
        do {
            let readText = try String(contentsOf: fileURL, encoding: .utf8)
            XCTAssertEqual("[DEBUG] [DEFAULT]: \(logMessage)\(logger.endingCharacter)\n", readText)
        } catch {
            XCTFail("Couldn't read file \(String(describing: fileURL.path))")
        }

        clearFiles()
    }
    
    func testInfoLogMessage() throws {
        let logMessage = "Testing Info message"
        try logger.saveLogsToFileIfNeeded(logMessage, .info, .analytics)
        
        let fileURL = URL(string: "\(logger.logsPath!)_1.log")!
        
        do {
            let readText = try String(contentsOf: fileURL, encoding: .utf8)
            XCTAssertEqual("[INFO] [ANALYTICS]: \(logMessage)\(logger.endingCharacter)\n", readText)
        } catch {
            XCTFail("Couldn't read file \(String(describing: fileURL.path))")
        }
        
        clearFiles()
    }
    
    func testWarningLogMessage() throws {
        let logMessage = "Testing Warning message"
        try logger.saveLogsToFileIfNeeded(logMessage, .warning, .health)
        
        let fileURL = URL(string: "\(logger.logsPath!)_1.log")!
        
        do {
            let readText = try String(contentsOf: fileURL, encoding: .utf8)
            XCTAssertEqual("[WARNING] [HEALTH]: \(logMessage)\(logger.endingCharacter)\n", readText)
        } catch {
            XCTFail("Couldn't read file \(String(describing: fileURL.path))")
        }
                           
        clearFiles()
    }
    
    func testErrorLogMessage() throws {
        let logMessage = "Testing Error message"
        logger.includeMetadataOnFile = false
        try logger.saveLogsToFileIfNeeded(logMessage, .error)
        
        let fileURL = URL(string: "\(logger.logsPath!)_1.log")!
        
        do {
            let readText = try String(contentsOf: fileURL, encoding: .utf8)
            XCTAssertEqual("[ERROR] [DEFAULT]: \(logMessage)\(logger.endingCharacter)\n", readText)
        } catch {
            XCTFail("Couldn't read file \(String(describing: fileURL.path))")
        }
                
        clearFiles()
    }
    
    func testDebugHostLogFileMessage() throws {
        let logMessage = "Testing Debug Message"
        logger.includeMetadataOnFile = false
        logger.saveLogsToHost = true
        
        let hostDirectory = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().deletingPathExtension().appendingPathComponent(".logs")
        /// Create the host directory if not exists
        try FileManager.default.createDirectory(
            atPath: hostDirectory.path,
            withIntermediateDirectories: true,
            attributes: nil)
        logger.hostLogsDirectory = hostDirectory
        try logger.saveLogsToFileIfNeeded(logMessage, .debug)
        
        logger.saveLogsToHost = false
        
        let fileURL = URL(string: "\(logger.hostLogsDirectoryName!)_1.log")!
        
        do {
            let readText = try String(contentsOf: fileURL, encoding: .utf8)
            XCTAssertEqual("[DEBUG] [DEFAULT]: \(logMessage)\(logger.endingCharacter)\n", readText)
        } catch {
            XCTFail("Couldn't read file \(String(describing: fileURL.path))")
        }
            
        try FileManager.default.removeItem(atPath: fileURL.path)
        
        clearFiles()
    }

}

// MARK: - MetaData

extension HKLoggerFileTests {
    
    func testCreateLogMessageWithMetada() {
        let logMessage = "Log message with MetaData\n"
        let expectedValue = "[main] [HKLoggerFileTests.swift] [testCreateLogMessageWithMetada()] [Line 135]: \(logMessage)"
        let receivedValue = logger.createLogMessageWithMetada(from: logMessage, #file, #function, #line)
        XCTAssertEqual(expectedValue, receivedValue)
        
        clearFiles()
    }
    
    func testGetLogMessageForConsoleWithMetaData() {
        let logMessage = "Log message with MetaData\n"
        let expectedValue = "[DEBUG] [DEFAULT]  [main] [HKLoggerFileTests.swift] [testGetLogMessageForConsoleWithMetaData()] [Line 145]: \(logMessage)"
        logger.includeMetadataOnConsole = true
        let receivedValue = logger.getLogMessageForConsole(logMessage, .debug, .default, #file, #function, #line)
        XCTAssertEqual(expectedValue, receivedValue)
        
        clearFiles()
    }
    
    func testGetLogMessageForConsoleWithoutMetaData() {
        let logMessage = "Log message without MetaData"
        let expectedValue = "[DEBUG] [DEFAULT]  \(logMessage)"
        logger.includeMetadataOnConsole = false
        let receivedValue = logger.getLogMessageForConsole(logMessage, .debug, .default, #file, #function, #line)
        XCTAssertEqual(expectedValue, receivedValue)
    }
    
    func testGetLogMessageForFileWithMetaData() {
        let logMessage = "Log message with MetaData\n"
        let expectedValue = "[DEBUG] [DEFAULT] [main] [HKLoggerFileTests.swift] [testGetLogMessageForFileWithMetaData()] [Line 163]: \(logMessage)\(logger.endingCharacter)"
        logger.includeMetadataOnFile = true
        let receivedValue = logger.getLogMessageForFile(logMessage, .debug, .default, #file, #function, #line)
        XCTAssertEqual(expectedValue, receivedValue)
        
        clearFiles()
    }
    
    func testGetLogMessageForFileWithoutMetaData() {
        let logMessage = "Log message without MetaData"
        let expectedValue = "[DEBUG] [DEFAULT]: \(logMessage)\(logger.endingCharacter)"
        logger.includeMetadataOnFile = false
        let receivedValue = logger.getLogMessageForFile(logMessage, .debug, .default, #file, #function, #line)
        XCTAssertEqual(expectedValue, receivedValue)
    }
    
    func testDebugLogMessageWithMetaData() throws {
        logger.includeMetadataOnFile = true
        let logMessage = "Testing Debug message with MetaData"
        let formattedMessage = getFormattedNetworkingMessage()
        let expectedValue = "[DEBUG] [NETWORKING] [main] [HKLoggerFileTests.swift] [testDebugLogMessageWithMetaData()] [Line 183]: \(formattedMessage)\(logger.endingCharacter)\n"
        let urlRequest = getURLRequest()
        try logger.saveLogsToFileIfNeeded(logMessage, .debug, .networking(
            request: urlRequest,
            response: HTTPURLResponse(),
            body: nil
        ))
        
        let fileURL = URL(string: "\(logger.logsPath!)_1.log")!
        
        do {
            let readText = try String(contentsOf: fileURL, encoding: .utf8)
            XCTAssertEqual(expectedValue, readText)
        } catch {
            XCTFail("Couldn't read file \(String(describing: fileURL))")
        }
        
        clearFiles()
    }
    
}

// MARK: - Find Last File Index

extension HKLoggerFileTests {
    
    func testIndexWithNoFiles() {
        let lastIndex = logger.findLastFileIndex(for: logger.logsDirectoryName!)
        XCTAssertEqual(lastIndex, 1)
    }
    
    func testIndexWithDefaultFile() {
        let filePath = "\(logger.logsPath!.path)_1.log"
        FileManager.default.createFile(atPath: filePath, contents: nil)
        let lastIndex = logger.findLastFileIndex(for: logger.logsDirectoryName!)
        XCTAssertEqual(lastIndex, 1)
        
        clearFiles()
    }
    
    func testIndexWithManyFiles() {
        let firstFilePath = "\(logger.logsPath!.path)_1.log"
        FileManager.default.createFile(atPath: firstFilePath, contents: nil)
        let secondFilePath = "\(logger.logsPath!.path)_2.log"
        FileManager.default.createFile(atPath: secondFilePath, contents: nil)
        let thirdFilePath = "\(logger.logsPath!.path)_3.log"
        FileManager.default.createFile(atPath: thirdFilePath, contents: nil)
        let fourthFilePath = "\(logger.logsPath!.path)_4.log"
        FileManager.default.createFile(atPath: fourthFilePath, contents: nil)
        
        
        let lastIndex = logger.findLastFileIndex(for: logger.logsPath!)
        XCTAssertEqual(lastIndex, 4)
        
        clearFiles()
        try? FileManager.default.removeItem(atPath: secondFilePath)
        try? FileManager.default.removeItem(atPath: thirdFilePath)
        try? FileManager.default.removeItem(atPath: fourthFilePath)
    }
    
    func testIndexWithManyFilesAndWrongFormat() {
        let firstFilePath = "\(logger.logsPath!.path)_1.log"
        FileManager.default.createFile(atPath: firstFilePath, contents: nil)
        let secondFilePath = "\(logger.logsPath!.path)_2.log"
        FileManager.default.createFile(atPath: secondFilePath, contents: nil)
        let thirdFilePath = "\(logger.logsPath!.path)+abc.log"
        FileManager.default.createFile(atPath: thirdFilePath, contents: nil)
        let fourthFilePath = "\(logger.logsPath!.path)_4.log"
        FileManager.default.createFile(atPath: fourthFilePath, contents: nil)
        let fifthFilePath = "\(logger.logsPath!.path)-5.log"
        FileManager.default.createFile(atPath: fifthFilePath, contents: nil)
        
        
        let lastIndex = logger.findLastFileIndex(for: logger.logsPath!)
        XCTAssertEqual(lastIndex, 4)
        
        clearFiles()
        try? FileManager.default.removeItem(atPath: secondFilePath)
        try? FileManager.default.removeItem(atPath: thirdFilePath)
        try? FileManager.default.removeItem(atPath: fourthFilePath)
        try? FileManager.default.removeItem(atPath: fifthFilePath)
    }
    
}

// MARK: - Helpers

private extension HKLoggerFileTests {
    
    func clearFiles() {
        let logFilePath = "\(logger.logsPath!.path)_1.log"
        
        if FileManager.default.fileExists(atPath: logFilePath) {
            try? FileManager.default.removeItem(atPath: logFilePath)
        }
    }
    
    func getURLRequest() -> URLRequest {
        let url = URL(string: "https://www.google.com")
        return URLRequest(url: url!)
    }
    
    // DO NOT CHANGE THE FORMAT OF THIS JSON OR IT WILL MAKE THE TEST FAIL
    func getFormattedNetworkingMessage() -> String {
        let formattedMessage = """
        {
      "path" : "https://www.google.com",
      "method" : "GET",
      "response" : {
        "headers" : {

        },
        "statusCode" : 200
      },
      "request" : {

      }
    }
    """
        return formattedMessage.trimmingCharacters(in: .whitespaces)
    }
}
