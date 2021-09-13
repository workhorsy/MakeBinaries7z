// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/smol

import helpers;

// FIXME: Change to use std.stdio.chunks
void chunkDirFiles(string path) {
	import std.array : replace;
	import std.file : dirEntries, SpanMode, isDir, remove, exists;
	import std.string : format, endsWith;
	import std.stdio : File, toFile;

	char[] buffer = new char[1024 * 1024 * 10]; // 10 MB
	// Break large files into smaller chunks
	foreach (string name; dirEntries(path, SpanMode.depth)) {
		name = name.replace(`\`, `/`);
		if (isDir(name) || ! name.endsWith(".smol")) continue;

		// Read file in 10 MB chunks
		//prints("chunking name: %s", name);
		auto f = File(name, "r");
		int i = 0;
		char[] chunk;
		while ((chunk = f.rawRead(buffer)).length > 0) {
			string chunk_name = "%s.%s".format(name, i);
			//chunk = f.rawRead(buffer);
			toFile(chunk, chunk_name);
			//prints("!!!! chunk: %s", chunk.length);
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
	import std.array : replace;
	import std.file : dirEntries, SpanMode, isFile, remove, exists, read, append;
	import std.regex : matchFirst, ctRegex;
	import std.algorithm : filter, map, sort;
	import std.array : array;

	auto file_ext = ctRegex!(`\.smol\.(\d+)$`);

	// Get all the smol files in lexicographic order
	string[] names = dirEntries(path, SpanMode.depth)
		.filter!(n => isFile(n))
		.map!(n => n.name)
		.map!(n => n.replace(`\`, `/`))
		.filter!(n => ! n.matchFirst(file_ext).empty)
		.array()
		.sort!((a, b) => a < b)
		.array();

	foreach (string name; names) {
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
