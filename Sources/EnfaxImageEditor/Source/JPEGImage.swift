import Foundation

public struct JPEGImage: Equatable {
    public let name: String
    public let data: Data
    
    public init(name: String, data: Data) {
        self.name = name
        self.data = data
    }
}
