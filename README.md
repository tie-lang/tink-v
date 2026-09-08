# tink-v

tink data-flow node frame protocol — V module (no dependencies).
Universal and language-agnostic: any component that obeys the frame protocol
can join a tink pipeline.

```
帧 = [ len: u32 BE ][ payload: len 字节 ][ crc: u32 BE ]
len = payload 字节数
crc = CRC32-IEEE(payload)（多项式 0xEDB88320）
```

Mirrors `std/tink.tie` (tie standard library) and the other-language tink
libraries; pure functions over `[]u8`, IO (stdin/stdout) left to the caller.
Names follow the V convention (`module tink`, snake_case functions).

## API (`module tink`)

| function | description |
| --- | --- |
| `tink.crc32(data []u8) u32` | CRC32-IEEE over a byte slice. Check vector: `crc32('123456789'.bytes()) == 0xCBF43926` |
| `tink.frame_encode(payload []u8) []u8` | encode a payload into a full frame `[len][payload][crc]` |
| `tink.frame_next(bytes []u8, pos int) ?Frame` | parse one frame at `pos`, verify CRC; `Frame(payload, next)` on success, `none` on out-of-bounds / CRC mismatch |
| `tink.frame_skip(bytes []u8, pos int) int` | skip one frame at `pos` without copying or verifying; `-1` on out-of-bounds |

## Usage

```v
import tink
frame := tink.frame_encode([u8(1), 2, 3])
got := tink.frame_next(frame, 0) or { return } // tink.Frame
```

## Test

```bash
v test .
```

## Cross-language

tink 帧协议各语言实现（API 语义与校验向量一致）：

| language | library |
| --- | --- |
| tie | `std/tink.tie` |
| Rust | `tink-rust`（tink crate） |
| C | `tink-c`（`tink.h` + `tink.c`） |
| Python | `tink-python`（`tink.py`） |
| JavaScript | `tink-js`（`tink.js` + `tink.d.ts`） |
| C++ | `tink-cpp`（`tink.hpp`） |
| Java | `tink-java`（`org.tielang.tink`） |
| C# | `tink-csharp`（namespace `Tink`） |
| Go | `tink-go`（package `tink`） |
| Zig | `tink-zig`（`tink.zig`） |
| Lua | `tink-lua`（`tink.lua`） |
| GDScript | `tink-godot`（`tink.gd`） |
| F# | `tink-fsharp`（`Tink.fs`） |
| PowerShell | `tink-powershell`（`tink.ps1`） |
| Kotlin | `tink-kotlin`（`Tink.kt`） |
| Ruby | `tink-ruby`（`tink.rb`） |
| Julia | `tink-julia`（`tink.jl`） |
| Nim | `tink-nim`（`tink.nim`） |
| Dart | `tink-dart`（`tink.dart`） |
| Crystal | `tink-crystal`（`tink.cr`） |
| PHP | `tink-php`（`tink.php`） |
| V | this module（`tink-v`） |

## License

本仓库使用 **Tie Public License v2.0 (TPL 2.0)**，完整文本见 [LICENSE](LICENSE)。
This repository is distributed under the **Tie Public License v2.0 (TPL 2.0)** — see [LICENSE](LICENSE) for the full text.