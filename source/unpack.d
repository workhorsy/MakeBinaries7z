// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recursively re compresses directories with lzma2 compression
// https://github.com/workhorsy/smol


import helpers;
import file_type;
import compressor;

void unpackFile(string name) {
	import std.file : remove, rmdirRecurse, exists;
	import std.string : format, stripRight, endsWith;
	import std.traits : EnumMembers;
	import std.file : rename, tempDir;

	string padding = getScopePadding();
/*
	// Delete the out file
	if (exists(out_file)) {
		remove(out_file);
	}

	// Delete the temp directory
	if (exists(temp_dir)) {
		rmdirRecurse(temp_dir);
	}
*/
	string original_dir = getcwd().absolutePath();
	string full_path = absolutePath(name);
	string path_dir = pathDirName(full_path);
	string path_base = pathBaseName(full_path);
	string temp_dir = getRandomTempDirectory();//"%s.xxx".format(path_base);
	//prints("!!!!!! temp_dir: %s", temp_dir);
	//prints("!!!!!! path_base: %s", path_base);

	// Get the original file name and type based on the .blah.smol
	string out_file = "";
	FileType file_type;
	foreach (n ; EnumMembers!FileType) {
		string extension = fileExtensionForType(n);
		if (path_base.endsWith(extension)) {
			//prints("!!!!! extension: %s", extension);
			out_file = path_base[0 .. $ - extension.length];
			//prints("!!!!! out_file: %s", out_file);
			file_type = n;
			break;
		}
	}
	//prints("!!!!! full_path: %s", full_path);
	//prints("!!!!! out_file: %s", out_file);

//	prints("!!!!! path_base: %s", path_base);
//	prints("!!!!! file_type: %s", fileExtensionForType(file_type));

	// Extract to temp directory
	prints("%s%s", padding, stripTempDirectory(name));
	chdir(path_dir);
	uncompress(path_base, temp_dir);

	unpackDir(temp_dir, false);

	final switch (file_type) {
		case FileType.SevenZip:
		case FileType.Zip:
			// Compress to original type
			//prints("%sCompressing: %s", padding, out_file);
			chdir(temp_dir);
			compress("*", out_file, file_type);

			rename(buildPath(temp_dir, out_file), buildPath(path_dir, out_file));
			//prints("???? rename from:%s, to:%s", buildPath(temp_dir, out_file), buildPath(path_dir, out_file));
			break;
		case FileType.XZ:
			break;
		case FileType.GZip:
			// Compress to original type
			//prints("%sCompressing: %s", padding, out_file);
			chdir(temp_dir);
			compress("*", out_file, file_type);

			rename(buildPath(temp_dir, out_file), buildPath(path_dir, out_file));
			//prints("???? rename from:%s, to:%s", buildPath(temp_dir, out_file), buildPath(path_dir, out_file));
			break;
		case FileType.BZip2:
			// Compress to original type
			//prints("%sCompressing: %s", padding, out_file);
			chdir(temp_dir);
			compress("*", out_file, file_type);

			rename(buildPath(temp_dir, out_file), buildPath(path_dir, out_file));
			//prints("???? rename from:%s, to:%s", buildPath(temp_dir, out_file), buildPath(path_dir, out_file));
			break;
		case FileType.Binary:
			// Rename to original file name
			rename(buildPath(temp_dir, out_file), buildPath(path_dir, out_file));
			//prints("???? rename from:%s, to:%s", buildPath(temp_dir, out_file), buildPath(path_dir, out_file));
			break;
	}

	chdir(original_dir);

	// Delete the temp directory
	if (exists(temp_dir)) {
		rmdirRecurse(temp_dir);
	}

	// Delete the original .blah.smol file
	if (exists(full_path)) {
		remove(full_path);
	}
}



void unpackDir(string path, bool is_root_dir) {
	import std.array : array, replace;
	import std.file : dirEntries, SpanMode, isFile, isDir;
	import std.algorithm : sort, map, filter, endsWith, canFind;
	import natcmp : comparePathsNaturalSort;

	string padding = getScopePadding();

	if (is_root_dir) {
		padding = getScopePadding();
		prints("%sUnpacking files:", padding);
	}

	g_scope_depth++;
	scope (exit) g_scope_depth--;
	padding = getScopePadding();

	auto names = dirEntries(path, SpanMode.depth)
		.filter!(n => isFile(n))
		.map!(n => n.name)
		.map!(n => n.replace(`\`, `/`))
		.filter!(n => ! n.canFind(`/.`))
		.filter!(n => n.endsWith(".smol"))
		.array()
		.sort!(comparePathsNaturalSort);

	foreach (string name; names) {
		//prints("%sScanning: %s", padding, name.absolutePath());

		auto file_type = getFileType(name);
		final switch (file_type) {
			case FileType.SevenZip:
				unpackFile(name);
				break;
			case FileType.Zip:
				break;
			case FileType.XZ:
				break;
			case FileType.GZip:
				break;
			case FileType.BZip2:
				break;
			case FileType.Binary:
				break;
		}
	}
}
