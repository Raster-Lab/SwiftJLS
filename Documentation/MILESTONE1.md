# Milestone 1 — API and ownership feasibility

**Final validation after review:** 26 Swift Testing tests passed in each of debug, release, AddressSanitizer and ThreadSanitizer; every command and the independent consumer exited 0. The final source hashes, complete command lines, logs and XML are in [Validation/final](Validation/final). Earlier tables below record the preceding implementation snapshot; this final evidence supersedes their test counts and source fingerprints.


This milestone implements the standalone SwiftJLS package and synthetic image-memory contract. It **does not encode, inspect or decode JPEG-LS**. Public codec call shapes compile, return empty capabilities and fail explicitly with `unsupportedFeature`; they never return synthetic bytes labelled as a compressed format. Codec migration is a separately assigned Milestone 2 task.

## Source and contract

- Starting successor revision: `3cea15e236ea53b32562ce9edc381ecf9b40a2dc`; feature branch `codex/milestone-1-contract`.
- Predecessor inspected: Raster-Lab/JLSwift `299b9a2e5bfe36ef104a3464a27d6c4c82874cc2`.
- Contract: **0.2.1**, coordinated across all four repositories; see `COMMON_CONTRACT_SHA256.txt`. It fixes the concrete lease signatures and final-image ownership transition; it does not expand codec scope.
- All six files under `Sources/SwiftJLS`, package/consumer files and tests are new MIT implementation. No predecessor source, fixture or third-party codec was copied. Identical local core sources are independently compiled by each suite module, without a shared runtime dependency.

The pinned predecessor manifest exposes the `JPEGLS` library and `jpegls` CLI with a package-level ArgumentParser dependency. `Sources/JPEGLS/Encoder/JPEGLSPixelBuffer.swift` stores `MultiComponentImageData.ComponentData.pixels` as `[[Int]]`; its corresponding pixel-buffer tests and codec regressions remain migration candidates. No equivalent owning-storage/lease API exists there. No predecessor codec regression or benchmark is claimed as run for this synthetic-only milestone. Library algorithms, CLI, restart/interleave/mapping-table/colour transforms and predecessor tests are deferred, not silently removed.

## Implemented behaviour

`ImageDescriptor` validates dimensions, explicit sample meaning, low-aligned precision, byte order, component mapping, positive aligned strides, row payload, capacity, disjoint plane ranges and checked arithmetic. The first safe sample helpers preserve full unsigned 16-bit and 12-in-16 greyscale samples, including odd dimensions and padded rows. Descriptors can express additional integer/float layouts, but descriptor validity is not codec capability. Subsampled planes are explicitly rejected during this milestone.

`OwnedImageStorage` allocates one zero-filled byte array inside `Synchronization.Mutex`. Its shared lifecycle rejects duplicate reservations, stale/forged tokens and concurrent/reentrant mutation. `ImageDestination` reserves immediately, aborts on abandonment/fill failure/cancellation, and accepts only one fill. `finishAndSeal` transfers the byte array's reference into an immutable read-only owner and clears the writable reference; no pixel conversion is performed. Multiple sealed readers may borrow concurrently. There are no stored raw pointers, `@unchecked Sendable` annotations, global concurrency suppressions or external package dependencies.

The public advanced storage signatures are the contract's `reserveWrite()`, `withUnsafeMutableBytes(lease:_:)`, `finishAndSeal(lease:)` and `abortAndInvalidate(lease:)`. `StorageWriteLease` is an opaque fresh UUID-backed Sendable/Hashable value. Adapter providers must forward allocation identity and enforce the shared lifecycle themselves; copied tokens do not authorise overlapping borrows. Unsafe closure APIs expressly prohibit pointer escape, concurrent use and spans across `await`.

`Image(..., metadata:, limits:)` and `ImageDestination(..., limits:)` retain explicit caller limits. Geometry, capacity, ICC/metadata and aggregate admission checks precede access/allocation. `writeUInt16` validates every generated value and checks cancellation by row; final publication checks cancellation again. The raw synchronous fill callback owns its own bounded work/cancellation policy. The future codec async surface uses Swift 6.2 `@concurrent`; no codec execution, progress or timing is fabricated.

## Validation environment and commands

Local native host: macOS 27.0 (26A428), arm64; Xcode 27.0 (27A266a), Apple Swift 6.4 (`swiftlang-6.4.0.34.1`), SDK macOS 27.0. Package minimum remains Swift 6.2, Swift 6 language mode, and Apple deployment minima 26.0. The installed Swift 6.4 run does **not** qualify the separate Swift 6.2 minimum-toolchain gate.

Commands run from this repository use `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`; no global Xcode selection was changed. `CLANG_MODULE_CACHE_PATH=work/clang-cache` keeps caches within the workspace. `--disable-sandbox` disables SwiftPM's nested manifest sandbox, not Swift language or concurrency checks.

All final commands returned exit **0** unless noted. Debug, release, AddressSanitizer and ThreadSanitizer each executed **25 tests, zero failures/errors/skips**. The `exactSamplesAndZeroedPadding` test includes both 12- and 16-bit cases. [Machine-readable results](Validation/results.json), [source checksums](Validation/SOURCE_SHA256.txt), and [deterministic fixture provenance/digests](Validation/synthetic-fixtures.json) are retained alongside the four XML test reports. Full local logs remain under ignored `work/evidence/`.

