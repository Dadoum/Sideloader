import Foundation
import SideloaderBackend

extension String {
    func withDString<Result>(function: (DString) throws -> Result) rethrows -> Result {
        let data = self.data(using: .ascii)!
        return try! data.withUnsafeBytes<Result> { (bytes: UnsafeRawBufferPointer) in
            let charBytes = bytes.bindMemory(to: CChar.self)
            let dstr = DString(charBytes.count, charBytes.baseAddress)
            return try function(dstr)
        }
    }
}

"Hello world from Swift".withDString {
    hello($0)
}
