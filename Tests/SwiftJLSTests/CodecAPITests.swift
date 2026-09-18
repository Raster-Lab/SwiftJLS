// SPDX-License-Identifier: MIT
import Foundation
import Synchronization
import Testing
import SwiftJLS

@Suite("Public codec API feasibility, without a codec implementation")
struct CodecAPITests {
    @Test("Defaults preserve fidelity, interpretation and supplied storage")
    func defaultOptions() throws {
        let encoder = try Encoder()
        let decoder = try Decoder()
        #expect(encoder.configuration.mode == .lossless)
        #expect(encoder.configuration == .lossless)
        #expect(decoder.configuration == .preserving)
        let encode = EncodeOptions()
        let decode = DecodeOptions()
        #expect(encode.copyPolicy == .requireSharedStorage)
        #expect(decode.copyPolicy == .requireSharedStorage)
        #expect(encode.metadataPolicy == .preserve)
        #expect(decode.metadataPolicy == .preserve)
        #expect(encode.executionPolicy == .automatic)
        #expect(decode.executionPolicy == .automatic)
        #expect(encode.resourceLimits == .default)
        #expect(decode.resourceLimits == .default)
        #expect(encode.progress == nil)
        #expect(decode.progress == nil)
    }

    @Test("Capability descriptions advertise no unfinished codec operation")
    func truthfulCapabilities() throws {
        let encoder = try Encoder()
        let decoder = try Decoder()
        for capabilities in [Encoder.capabilities, Decoder.capabilities, encoder.capabilities, decoder.capabilities] {
            #expect(!capabilities.supportsEncoding)
            #expect(!capabilities.supportsDecoding)
            #expect(!capabilities.supportsInspection)
            #expect(capabilities.formats.isEmpty)
            #expect(capabilities.compressionModes.isEmpty)
            #expect(capabilities.sampleTypes.isEmpty)
            #expect(capabilities.meaningfulBits == nil)
            #expect(capabilities.layouts.isEmpty)
            #expect(capabilities.backends.isEmpty)
        }
    }

    @Test("Near-lossless construction validates error bounds without pretending support")
    func unsupportedModes() throws {
        expectCodecError(.invalidArgument) { try EncoderConfiguration(mode: .nearLossless(maximumAbsoluteError: 0)) }
        expectCodecError(.invalidArgument) { try EncoderConfiguration(mode: .nearLossless(maximumAbsoluteError: -1)) }
        expectCodecError(.unsupportedFeature) { try EncoderConfiguration(mode: .nearLossless(maximumAbsoluteError: 1)) }
        expectCodecError(.unsupportedFeature) { try EncoderConfiguration(mode: .nearLossless(maximumAbsoluteError: Int.max)) }
        expectCodecError(.unsupportedFeature) { try EncoderConfiguration(mode: .lossy) }
        #expect(try EncoderConfiguration().mode == .lossless)
    }

    @Test("Every codec call has the agreed public shape and fails explicitly")
    func allOperationShapes() async throws {
        let descriptor = try ImageDescriptor.greyscale16(width: 1, height: 1, meaningfulBits: 12)
        let source = try ImageDestination.allocate(descriptor: descriptor)
        try source.setSample(4095, x: 0, y: 0)
        let image = try source.seal()
        let encoder = try Encoder(configuration: EncoderConfiguration())
        let decoder = try Decoder(configuration: DecoderConfiguration())
        let updates = ProgressRecorder()
        let encodeOptions = EncodeOptions(progress: { updates.record($0) })
        let decodeOptions = DecodeOptions(progress: { updates.record($0) })
        expectCodecError(.unsupportedFeature) { try decoder.inspect(Data(), options: decodeOptions) }
        await expectAsyncCodecError(.unsupportedFeature) { try await encoder.encode(image, options: encodeOptions) }
        await expectAsyncCodecError(.unsupportedFeature) { try await decoder.decode(Data(), options: decodeOptions) }
        let destination = try ImageDestination.allocate(descriptor: descriptor)
        await expectAsyncCodecError(.unsupportedFeature) {
            try await decoder.decode(Data(), into: destination, options: decodeOptions)
        }
        expectCodecError(.storageUnavailable) { try destination.seal() }
        #expect(updates.count == 0)
        #expect(try image.sample(x: 0, y: 0) == 4095)
    }

    @Test("Decode admission failure cannot publish a caller destination")
    func failedAdmissionInvalidatesDestination() async throws {
        let descriptor = try ImageDescriptor.greyscale16(width: 1, height: 1)
        let owner = try OwnedImageStorage(byteCount: 2)
        let destination = try ImageDestination(descriptor: descriptor, storage: owner)
        let decoder = try Decoder()
        let limits = try ResourceLimits(maximumInputBytes: 2)
        await expectAsyncCodecError(.resourceLimitExceeded) {
            try await decoder.decode(Data([0, 1, 2]), into: destination, options: DecodeOptions(resourceLimits: limits))
        }
        #expect(owner.state == .invalid)
        expectCodecError(.storageUnavailable) { try destination.seal() }
        expectCodecError(.storageUnavailable) { try owner.readOnlyStorage() }
    }

    @Test("Cancellation precedes codec work and invalidates supplied output")
    func cancellationIsNotWrapped() async throws {
        let descriptor = try ImageDescriptor.greyscale16(width: 1, height: 1)
        let owner = try OwnedImageStorage(byteCount: 2)
        let destination = try ImageDestination(descriptor: descriptor, storage: owner)
        let decoder = try Decoder()
        let cancelled = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await decoder.decode(Data(), into: destination)
        }
        do {
            _ = try await cancelled.value
            Issue.record("A cancelled decode returned success")
        } catch is CancellationError {
            // This exact public error type must survive the async boundary.
        } catch {
            Issue.record("Cancellation was replaced by \(type(of: error))")
        }
        #expect(owner.state == .invalid)
        expectCodecError(.storageUnavailable) { try destination.seal() }
    }

    @Test("Unmeasured resource reports do not invent zero measurements")
    func reportUnknownsAndValidation() throws {
        let report = try OperationReport(backend: .scalarCPU, fidelity: .exactSamples, processingPath: .samples)
        #expect(report.pixelAllocationCount == nil)
        #expect(report.peakPixelBytes == nil)
        #expect(report.peakWorkspaceBytes == nil)
        #expect(report.elapsed == nil)
        expectCodecError(.invalidArgument) {
            try OperationReport(backend: .scalarCPU, fidelity: .exactSamples, processingPath: .samples, pixelAllocationCount: -1)
        }
        expectCodecError(.invalidArgument) {
            try CopyEvent(reason: "invalid", bytesMoved: -1, sourceLayout: "grey16", destinationLayout: "grey16")
        }
    }
}

private final class ProgressRecorder: Sendable {
    private let updates = Mutex<[ProgressUpdate]>([])
    var count: Int { updates.withLock { $0.count } }
    func record(_ update: ProgressUpdate) { updates.withLock { $0.append(update) } }
}
