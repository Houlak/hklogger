import XCTest
@testable import HKLogger

final class HKLoggerPrintingTests: XCTestCase {
    
    let logger = HKLogger.shared
    
    override func setUp() {
        super.setUp()
        logger.saveLogsToFile = false
    }
    
    override func tearDown() {
        super.tearDown()
    }
}

// MARK: - Console printing

extension HKLoggerPrintingTests {
    
    func testPrintToConsoleInDebugMode() {
        logger.environment = .debug
        let printingResult = logger.printMessageIfNeeded("Testing printing message on Console")
        XCTAssertEqual(printingResult, true)
    }
    
    func testPrintToConsoleInReleaseMode() {
        logger.environment = .release
        let printingResult = logger.printMessageIfNeeded("Testing printing message on Console")
        XCTAssertEqual(printingResult, false)
    }
    
    func testPrintToConsoleInDebugWithMetadata() {
        logger.environment = .debug
        logger.includeMetadataOnConsole = true
        let printingResult = logger.printMessageIfNeeded("Testing printing message on Console with MetaData", .info)
        XCTAssertEqual(printingResult, true)
    }
    
    func testPrintToConsoleInReleaseWithMetadata() {
        logger.environment = .release
        logger.includeMetadataOnConsole = false
        let printingResult = logger.printMessageIfNeeded("Testing printing message on Console with MetaData", .info)
        XCTAssertEqual(printingResult, false)
    }
    
}
