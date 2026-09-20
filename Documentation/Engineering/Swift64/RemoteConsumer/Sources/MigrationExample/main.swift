import SwiftJLS

// Stand-in for one predecessor component's pixels; explicitly declared 12-bit.
let oldPixels: [[Int]] = [[0, 1, 4095], [4095, 2048, 2]]
let width = 3
let height = 2
guard oldPixels.count == height,
      oldPixels.allSatisfy({ $0.count == width }) else {
    throw SwiftJLS.CodecError(.invalidArgument, "Unexpected source geometry.")
}
let limits = try SwiftJLS.ResourceLimits(
    maximumDecodedBytes: 1024, maximumPixels: 64,
    maximumDimension: 8, maximumMemoryBytes: 4096)
let descriptor = try SwiftJLS.ImageDescriptor.greyscale16(
    width: width, height: height, meaningfulBits: 12,
    rowBytes: 8, limits: limits)
let destination = try SwiftJLS.ImageDestination.allocate(
    descriptor: descriptor, limits: limits)
let allocationID = destination.storage.allocationID
let image = try destination.writeUInt16 { x, y in
    guard let value = UInt16(exactly: oldPixels[y][x]), value <= 4095 else {
        throw SwiftJLS.CodecError(.invalidArgument, "Sample exceeds 12-bit range.")
    }
    return value
}
guard image.storage.allocationID == allocationID,
      try image.sampleUInt16(x: 2, y: 0) == 4095 else {
    throw SwiftJLS.CodecError(.internalFailure, "Storage trial failed.")
}
let encoder = try SwiftJLS.Encoder()
guard !encoder.capabilities.canEncode else {
    throw SwiftJLS.CodecError(.internalFailure, "Reassess this Milestone 1 trial.")
}
do {
    _ = try await encoder.encode(image, options: .init(resourceLimits: limits))
    throw SwiftJLS.CodecError(.internalFailure, "Unexpected codec success.")
} catch let error as SwiftJLS.CodecError where error.category == .unsupportedFeature {
    print("Storage trial passed; JPEG-LS encoding remains unavailable.")
}
