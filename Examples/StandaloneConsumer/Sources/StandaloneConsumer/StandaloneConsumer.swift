// SPDX-License-Identifier: MIT
import Foundation
import SwiftJLS

enum ConsumerFailure: Error { case unexpectedSuccess, wrongSamples, wrongIdentity, wrongCapabilities }

/// A consumer-defined adapter retains an actual sealed provider and forwards its
/// identity and scoped borrow. It neither copies pixels nor discovers a sibling.
final class ConsumerReadAdapter: SwiftJLS.ReadOnlyImageStorage {
    let owner: any SwiftJLS.ReadOnlyImageStorage
    init(owner: any SwiftJLS.ReadOnlyImageStorage) { self.owner = owner }
    var byteCount: Int { owner.byteCount }
    var allocationID: UUID { owner.allocationID }
    func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) throws -> R {
        try owner.withUnsafeBytes(body)
    }
}

@main
struct StandaloneConsumer {
    static func main() async throws {
        let descriptor = try SwiftJLS.ImageDescriptor.greyscale16(
            width: 3, height: 2, meaningfulBits: 12, rowBytes: 8)
        let destination = try SwiftJLS.ImageDestination.allocate(descriptor: descriptor)
        let expected: [UInt16] = [0, 4095, 1, 2048, 17, 4094]
        for y in 0..<2 {
            for x in 0..<3 { try destination.setSample(expected[y * 3 + x], x: x, y: y) }
        }
        let image = try destination.seal()
        let adapter = ConsumerReadAdapter(owner: image.storage)
        let adapted = try SwiftJLS.Image(descriptor: descriptor, storage: adapter, metadata: image.metadata)
        guard adapted.storage.allocationID == image.storage.allocationID else { throw ConsumerFailure.wrongIdentity }
        for y in 0..<2 {
            for x in 0..<3 {
                guard try adapted.sample(x: x, y: y) == expected[y * 3 + x] else { throw ConsumerFailure.wrongSamples }
            }
        }
        let encoder = try SwiftJLS.Encoder(configuration: SwiftJLS.EncoderConfiguration())
        let decoder = try SwiftJLS.Decoder(configuration: SwiftJLS.DecoderConfiguration())
        guard !encoder.capabilities.supportsEncoding,
              !decoder.capabilities.supportsDecoding,
              !decoder.capabilities.supportsInspection else { throw ConsumerFailure.wrongCapabilities }
        do {
            _ = try decoder.inspect(Data(), options: SwiftJLS.DecodeOptions())
            throw ConsumerFailure.unexpectedSuccess
        } catch let error as SwiftJLS.CodecError where error.category == .unsupportedFeature {}
        do {
            _ = try await encoder.encode(adapted, options: SwiftJLS.EncodeOptions())
            throw ConsumerFailure.unexpectedSuccess
        } catch let error as SwiftJLS.CodecError where error.category == .unsupportedFeature {}
        do {
            _ = try await decoder.decode(Data(), options: SwiftJLS.DecodeOptions())
            throw ConsumerFailure.unexpectedSuccess
        } catch let error as SwiftJLS.CodecError where error.category == .unsupportedFeature {}
        let output = try SwiftJLS.ImageDestination.allocate(descriptor: descriptor)
        do {
            _ = try await decoder.decode(Data(), into: output, options: SwiftJLS.DecodeOptions())
            throw ConsumerFailure.unexpectedSuccess
        } catch let error as SwiftJLS.CodecError where error.category == .unsupportedFeature {}
        do {
            _ = try output.seal()
            throw ConsumerFailure.unexpectedSuccess
        } catch let error as SwiftJLS.CodecError where error.category == .storageUnavailable {}
        print("SwiftJLS Milestone 1: independent API and retained-storage checks passed; codec operations remain unavailable.")
    }
}
