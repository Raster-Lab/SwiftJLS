// SPDX-License-Identifier: Apache-2.0
import Foundation
import SwiftJLS

let descriptor = try SwiftJLS.ImageDescriptor.greyscale16(width: 3, height: 2, meaningfulBits: 12, rowBytes: 8)
let destination = try SwiftJLS.ImageDestination.allocate(descriptor: descriptor)
let allocationID = destination.storage.allocationID
let image = try destination.writeUInt16 { x, y in x == 2 ? 4095 : UInt16(x + y * 3) }
guard image.storage.allocationID == allocationID,
      try image.sampleUInt16(x: 2, y: 1) == 4095,
      image.descriptor.meaningfulBits == 12 else {
    throw SwiftJLS.CodecError(.internalFailure, "Independent sample preservation failed.")
}
let encoder = try SwiftJLS.Encoder()
let decoder = try SwiftJLS.Decoder()
guard !encoder.capabilities.canEncode, !decoder.capabilities.canDecode else {
    throw SwiftJLS.CodecError(.internalFailure, "Contract-only package advertised codec support.")
}
do {
    _ = try await encoder.encode(image)
    throw SwiftJLS.CodecError(.internalFailure, "Unimplemented encoding succeeded.")
} catch let error as SwiftJLS.CodecError where error.category == .unsupportedFeature { }
print("Independent consumer passed: 12-bit samples and storage identity preserved; codecs explicitly deferred.")
