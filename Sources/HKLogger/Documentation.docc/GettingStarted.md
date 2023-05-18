# Getting Started

## Overview

`HKLogger` is available as a shared instance, you can access it by using HKLogger.shared property. You can configure the instance with the settings that suit best for your project. 

## Configure Logger Instance
The best place to configure `HKLogger` instance is in your AppDelegate. However, you can place it any place that suits you best.

### Environment
- ``HKLogger/HKLogger/environment`` - ``HKLoggerEnv/debug`` or ``HKLoggerEnv/release``

You should configure the environment depending on the mode you're compiling the application. If you set it to `release`, the printing feature will be skipped.

### Metadata
- ``HKLogger/HKLogger/includeMetadataOnConsole`` Indicates if the metadata should be included in the printing messages
- ``HKLogger/HKLogger/includeMetadataOnFile`` - Indicates if the metadata should be included in the file's messages

Keep in mind that the metadata info should be taking from the file, class, and function that execute the log function. If you make a wrapper above HKLogger (see example below), the metadata logged will be always the same.
```swift
//
//  Logger.swift
//  

import HKLogger

final class Logger {
    static let shared = Logger()
    private init() {}

    func logMessage(_ message: String) {
        HKLogger.log(message: "Testing message", severity: .info, type: .default)
    }
}
```
Here, the metadata will be:
- **File** Logger.swift
- **Function** logMessage(:string)
- **line** 12

If you won't be using the metadata information, then the previous approach is a good solution. However, if you find the metadata helpful in your debug process, consider using the log function directly from `HKLogger` whenever you want.

### Saving to file
You can save your logs file to the device or simulator where your app is running, and in the machine you're running Xcode. This is helpful when you're in a development phase and want to use `HKLogger` together with our Logs Viewer [Mate](https://github.com/Houlak/mate)

- ``HKLogger/HKLogger/saveLogsToFile`` - Indicates if the logs need to be stored on a file within the device
- ``HKLogger/HKLogger/logsDirectoryName`` Indicates the directory where the files needs to be store on the device (or simulator)
- ``HKLogger/HKLogger/saveLogsToHost`` Indicates if the logs needs to be stored in the host's file system
- ``HKLogger/HKLogger/hostLogsDirectory`` If ``HKLogger/HKLogger/saveLogsToHost`` is true, then you can define the directory where you want to store the file in the host's file system.

## Working with a physical device
If you're running your app in a phyisical device and want to save the logs on the host machine, it's necessary to establish a connection between the device and the host Mac itself. To do that, run the `ClientScript` stored in **Scripts/** folder in the host machine. The script will entablish a connection between the two devices.

```bash
$ swift ClientScript
```

You also need to set the `hostLogsDirectory` property. 
- Please note that this path must not contain any spaces!
- The URL should be relateive to the file in with you're configuring the instance. You can not create the URL with an absolute path like this:
```swift
URL(string: "/users/blorenzo/dev/projects/logger-demo/.logs")
```
We recommenden using `deletingLastPathComponent()` built-in function.
- Example: `URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent(".logs")`

## Working with networking request
If you want to log a networking request, take adavantage of ``HKLoggerType/networking(request:response:responseBody:)``. `HKLogger` will format the request and response in a JSON format.

```swift
HKLogger.shared.saveLogsToFileIfNeeded(
    logMessage, 
    .debug, 
    .networking(
        request: urlRequest,
        response: httpResponse,
        responseBody: responseBody
    )
)
```

## Example
```swift
import HKLogger

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        configureLogger()
        return true
    }
}

extension AppDelegate {
    func configureLogger() {
        let logger = HKLogger.shared
        logger.includeMetadataOnConsole = false
        logger.includeMetadataOnFile = true
        logger.environment = .debug
        logger.saveLogsToFile = true
        logger.logsDirectoryName = URL(string: "TestingLogs.log")
    }
}
```
