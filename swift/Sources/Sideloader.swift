import Foundation
import SideloaderBackend

extension String {
    func toDString() -> DString {
        let data = self.data(using: .utf8)!
        return try! data.withUnsafeBytes<DString> { (bytes: UnsafeRawBufferPointer) in
            let charBytes = bytes.bindMemory(to: CChar.self)
            return DString(charBytes.count, charBytes.baseAddress)
        }
    }
}

hello("Hello world from Swift".toDString())
