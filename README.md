# HKLogger
## Overview
`HKLogger` is a solution to help developers to log information in an easier way during the development process. In addition, you can use `HKLogger` to save your logs into a logs file that can be useful to troubleshoot in a production environment.
​
### Console printing
​
- 2023-01-01T12:00:00 - [DEBUG] [HEALTH] Debug log
- 2023-01-01T12:00:00 - [INFO] [ANALYTICS] ℹ️ Info log
- 2023-01-01T12:00:00 - [WARNING] [NETWORKING] ⚠️ Warning log
- 2023-01-01T12:00:00 - [ERROR] [TRACE] ❌ Error log
​
### Logs file
```
2023-01-01T12:00:00 - [DEBUG] [ANALYTICS]: Testing Debug Messageˆˆˆ
2023-01-01T12:00:00 - [DEBUG] [HEALTH]: Testing Debug messageˆˆˆ
2023-01-01T12:00:00 - [DEBUG] [TRACE] [main] [HKLoggerFileTests.swift] [testDebugLogMessageWithMetaData()] [Line 159]: Testing Debug message with MetaDataˆˆˆ
2023-01-01T12:00:00 - [ERROR] [HEALTH]: Testing Error messageˆˆˆ
2023-01-01T12:00:00 - [INFO] [ANALYTICS]: Testing Info messageˆˆˆ
2023-01-01T12:00:00 - [WARNING] [DEFAULT]: Testing Warning messageˆˆˆ
```
​
## Installation
### SwiftPM
In Xcode go to File > Add Packages.
In the Search or Enter Package URL search box enter this URL: https://github.com/Houlak/hklogger
​
## Usage
### Setup Logger Instance
HKLogger is available as a shared instance, you can access it by using `HKLogger.shared`. Also, you can configure it with the settings that suit best for your project.
​
- `HKLogger.shared.saveLogsToFile` - Indicates if the logs need to be stored on a file within the device
- `HKLogger.shared.saveLogsToHost` - Indicates if the logs needs to be stored in the host file system
- `HKLogger.shared.hostLogsDirectory` - If `saveLogsToHost` is true, then you can define the directory where you want to store the file
- `HKLogger.shared.logsDirectoryName` - Log's file directory
- `HKLogger.shared.environment` - `debug` or `release`
- `HKLogger.shared.includeMetadataOnConsole` - Indicates if the metadata should be included in the printing messages
- `HKLogger.shared.includeMetadataOnFile` - Indicates if the metadata should be included in the file's messages
​
#### Metadata information:
- thread where the log was generated
- file where the log was generated
- function where the log was generated
- line where the log was generated
​
### Logging
```swift
/// Print the log message in console and/or add it to the logs file
///
/// - Parameters:
///     - message: The message to be logged
///     - severity: The severity of the message (debug, info, warning, or error)
///     - type: The type of the message (analytics, networking, trace, health, default)
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
```
​
### Example
```swift
let logger = HKLogger.shared
logger.includeMetadataOnConsole = false
logger.includeMetadataOnFile = true
logger.environment = .debug
logger.saveLogsToFile = true
logger.logsDirectoryName = URL(string: "TestingLogs.log")
​
do {
    try logger.log(message: "Testing \(logger.logsDirectoryName?.path)", severity: .info, type: .health)
} catch let loggerError as HKLoggerError {
    print(loggerError.debugMessage)
} catch {
    print(error)
}
```

#### Save the logs file to the host's machine
​
​In case you want to additionally save the logs in the host's machine, you have to define a few more settings:
```swift
logger.saveLogsToHost = true
// Warning: The directory path must not contain any spaces!
logger.hostLogsDirectory = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(".logs")
```

Besides, if you are running your app on a physical device, it's mandatory to run the script in the `Scripts` folder **on the host Mac**. Due to the sandbox environment, it's necessary to establish a connection between the device and the host Mac itself.
​
## Contribution
If you want to report a bug or need a new feature, open an issue from the issues tab.
