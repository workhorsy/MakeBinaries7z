// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/smol


import helpers;
import file_type;
import smol;
import compressor;

void unpackFile(string name) {
	import std.file : remove, rmdirRecurse, exists;
	import std.string : format, stripRight, endsWith;
	import std.traits : EnumMembers;
	import std.file : rename, tempDir;

	g_scope_depth++;
	scope (exit) g_scope_depth--;
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
	prints("!!!!!! temp_dir: %s", temp_dir);
	//prints("!!!!!! path_base: %s", path_base);

	// Get the original file name and type based on the .blah.smol
	string out_file = "";
	FileType file_type;
	foreach (n ; EnumMembers!FileType) {
		string extension = fileExtensionForType(n);
		if (path_base.endsWith(extension)) {
			prints("!!!!! extension: %s", extension);
			out_file = path_base[0 .. $ - extension.length];
			prints("!!!!! out_file: %s", out_file);
			file_type = n;
			break;
		}
	}
	prints("!!!!! full_path: %s", full_path);
	prints("!!!!! out_file: %s", out_file);

//	prints("!!!!! path_base: %s", path_base);
//	prints("!!!!! file_type: %s", fileExtensionForType(file_type));

	// Extract to temp directory
	prints("%sUncompressing: %s", padding, path_base);
	chdir(path_dir);
	uncompress(path_base, temp_dir);

	unpackDir(temp_dir, false);

	final switch (file_type) {
		case FileType.SevenZip:
		case FileType.Zip:
			// Compress to original type
			prints("%sCompressing: %s", padding, out_file);
			chdir(temp_dir);
			compress("*", out_file, file_type);

			rename(buildPath(temp_dir, out_file), buildPath(path_dir, out_file));
			prints("???? rename from:%s, to:%s", buildPath(temp_dir, out_file), buildPath(path_dir, out_file));
			break;
		case FileType.Binary:
			// Rename to original file name
			rename(buildPath(temp_dir, out_file), buildPath(path_dir, out_file));
			prints("???? rename from:%s, to:%s", buildPath(temp_dir, out_file), buildPath(path_dir, out_file));
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
	import std.array : replace;
	import std.file : dirEntries, SpanMode, isDir;
	import std.algorithm.searching : endsWith;

	g_scope_depth++;
	scope (exit) g_scope_depth--;
	string padding = getScopePadding();

	foreach (string name; dirEntries(path, SpanMode.depth)) {
		name = name.replace(`\`, `/`);
		//prints("%sScanning: %s", padding, name.absolutePath());

		if (isDir(name) || ! name.endsWith(".smol")) continue;

		auto file_type = getFileType(name);
		final switch (file_type) {
			case FileType.SevenZip:
				unpackFile(name);
				break;
			case FileType.Zip:
				break;
			case FileType.Binary:
				break;
		}
	}
}
