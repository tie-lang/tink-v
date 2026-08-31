// tink_test.v —— unit tests for tink.v. Run: v test .
module main

import tink

struct Checker {
mut:
	failures int
}

fn (mut c Checker) check(cond bool, name string) {
	if cond {
		println('[PASS] ${name}')
	} else {
		c.failures++
		println('[FAIL] ${name}')
	}
}

fn test_all() {
	mut c := Checker{}
	// crc32 check vector
	c.check(tink.crc32('123456789'.bytes()) == u32(0xCBF43926), 'crc32 vector')

	// frame roundtrip
	p := [u8(1), 2, 3]
	frame := tink.frame_encode(p)
	c.check(frame.len == p.len + 8, 'frame length')
	if got := tink.frame_next(frame, 0) {
		c.check(got.next == frame.len, 'frame next == length')
		c.check(got.payload == p, 'frame payload roundtrip')
	} else {
		c.check(false, 'frame present')
	}

	// empty frame roundtrip
	fe := tink.frame_encode([]u8{})
	if ge := tink.frame_next(fe, 0) {
		c.check(ge.next == fe.len && ge.payload.len == 0, 'empty frame roundtrip')
	} else {
		c.check(false, 'empty frame present')
	}

	// CRC tamper rejected
	mut ft := tink.frame_encode(p)
	ft[4] = ft[4] + 1 // tamper payload[0]
	mut tampered_ok := false
	if _ := tink.frame_next(ft, 0) {
		tampered_ok = true
	}
	c.check(!tampered_ok, 'crc tamper rejected')

	// frame_skip matches length
	fs := tink.frame_encode(p)
	c.check(tink.frame_skip(fs, 0) == fs.len, 'frame_skip matches length')

	// out of bounds
	mut failed := false
	if _ := tink.frame_next(frame, frame.len) {
		failed = true
	}
	c.check(!failed, 'frameNext out of bounds')
	c.check(tink.frame_skip(frame, frame.len) == -1, 'frame_skip out of bounds')
	mut failed2 := false
	if _ := tink.frame_next([]u8{}, 0) {
		failed2 = true
	}
	c.check(!failed2, 'frame_next empty input')
	c.check(tink.frame_skip([]u8{}, 0) == -1, 'frame_skip empty input')

	if c.failures > 0 {
		println('${c.failures} checks FAILED')
		assert false
	}
	println('all tests passed')
}