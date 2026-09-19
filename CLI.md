# swiftjls: help, diagnostics and installation

Version **1.1.0-dev.2**; Swift 6.4 / Swift 6, Apple OS minimum **27.0**. The CLI targets macOS and Linux; Linux execution remains a qualification requirement. No external parser package or sibling codec is required. Current commands report help, version and the library's actual capabilities. Encode/decode/inspect/validate remain unavailable (exit 4), without opening input, consuming stdin or creating output. Their help describes reserved syntax only.

```sh
swift run swiftjls --help
swift run swiftjls -h
swift run swiftjls help capabilities
swift run swiftjls capabilities --help
swift run swiftjls --version
swift run swiftjls capabilities --json
swift run swiftjls capabilities -vv
swift run swiftjls capabilities -verbose: 3
swift run swiftjls capabilities --verbose=+++++
```

Both global and command-local help include availability, examples, option ranges/defaults, streams, errors and manual discovery. No arguments also show help. Use `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` with the qualified Xcode on macOS.

## Verbosity

| Level | Cumulative stderr diagnostics |
| --- | --- |
| 0 (default) | Errors only |
| 1 | Version/operation summary |
| 2 | Command stages |
| 3 | Capability/configuration details |
| 4 | Elapsed timing |
| 5 | Bounded execution trace |

`-v` increments, `-vv` through `-vvvvv` group increments, and `--verbose LEVEL`, `--verbose=LEVEL`, `-verbose: LEVEL` or `-verbose:LEVEL` set an explicit level. Digits 1..5 and `+`..`+++++` are equivalent. Bare `--verbose` / `-verbose` increment once. Options apply in order; exceeding 5 or supplying an invalid level returns 2. `--quiet` / `-q` conflicts with any positive verbosity. Errors still print in quiet mode. Help, version and capability output remain stdout data. Diagnostics never contaminate JSON or log payload bytes, metadata, raw addresses or input/output paths.

## Install or update the binary and UNIX manual

Run the installer from this source checkout. It builds the release executable and installs both the binary and matching manual every time; rerunning updates both. No administrator command runs automatically.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./Scripts/install-cli.sh --prefix "$HOME/.local"
"$HOME/.local/bin/swiftjls" --help
man -M "$HOME/.local/share/man" swiftjls
```

Default prefix is `/usr/local`; choose an absolute writable prefix. Add its `bin` directory to PATH. For ordinary `man swiftjls` lookup with a custom prefix, configure MANPATH to include `PREFIX/share/man` while retaining system defaults (for example `export MANPATH="$HOME/.local/share/man:${MANPATH:-}"`). Direct `man -M` needs no index refresh. The page is [ManPages/swiftjls.1](ManPages/swiftjls.1). A packaging recipe must install both `PREFIX/bin/swiftjls` (0755) and `PREFIX/share/man/man1/swiftjls.1` (0644).

`--destdir /absolute/staging` (or DESTDIR) stages those same prefix-relative locations for packaging. `--binary /absolute/built/swiftjls` avoids a rebuild and verifies `--version` against VERSION before writing. `--scratch-path` selects a build directory; `--disable-package-sandbox` is only an explicit workaround for nested sandbox restrictions. An existing destination symlink/directory is refused. Merely copying the executable does not install its manual.

## Exit codes and validation

Implemented exit statuses: 0 success/help/version, 2 invalid usage, 4 unavailable codec operation, 6 output failure including closed pipes. Reserved future codec codes: 3 malformed input, 5 resource/deadline, 7 internal failure, 130 user cancellation. No successful compression is inferred from a zero-exit capability query. Library errors cannot terminate the host application; exit handling exists only in this executable.

`Scripts/test-cli.py --binary /absolute/built/swiftjls --output /new/evidence/directory` checks the real executable, help, verbosity, JSON separation, invalid inputs, unavailable operations, closed pipes and staged manual install/update/rendering. [Qualification](Documentation/Engineering/OS27CLI/README.md) records exact executed commands and platform limits. Later codec milestones must add real stream/format/overwrite/cancellation tests before advertising those operations.
