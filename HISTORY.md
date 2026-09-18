# History and provenance — SwiftJLS

## Documentation foundation — 17 September 2026

The owner chose four fresh repositories under Raster-Lab, with independent codecs, a common API and memory contract, MIT licensing and an optional adapter-based umbrella. The previous proposal for a new shared-foundation package, SwiftCompressionFamily 2.0.0, was superseded. The intended first stable release here is 1.0.0; no library version has been released or tagged by this foundation.

| Item | Recorded source |
| --- | --- |
| Predecessor | [Raster-Lab/JLSwift](https://github.com/Raster-Lab/JLSwift) |
| Default branch observed | main |
| Inspected source snapshot | [299b9a2e5bfe36ef104a3464a27d6c4c82874cc2](https://github.com/Raster-Lab/JLSwift/commit/299b9a2e5bfe36ef104a3464a27d6c4c82874cc2) |
| Highest stable-shaped tag observed | [v0.9.1](https://github.com/Raster-Lab/JLSwift/tree/v0.9.1) |
| Source-tree licence observed | Apache-2.0 |
| Successor licence | MIT, for owner-authorised in-house material |
| Inspection date | 2026-09-17 |

The tag and the inspected branch snapshot are separate references; this record does not assert they resolve to the same commit. Before migrating a tagged baseline, resolve annotated tags to commits and record the exact chosen SHA. The pinned snapshot above was read for documentation preparation; it was not independently built or regression-tested in this task.

## Migration provenance requirements

The coding agent must record source repository, commit, original path and successor path for each migrated subsystem, and distinguish copied/adapted in-house material from new implementation. Record retained tests, fixture licences and explicit product/feature dispositions. Keep predecessor bug history accessible through links. Do not import old tags, rewrite predecessor history or imply all historical commits have been relicensed.

The owner states the implementation is in-house and has authorised MIT relicensing. Preserve accurate original copyright years and ownership. Audit any third-party dependencies, tools or fixtures separately. The MIT root licence is not authority to remove another party's notices.

The originals are intended to become maintenance projects while new development moves here. No predecessor settings, README, branch, release, licence or archive flag was changed during this documentation preparation. Maintenance announcements and downstream DICOMKit/Voxelia migration are separate work.

## Swift 6.4 development upgrade — 19 September 2026

The owner assigned the successor upgrade before Milestone 2 and requested version increments. Starting from `d85332fd7a7ce67ae27f9806f3e4b3c09dd3bd9f`, the candidate requires Swift tools 6.4 in Swift 6 language mode, advances shared contract 0.2.1 to 0.3.0 and advances the unreleased 1.0.0 target to 1.1.0 (`1.1.0-dev.1` development identifier). Platform floors, public API signatures, licensing and codec milestone scope are preserved. This is not a release/tag. The [upgrade record](Documentation/Engineering/Swift64/README.md) keeps current evidence separate from the earlier historical reports.
