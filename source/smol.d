// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/smol


module smol;

import helpers;
import file_type;
import compressor;

int g_scope_depth = 0;


string fileExtensionForType(FileType file_type) {
	final switch (file_type) {
		case FileType.SevenZip:
			return ".7z.smol";
		case FileType.Zip:
			return ".zip.smol";
		case FileType.Binary:
			return ".bin.smol";
	}
}

string getScopePadding() {
	import std.range : repeat, take;
	import std.array : array, join;
	return "    ".repeat.take(g_scope_depth).array.join("");
}

string getRandomTempDirectory() {
	import std.random : MinstdRand0, uniform;
	import std.range : iota;
	import std.array : array, join, replace;
	import std.conv : to;
	import std.file : tempDir;
	import std.algorithm : map, filter;

	immutable string data = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

	string name = iota(0, 10)
		.map!(n => uniform(0, data.length, g_rand))
		.map!(n => data[n].to!string)
		.array()
		.join("")
		.replace(`\`, `/`);

	return buildPath(tempDir(), name) ~ `/`;
}
