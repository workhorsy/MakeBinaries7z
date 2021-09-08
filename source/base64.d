// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/MakeBinaries7z



@nogc char[] stringToBase64(InputType, SinkType)(InputType input, ref SinkType sink) {
	size_t sink_index = 0;
	size_t j;
	ubyte data = 0;
	foreach (i ; 0 .. input.length * 8) {
		ubyte bit = getBit(input, i);
		data |= (bit << (5 - j));
		j++;
		if (j > 5) {
			sink[sink_index] = CODES[data];
			j = 0;
			data = 0;
			sink_index++;
		}
	}

	// Add trailing character that was less than 6 bits
	if (j > 0) {
		sink[sink_index] = CODES[data];
		sink_index++;
	}

	// Add trailing "=" until divisible by 4
	while (sink_index % 4 != 0) {
		sink[sink_index] = '=';
		sink_index++;
	}

	return sink[0 .. sink_index];
}

@nogc char[] base64ToString(InputType, SinkType)(InputType input, ref SinkType sink) {
	size_t j = 0;
	foreach (char n ; input) {
		if (n == '=') break;

		ubyte data = getIndexOfCode(n);
		foreach (i ; 0 .. 6) {
			int bit_index = 5 - i;
			ubyte mask = cast(ubyte) (0b0000_0001 << bit_index);
			ubyte bit_value = (data & mask) >> bit_index;
			setBit(sink, j, bit_value);
			j++;
		}
	}

	size_t sink_index = j / 8;
	return sink[0 .. sink_index];
}

immutable string CODES = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

// FIXME: Replace with std.algorithm
@nogc ubyte getIndexOfCode(char n) {
	foreach (i, code ; CODES) {
		if (code == n) {
			return cast(ubyte) i;
		}
	}
	return 0;
}

@nogc ubyte getBit(InputType)(InputType input, size_t bit_index) {
	size_t array_index = bit_index / 8;
	ubyte bit_offset = cast(ubyte) (bit_index % 8);

	switch (bit_offset) {
		case 0: return (input[array_index] & 0B1000_0000) >> 7;
		case 1: return (input[array_index] & 0B0100_0000) >> 6;
		case 2: return (input[array_index] & 0B0010_0000) >> 5;
		case 3: return (input[array_index] & 0B0001_0000) >> 4;
		case 4: return (input[array_index] & 0B0000_1000) >> 3;
		case 5: return (input[array_index] & 0B0000_0100) >> 2;
		case 6: return (input[array_index] & 0B0000_0010) >> 1;
		case 7: return (input[array_index] & 0B0000_0001) >> 0;
		default: return 0;
	}
}

@nogc void setBit(InputType)(ref InputType input, size_t bit_index, ubyte bit_value) {
	size_t array_index = bit_index / 8;
	ubyte bit_offset = cast(ubyte) (bit_index % 8);

	switch (bit_offset) {
		case 0: input[array_index] |= (bit_value << 7); break;
		case 1: input[array_index] |= (bit_value << 6); break;
		case 2: input[array_index] |= (bit_value << 5); break;
		case 3: input[array_index] |= (bit_value << 4); break;
		case 4: input[array_index] |= (bit_value << 3); break;
		case 5: input[array_index] |= (bit_value << 2); break;
		case 6: input[array_index] |= (bit_value << 1); break;
		case 7: input[array_index] |= (bit_value << 0); break;
		default: break;
	}
}

unittest {
	import BDD;

	describe("base64",
		it("Should convert to base64", delegate() {
			char[1024] buf = 0;
			char[] result;

			buf = 0;
			result = "a".stringToBase64(buf);
			result.shouldEqual("YQ==");

			buf = 0;
			result = "ab".stringToBase64(buf);
			result.shouldEqual("YWI=");

			buf = 0;
			result = "abc".stringToBase64(buf);
			result.shouldEqual("YWJj");

			buf = 0;
			result = "abcd".stringToBase64(buf);
			result.shouldEqual("YWJjZA==");

			buf = 0;
			result = `abc +&^ 123?/`.stringToBase64(buf);
			result.shouldEqual("YWJjICsmXiAxMjM/Lw==");
		}),
		it("Should convert from base64", delegate() {
			char[1024] buf = 0;
			char[] result;

			buf = 0;
			result = "YQ==".base64ToString(buf);
			result.shouldEqual("a");

			buf = 0;
			result = "YWI=".base64ToString(buf);
			result.shouldEqual("ab");

			buf = 0;
			result = "YWJj".base64ToString(buf);
			result.shouldEqual("abc");

			buf = 0;
			result = "YWJjZA==".base64ToString(buf);
			result.shouldEqual("abcd");

			buf = 0;
			result = "YWJjICsmXiAxMjM/Lw==".base64ToString(buf);
			result.shouldEqual(`abc +&^ 123?/`);
		}),
	);
}