```sh
# Common per-command environment:
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
export CLANG_MODULE_CACHE_PATH=work/clang-cache

xcrun swift build --build-system native --disable-sandbox --jobs 2 --cache-path work/swift-cache --scratch-path work/native-debug -c debug
xcrun swift build --build-system native --disable-sandbox --jobs 2 --cache-path work/swift-cache --scratch-path work/native-release -c release
xcrun swift test --build-system native --disable-sandbox --jobs 2 --cache-path work/swift-cache --scratch-path work/native-debug --xunit-output work/evidence/native-debug.xml
xcrun swift test --build-system native --disable-sandbox --jobs 2 --cache-path work/swift-cache --scratch-path work/native-release -c release --xunit-output work/evidence/native-release.xml
xcrun swift test --build-system native --disable-sandbox --jobs 2 --cache-path work/swift-cache --scratch-path work/native-asan --sanitize address --xunit-output work/evidence/native-asan.xml
xcrun swift test --build-system native --disable-sandbox --jobs 2 --cache-path work/swift-cache --scratch-path work/native-tsan --sanitize thread --xunit-output work/evidence/native-tsan.xml
xcrun swift run --disable-sandbox --jobs 2 --cache-path work/swift-cache --package-path Examples/IndependentConsumer Consumer
```

The independent consumer ran successfully and preserved allocation identity and 12-bit values while checking explicit codec rejection. These commands invoke the compiler installed inside Xcode headlessly. Initial `xcodebuild -list -json` returned **66** because it did not recognise the source-only Swift package as an Xcode project/workspace/package. Initial default Swift Build backend release testing returned **1** at sandbox-denied dSYM generation, after compilation. The native SwiftPM backend recovered and passed all final checks without weakening Swift/concurrency/sanitizer checks. The native backend is deprecated in Swift 6.4, which is a tooling limitation to revisit; the default backend also passed debug and AddressSanitizer tests and release with `-debug-info-format none` before the final additional cancellation test.

User-cache sandbox warnings did not prevent the explicit workspace-cache runs. No simulator permission or global system setting was changed. `git diff --check` and `shasum -a 256 -c COMMON_CONTRACT_SHA256.txt` from `Documentation/` both returned **0**.

## Evidence and limitations

Fixtures are deterministic values constructed in MIT-licensed tests: zero/max, 12-bit 4095 and 16-bit 65535, coordinate-derived values, explicit endian words, odd dimensions and zeroed padding. No external or clinical data is used. `DescriptorTests` exhausts 88 offset/row-stride combinations for a fixed 3x2 image and covers exact/short capacities, plane overlap and overflow rejection.

`OwnershipTests` observes adapter identity and reads/writes, 16 competing writer reservations, overlapping copies of a token, reentrant lease calls, nested/concurrent sealed reads, early caller release and exactly one **adapter** destruction. `APITests` proves precision and padding values, real task cancellation before publication, caller budget boundaries and truthful unsupported codec operations. These tests plus source inspection prove the tested synthetic hand-off; they do not measure codec workspace, throughput or general heap allocation traffic. No codec performance claim is made.

Unexecuted/deferred gates: JPEG-LS encoder/decoder interoperability, pinned codec regressions, real shared-storage transcodes, CLI, acceleration, process/file-I/O tracing, coverage-guided parser fuzzing, controlled codec release benchmarks, exact Swift 6.2 compilation, Linux, Intel macOS and Apple device/simulator runtime qualification. There is no codec parser in this milestone, so no parser fuzz/oracle test is represented by the descriptor mutation checks. No stable version is tagged.

## Additional Apple SDK compilation

Nine source-module builds passed using Xcode 27 Swift 6.4, explicit Swift 6 language mode and complete concurrency checking: macOS x86_64; iOS/tvOS/visionOS arm64 device and simulator; watchOS arm64_32 device and arm64 simulator. All target deployment versions were 26.0 using installed SDK 27.0. This is module compilation only, not linking, simulator execution or native-device qualification. Exact commands, exit codes and source hashes are in [apple-sdk-compilation.json](Validation/apple-sdk-compilation.json). The complete four-module matrix passed 36 of 36 compiler checks with no diagnostics.

## Final publication-cancellation correction

Independent review found that cancellation inside an external provider's sealing or validation callback could occur after the last cancellation check. The write now constructs its owning image, checks task cancellation immediately before returning, and publishes only on success. A deterministic parameterised regression cancels during `finishAndSeal` and during the returned read-owner validation borrow. Both cases throw `CancellationError` and permanently prevent destination reuse. If the provider has already sealed, its private read owner is discarded without publishing an Image; cleanup cannot reopen that sealed allocation. No workers or pointers outlive the operation.

All final test runs explicitly select Swift Testing with `--disable-xctest`: these packages contain no XCTest cases. The first final-validation attempt executed every Swift Testing case successfully but exited 1 because Xcode 27's empty XCTest compatibility bundle could not be loaded from the separate scratch directory. That failed runner log is retained; the corrected invocation runs all actual tests and returns 0. This is runner selection, not a test skip or suppression of a failing test. All nine Apple SDK module checks were repeated after the source fix and passed.
