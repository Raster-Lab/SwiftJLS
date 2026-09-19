# SwiftJLS

JPEG-LS for the **Swift Image Compression Suite**.

**Status: Milestone 1 API and owning-memory feasibility implemented.** The standalone package builds and its synthetic contract tests run locally with headless Xcode tools. JPEG-LS encoding, inspection and decoding are **not implemented**; codec operations fail explicitly and capabilities remain empty. The intended stable version **1.1.0** is not a published release. See [exact validation evidence and limitations](Documentation/MILESTONE1.md).

SwiftJLS is the standalone successor to [JLSwift](https://github.com/Raster-Lab/JLSwift). The successor is intended to provide a harmonised API, explicit memory ownership, high-precision sample preservation and efficient shared-storage integration. It has no mandatory dependency on another suite library or CompressionFamily. MIT licensing applies to these documents and subsequent authorised in-house implementation; third-party material retains its own terms.

## Swift 6.4 development candidate

Current development version: **1.1.0-dev.2** ([VERSION](VERSION)); shared contract **0.4.0**. This increments the earlier unreleased 1.0.0 target and creates no release/tag. See the [current qualification record](Documentation/Engineering/OS27CLI/README.md) for adopted features, exact Xcode/Swift Build evidence and open platform gates. The historical [Milestone 1 evidence](Documentation/MILESTONE1.md) remains unchanged.

## Apple platform runtime tests

The existing API/storage foundation now passes complete Debug and Release suites on macOS arm64, Mac Catalyst and OS 27 simulators for iPhone, iPad, Apple TV, Apple Watch and Vision Pro. See [Apple platform runtime qualification](Documentation/Engineering/ApplePlatforms/README.md) for exact counts, commands, source hashes and remaining physical-device/Intel/Linux gates. Codec algorithms and compressed-format interoperability remain deferred. Current development version **1.1.0-dev.2** is unchanged because this update adds qualification tooling and tests without changing the shipped API or behaviour.

## Intended platform baseline

Swift 6.4 minimum, Swift 6 language mode and complete concurrency checking. Apple OS deployment minima: macOS, iOS/iPadOS, tvOS, visionOS and watchOS 27.0. Apple Silicon is the primary optimisation target. macOS x86_64 and Linux ARM64/x86_64 are included with cleanly separated platform/architecture support. Ubuntu 24.04 is the initial Linux engineering baseline. These are requirements, not completed qualification claims.

## Start reading

**Moving an application from JLSwift? Read [MIGRATION.md](MIGRATION.md)** for dependency/import changes, the current API mapping, a runnable storage trial and the gates before production cutover. Codec replacement remains blocked until later milestones supply the required JPEG-LS capabilities.

The current implementation is **Milestone 1: API and memory-contract feasibility**, using synthetic buffers. Codec migration and the first real shared-storage transcode remain separately assigned Milestones 2 and 3. Start with [the evidence record](Documentation/MILESTONE1.md) and [AGENTS.md](AGENTS.md).

- [Coding-agent entry point](AGENTS.md) and [codec-specific implementation plan](IMPLEMENTATION.md).
- [Suite policy](Documentation/SUITE_POLICY.md) and [common API](Documentation/COMMON_API.md).
- [Memory ownership and no-copy hand-off](Documentation/MEMORY_CONTRACT.md).
- [Unit, regression and security testing](Documentation/TESTING.md).
- [Performance gates](Documentation/PERFORMANCE.md), [platforms](Documentation/PLATFORMS.md) and [CLI](Documentation/CLI_CONTRACT.md).
- [History and source provenance](HISTORY.md), [change log](CHANGELOG.md), [security](SECURITY.md), [contributing](CONTRIBUTING.md) and [MIT licence](LICENSE).

## Relationship to the suite

The four independent libraries are SwiftJ2K, SwiftJLS, SwiftJXL and SwiftJLI, all intended to live under Raster-Lab. A future optional umbrella adapts them for codec selection and in-process transcoding. The codecs do not depend on that umbrella. SwiftCompressionFamily is not part of this successor plan. The common contract is mirrored documentation plus behavioural tests, not a shared runtime package.

The package product and module are `SwiftJLS`; the diagnostic CLI `swiftjls` provides help/version/capabilities. [The independent consumer](Examples/IndependentConsumer/Sources/Consumer/main.swift) compiles and runs against only this package, exercising sample ownership and explicit codec rejection. Features from the predecessor are migration candidates whose exact coverage must be verified; see IMPLEMENTATION.md. Nothing here changes the predecessor repository's current maintenance configuration.

## Synthetic storage example

```swift
import SwiftJLS

let descriptor = try ImageDescriptor.greyscale16(
    width: 3, height: 2, meaningfulBits: 12, rowBytes: 8)
let image = try ImageDestination.allocate(descriptor: descriptor)
    .writeUInt16 { x, y in x == 2 ? 4095 : UInt16(x + y * 3) }
let sample = try image.sampleUInt16(x: 2, y: 1) // 4095
```

This initialises synthetic samples; it does not compress them. See the contract's scoped-pointer obligations before implementing custom storage adapters.

## Command-line help and manual

The diagnostic CLI now provides `-h` / `--help`, `help <command>`, version and truthful capability reporting. Codec commands remain unavailable. Verbosity has five levels: `-v`, `-vv`, `--verbose 1..5`, `--verbose=+++` and `-verbose: 3`; diagnostics use stderr and `--quiet` suppresses optional messages. See [CLI usage and installation](CLI.md). The installer updates both the executable and its UNIX man page together. [OS 27/CLI qualification](Documentation/Engineering/OS27CLI/README.md) supersedes the earlier OS 26 upgrade decision; earlier evidence remains historical.
