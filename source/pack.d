// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/smol


import helpers;
import file_type;
import compressor;

void packFile(string name, FileType file_type) {
	import std.file : rename, remove, rmdirRecurse, exists, tempDir;
	import std.string : format;

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
	string out_file = "%s%s".format(path_base, fileExtensionForType(file_type));

	// Extract to temp directory
	prints("%s%s", padding, name);
	chdir(path_dir);
	uncompress(path_base, temp_dir);

	packDir(temp_dir, false);

	// Compress to 7z
	//prints("%sCompressing: %s", padding, out_file);
	chdir(temp_dir);
	compress("*", out_file, FileType.SevenZip);

	rename(buildPath(temp_dir, out_file), buildPath(path_dir, out_file));
	chdir(original_dir);

	// Delete the temp directory
	if (exists(temp_dir)) {
		rmdirRecurse(temp_dir);
	}

	// Delete the original zip file
	if (exists(full_path)) {
		remove(full_path);
	}
}

void packDir(string path, bool is_root_dir) {
	import std.array : array, replace;
	import std.file : dirEntries, SpanMode, isDir, isFile, remove, exists;
	import std.string : format, startsWith;
	import std.algorithm : sort, map, filter, canFind;
	import natcmp : comparePathsNaturalSort;

	string padding = getScopePadding();

	if (is_root_dir) {
		padding = getScopePadding();
		prints("%sPacking files:", padding);
	}

	g_scope_depth++;
	scope (exit) g_scope_depth--;
	padding = getScopePadding();

	auto names = dirEntries(path, SpanMode.depth)
		.filter!(n => isFile(n))
		.map!(n => n.name)
		.map!(n => n.replace(`\`, `/`))
		.filter!(n => ! n.canFind(`/.`))
		.array()
		.sort!(comparePathsNaturalSort);

	foreach (string name; names) {
		auto file_type = getFileType(name);
		final switch (file_type) {
			case FileType.SevenZip:
				break;
			case FileType.Zip:
				packFile(name, file_type);
				break;
			case FileType.XZ:
				break;
			case FileType.GZip:
				packFile(name, file_type);
				break;
			case FileType.BZip2:
				packFile(name, file_type);
				break;
			case FileType.Binary:
				if (is_root_dir) {
					string prev_dir = getcwd().absolutePath();
					string dir_name = pathDirName(name);
					string file_name = pathBaseName(name);
					//prints("!!!!! dir_name: %s", dir_name);
					//prints("!!!!! file_name: %s", file_name);
					chdir(dir_name);
					compress(file_name, "%s%s".format(file_name, fileExtensionForType(FileType.Binary)), FileType.SevenZip);
					chdir(prev_dir);

					// Delete the original binary file
					if (exists(name)) {
						remove(name);
					}
				}
				break;
		}
	}
}
