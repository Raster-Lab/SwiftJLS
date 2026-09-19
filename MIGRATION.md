# Migrating applications from JLSwift to SwiftJLS

The successor now requires Swift 6.4 and retains its OS 27 deployment floors. See the [Swift 6.4 upgrade record](Documentation/Engineering/Swift64/README.md) for development versioning and validation; current codec availability is unchanged.

This guide is for application maintainers and coding agents changing a dependency. Library implementation work follows [AGENTS.md](AGENTS.md) and [IMPLEMENTATION.md](IMPLEMENTATION.md).

**Current status: Milestone 1 API and owning-memory feasibility only. SwiftJLS cannot yet inspect, encode or decode JPEG-LS.** Its codec capabilities are empty and codec operations reject with `CodecError` after preflight checks. Keep the predecessor serving production codec requests until the required successor capabilities are implemented and independently validated. A dependency/import rename alone is insufficient.

This guide uses common contract **0.4.0** and predecessor commit **`299b9a2e5bfe36ef104a3464a27d6c4c82874cc2`**. Compare your application's actual pinned revision before applying it; other predecessor versions may differ. The successor's implemented surface is in [Sources/SwiftJLS](Sources/SwiftJLS); executed coverage and unavailable gates are in [Documentation/MILESTONE1.md](Documentation/MILESTONE1.md).

## Dependency and deployment changes

| Item | Predecessor at the inspected commit | Successor now |
| --- | --- | --- |
| Repository / package | `Raster-Lab/JLSwift` / `JLSwift` | `Raster-Lab/SwiftJLS` / `SwiftJLS` |
| Library product / import | `JPEGLS` / `import JPEGLS` | `SwiftJLS` / `import SwiftJLS` |
| Executable | `jpegls` (target `jpeglscli`) | `swiftjls` provides help/version/capabilities only |
| Swift | Tools 6.2, Swift 6 language mode | Tools 6.4, Swift 6 language mode; complete concurrency checking |
| Apple deployment minima | macOS 12, iOS 15 | macOS, iOS/iPadOS, tvOS, visionOS, watchOS 27.0 |

