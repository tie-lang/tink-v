// tink.v —— tink data-flow node frame protocol (universal, language-agnostic).
//
// Frame = [len u32 BE][payload][crc u32 BE]; crc = CRC32-IEEE (0xEDB88320).
// Mirrors std/tink.tie (tie standard library) and the other-language tink
// libraries; pure functions over []u8, IO (stdin/stdout) left to the caller.
// V, no dependencies.

module tink

// crc32 returns the CRC32-IEEE checksum of a byte slice (bit-loop, no table).
// Check vector: crc32('123456789'.bytes()) == 0xCBF43926
pub fn crc32(data []u8) u32 {
	mut crc := u32(0xFFFFFFFF)
	for b in data {
		crc ^= u32(b)
		for _ in 0 .. 8 {
			if crc & 1 != 0 {
				crc = (crc >> 1) ^ u32(0xEDB88320)
			} else {
				crc = crc >> 1
			}
		}
	}
	return (crc ^ u32(0xFFFFFFFF)) & u32(0xFFFFFFFF)
}

// Frame is the result of parsing a frame: payload (copy) and pos after it.
pub struct Frame {
pub:
	payload []u8
	next    int
}

// frame_encode encodes a payload into [len u32 BE][payload][crc u32 BE].
pub fn frame_encode(payload []u8) []u8 {
	n := payload.len
	mut out := []u8{len: n + 8}
	out[0] = u8((n >> 24) & 0xFF)
	out[1] = u8((n >> 16) & 0xFF)
	out[2] = u8((n >> 8) & 0xFF)
	out[3] = u8(n & 0xFF)
	for i in 0 .. n {
		out[4 + i] = payload[i]
	}
	c := crc32(payload)
	out[n + 4] = u8((c >> 24) & 0xFF)
	out[n + 5] = u8((c >> 16) & 0xFF)
	out[n + 6] = u8((c >> 8) & 0xFF)
	out[n + 7] = u8(c & 0xFF)
	return out
}

// frame_next parses one frame at pos (verifies CRC). Returns Frame or none on
// out-of-bounds / CRC mismatch.
pub fn frame_next(bytes []u8, pos int) ?Frame {
	if pos < 0 || bytes.len < pos + 8 {
		return none
	}
	n := int(be32(bytes, pos))
	e := pos + 8 + n
	if bytes.len < e {
		return none
	}
	mut payload := []u8{len: n}
	for i in 0 .. n {
		payload[i] = bytes[pos + 4 + i]
	}
	want := be32(bytes, e - 4)
	if crc32(payload) != want {
		return none
	}
	return Frame{
		payload: payload
		next:    e
	}
}

// frame_skip skips one frame at pos without copying or verifying.
// Returns the position after the frame, or -1 on out-of-bounds.
pub fn frame_skip(bytes []u8, pos int) int {
	if pos < 0 || bytes.len < pos + 8 {
		return -1
	}
	n := int(be32(bytes, pos))
	e := pos + 8 + n
	if bytes.len < e {
		return -1
	}
	return e
}

fn be32(b []u8, off int) u32 {
	return (u32(b[off]) << 24) | (u32(b[off + 1]) << 16) | (u32(b[off + 2]) << 8) | u32(b[off + 3])
}