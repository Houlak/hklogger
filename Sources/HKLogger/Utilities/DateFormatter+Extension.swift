import Foundation

internal extension Date {
    
    static func customDateFormatter(with format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter
    }
    
    var stringyyyyMMddTHHmmss: String {
        let formatter = Date.customDateFormatter(with: "yyyy-MM-dd'T'HH:mm:ss")
        return formatter.string(from: self)
    }
}
