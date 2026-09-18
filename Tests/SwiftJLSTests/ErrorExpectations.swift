// SPDX-License-Identifier: MIT
import Testing
import SwiftJLS

func expectCodecError<R>(
    _ category: CodecError.Category,
    sourceLocation: SourceLocation = #_sourceLocation,
    _ body: () throws -> R
) {
    do {
        _ = try body()
        Issue.record("Expected a defined codec error", sourceLocation: sourceLocation)
    } catch let error as CodecError {
        #expect(error.category == category, sourceLocation: sourceLocation)
    } catch {
        Issue.record("Unexpected error type: \(type(of: error))", sourceLocation: sourceLocation)
    }
}

func expectAsyncCodecError<R>(
    _ category: CodecError.Category,
    sourceLocation: SourceLocation = #_sourceLocation,
    _ body: () async throws -> R
) async {
    do {
        _ = try await body()
        Issue.record("Expected a defined codec error", sourceLocation: sourceLocation)
    } catch let error as CodecError {
        #expect(error.category == category, sourceLocation: sourceLocation)
    } catch {
        Issue.record("Unexpected error type: \(type(of: error))", sourceLocation: sourceLocation)
    }
}