Evidence: [pinned predecessor manifest](https://github.com/Raster-Lab/JLSwift/blob/299b9a2e5bfe36ef104a3464a27d6c4c82874cc2/Package.swift), [current manifest](Package.swift), [platform qualification requirements](Documentation/PLATFORMS.md). An application supporting older Apple systems must retain a compatible dependency path or deliberately raise its deployment target before linking SwiftJLS. Build-only evidence does not establish device/runtime support.

For a local migration trial, add `.package(path: "../SwiftJLS")` to the consumer's package dependencies and `.product(name: "SwiftJLS", package: "SwiftJLS")` to its executable/application target. Adjust the relative path to your checkout. Alternatively add the local package through Xcode. Keep `JPEGLS` alongside it while the application adapter is being developed.

For a remote trial, use `https://github.com/Raster-Lab/SwiftJLS.git` and pin an actual reviewed full commit SHA available in that repository. Record it in the migration review and commit the application's resolved dependencies. **Do not use a `from: "1.1.0"` requirement yet:** 1.1.0 is intended, not published. SwiftJLS has no dependency on another suite codec or umbrella; adding all four is unnecessary.

## API mapping and current availability

The predecessor calls below are verified in its pinned [encoder](https://github.com/Raster-Lab/JLSwift/blob/299b9a2e5bfe36ef104a3464a27d6c4c82874cc2/Sources/JPEGLS/JPEGLSEncoder.swift), [decoder](https://github.com/Raster-Lab/JLSwift/blob/299b9a2e5bfe36ef104a3464a27d6c4c82874cc2/Sources/JPEGLS/JPEGLSDecoder.swift) and [image types](https://github.com/Raster-Lab/JLSwift/blob/299b9a2e5bfe36ef104a3464a27d6c4c82874cc2/Sources/JPEGLS/Encoder/JPEGLSPixelBuffer.swift). The right column describes actual Milestone 1 behaviour, not feature parity.

| Existing application usage | Successor direction | Available now |
| --- | --- | --- |
| `MultiComponentImageData.grayscale(pixels:bitsPerSample:)`; component `pixels: [[Int]]` | Validated `ImageDescriptor`, owning `ImageDestination`, sealed `Image` | Synthetic storage and unsigned greyscale `writeUInt16` / `sampleUInt16` helpers work |
| `JPEGLSEncoder()`; `encode(_:configuration:) throws -> Data` | `try SwiftJLS.Encoder(configuration:)`; `try await encode(_:options:) -> EncodedImage` | Holder exists; encode throws; eventual compressed bytes are `result.data`, diagnostics `result.report` |
| `JPEGLSDecoder().decode(_:) throws -> MultiComponentImageData` | `try SwiftJLS.Decoder()`; `try await decode(_:options:) -> DecodedImage` | Holder exists; decode throws; eventual samples are `result.image`, diagnostics `result.report` |
| Application header/parser calls | `Decoder.inspect(_:options:) -> ImageInfo` | Synchronous API exists but rejects all compressed input |
| Application-managed decoded buffer | `Decoder.decode(_:into:options:)` | Signature exists; preflight rejection performs no write |
| `JPEGLSEncoder.Configuration(near: 0, ...)` | `EncoderConfiguration(mode: .lossless)` | Configuration accepted; no lossless encoder yet |
| Nonzero `near` | `.nearLossless(maximumAbsoluteError:)`, in integer sample units | Nonpositive bounds are invalid; positive near-lossless bounds are currently unsupported |
| `JPEGLSError` cases | `CodecError.category` and separate `CancellationError` | Remap handling explicitly; no case-for-case compatibility alias |

Interleave modes, presets/MAXVAL, restart intervals, mapping tables and colour transforms are predecessor-specific settings requiring separate capability checks and tests when migrated. Current `CodecOptions` is empty. Do not drop an old setting silently, infer support from an enum case, or replace near-lossless output with another fidelity mode.

## Runnable contract trial

Use this as `main.swift` in a separate executable consumer targeting macOS 27 or another supported deployment target, linked only to the local SwiftJLS library. It copies a small predecessor-shaped array into new owned storage, validates precision and observes the expected codec rejection. It does **not** produce a JPEG-LS file.

```swift
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
```

Run the consumer headlessly with Xcode's selected toolchain using `xcrun swift run --package-path /path/to/consumer`. See the existing [independent consumer manifest](Examples/IndependentConsumer/Package.swift) for a complete package layout. Its repository example can also be run with `xcrun swift run --package-path Examples/IndependentConsumer` from this repository. Record the actual compiler, SDK, command and result; this checks API/storage integration only.

## Application behaviour to preserve

- **Subsampled components:** the predecessor's `MultiComponentImageData` can represent component dimensions derived from sampling factors. Current successor descriptors require every plane to have the full image dimensions, so subsampled component buffers cannot yet enter the storage trial. Retain the old path for these buffers; do not silently upsample or relabel them.
- **Precision and interpretation:** preserve declared precision, dimensions, component roles, signedness, byte order, strides and metadata. For the first storage trial use unsigned greyscale, 16-bit storage and explicit meaningful bits (for example 12); values are low aligned and unsigned high bits must be zero. Do not infer precision from observed maxima, truncate an `Int`, apply display windowing or treat a `UInt16` view as proof of signed codec support. A descriptor accepting a layout does not mean a codec can encode it. Non-power-of-two MAXVAL and presets need explicit future codec treatment.
- **Ownership and copying:** `Image` retains a sealed immutable owner. A destination is single-use; initialise all samples, then share only read access. A failed write/cancelled write cannot publish a partial image. Preflight rejection before a write leaves the reservation usable. Never let a scoped pointer escape, cross `await`, or become an asynchronous owner. The sample above performs an explicit array-to-storage copy; it is not an end-to-end no-copy migration. Custom adapters must satisfy the [memory contract](Documentation/MEMORY_CONTRACT.md); default `requireSharedStorage` forbids a hidden full-frame repack during codec hand-off.
- **Concurrency and limits:** migrate synchronous call sites to structured `try await` calls and retain owners for the operation. Current async stubs use `@concurrent`; real codec scheduling, bounded worker execution and progress remain unimplemented. Keep UI state on its actor; progress closures are `@Sendable`. Set finite `ResourceLimits` at construction and operation boundaries, include padding and concurrent work in budgets, and propagate `CancellationError`. Milestone 1 validates limits and selected preflight checks; it does not demonstrate codec deadline enforcement or throughput.
- **Errors and publication:** map `CodecError.category` to application outcomes instead of parsing messages or reusing the predecessor enum. Separate invalid arguments, unsupported features/layouts, resource exhaustion, unavailable storage/backends and cancellation. Do not turn an unsupported codec into an empty file, successful result or silent lossy fallback. Publish final application output only on successful completion.

## Features that need a separate migration decision

The predecessor has public `PNGSupport` and `TIFFSupport` helpers ([PNG source](https://github.com/Raster-Lab/JLSwift/blob/299b9a2e5bfe36ef104a3464a27d6c4c82874cc2/Sources/JPEGLS/PNGSupport.swift), [TIFF source](https://github.com/Raster-Lab/JLSwift/blob/299b9a2e5bfe36ef104a3464a27d6c4c82874cc2/Sources/JPEGLS/TIFFSupport.swift)). SwiftJLS supplies neither. Inventory direct use of these helpers and retain or separately replace the relevant application functionality.

The predecessor CLI also contains PNM/DICOM handling, batch/conversion/verification and benchmarking commands. The successor [diagnostic CLI](CLI.md) provides help/version/capabilities; payload operations remain unavailable. The [CLI contract](Documentation/CLI_CONTRACT.md) is not a predecessor command compatibility promise. Retain existing scripts until replacement commands are implemented and tested. DICOM transfer syntax, frame encapsulation, signed pixel interpretation and object metadata remain application responsibilities; the common `Image` metadata is not a DICOM object model. No SwiftJLS native transcoder is provided.

## Staged rollout and acceptance checklist

1. Record predecessor and successor commits, contract version, deployment targets, current package products/imports, codec options and auxiliary helper/CLI usage. Capture application regression fixtures with expected samples, precision, metadata and failure behaviour; use licensed synthetic or de-identified data.
2. Introduce an application-owned codec boundary and a separate successor trial target. During coexistence, use explicit module qualifications such as `JPEGLS.JPEGLSEncoder` and `SwiftJLS.Encoder`. Keep predecessor routing as the production default and make successor selection explicit. Common names in different suite modules are different Swift types.
3. Compile the contract trial and the application's adapter with strict Swift 6 checks. Test odd dimensions, padded rows, 12/16-bit extremes, invalid ranges, ownership, repeated writes, cancellation and resource rejection. Keep unsupported colour/signed/near-lossless modes blocked. Record copy/allocation costs of any legacy array conversion.
4. **After actual codec delivery**, check encode/decode/inspect capabilities and each required feature; a boolean alone does not prove an option/layout combination. Validate old compressed files with the successor and new files with both the predecessor and an independent JPEG-LS implementation. Lossless acceptance requires exact logical samples and interpretation; near-lossless requires the declared error bound. Identical compressed bytes are not a general lossless requirement.
5. Qualify application targets, memory, cancellation, concurrency, performance and persistence/output handling before a controlled rollout. Keep rollback to the pinned predecessor until all required features pass. Do not re-encode a stored corpus merely to rename the library.
6. Remove the predecessor dependency, imports and obsolete scripts only after every required call site is covered. Update application lockfiles, user documentation and release notes with deliberate deployment/behaviour changes and remaining limitations.

For coding agents: an application-migration task does not authorise implementing later codec milestones, changing common contracts, inventing missing APIs, tagging a release or declaring feature parity. Report modified call sites, exact revisions, commands/results, unavailable features and deferred acceptance gates. Stop production cutover at the current capability boundary while completing the authorised adapter/documentation work.

## Apple runtime qualification update

See [Apple platform runtime qualification](Documentation/Engineering/ApplePlatforms/README.md) for executed OS 27 simulator, macOS and Mac Catalyst tests and the reproducible headless runner. This qualifies the current API/storage foundation; the existing codec migration and production-cutover gates remain in force.
