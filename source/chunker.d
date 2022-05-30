// Copyright (c) 2021-2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recursively re compresses directories with lzma2 compression
// https://github.com/workhorsy/smol

import helpers;

void chunkDirFiles(string path) {
	import std.array : array, replace;
	import std.file : dirEntries, SpanMode, isFile, remove, exists, read, append;
	import std.string : format, endsWith;
	import std.stdio : File, toFile, chunks;
	import std.regex : matchFirst, ctRegex;
	import std.algorithm : canFind, filter, map, sort;
	import natcmp : comparePathsNaturalSort;

	string padding = getScopePadding();
	prints("%sBreaking files into chunks:", padding);

	g_scope_depth++;
	scope (exit) g_scope_depth--;
	padding = getScopePadding();

	// Get all the smol files in natural sorted order
	auto names = dirEntries(path, SpanMode.depth)
		.filter!(n => isFile(n))
		.map!(n => n.name)
		.map!(n => n.replace(`\`, `/`))
		.filter!(n => ! n.canFind(`/.`))
		.filter!(n => n.endsWith(".smol"))
		.array()
		.sort!(comparePathsNaturalSort);

	immutable size_t SIZE = 1024 * 1024 * 10; // 10 MB
	foreach (string name ; names) {
		prints("%s%s", padding, name);
		auto f = File(name, "rb");

		size_t i = 0;
		foreach (ubyte[] chunk; chunks(f, SIZE)) {
			//prints("????? i: %s", i);
			string chunk_name = "%s.%s".format(name, i);
			chunk.toFile(chunk_name);
			i++;
		}
		f.close();

		// Delete the original smol file
		if (exists(name)) {
			remove(name);
		}
	}
}

void unChunkDirFiles(string path) {
	import std.file : dirEntries, SpanMode, isFile, remove, exists, read, append;
	import std.regex : matchFirst, ctRegex;
	import std.algorithm : canFind, filter, map, sort;
	import std.array : array, replace;
	import natcmp : comparePathsNaturalSort;

	string padding = getScopePadding();
	prints("%sCombining file chunks:", padding);

	g_scope_depth++;
	scope (exit) g_scope_depth--;
	padding = getScopePadding();

	auto file_ext = ctRegex!(`\.smol\.(\d+)$`);

	// Get all the smol files in natural sorted order
	auto names = dirEntries(path, SpanMode.depth)
		.filter!(n => isFile(n))
		.map!(n => n.name)
		.map!(n => n.replace(`\`, `/`))
		.filter!(n => ! n.canFind(`/.`))
		.filter!(n => ! n.matchFirst(file_ext).empty)
		.array()
		.sort!(comparePathsNaturalSort);

	foreach (string name; names) {
		prints("%s%s", padding, name);

		string i = name.after(".smol.");
		string base_name = name[0 .. $ - i.length - 1];
		//prints("!!!! base_name:%s, i:%s", base_name, i);

		// Read the chunk file and append it to the original smol file
		void[] chunk = read(name);
		append(base_name, chunk);

		// Delete the original smol.# file
		if (exists(name)) {
			remove(name);
		}
	}
}
