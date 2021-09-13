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

void recompressFile(string name, FileType file_type) {
	import std.file : remove, rmdirRecurse, exists;
	import std.string : format;

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
	string full_path = absolutePath(name);
	string path = pathDirName(full_path);
	string file_name = pathBaseName(full_path);
	string temp_dir = "%s.xxx".format(file_name);
	string out_file = "%s%s".format(file_name, fileExtensionForType(file_type));
	string prev_dir = getcwd().absolutePath();

	// Extract to temp directory
	prints("%sUncompressing: %s", padding, file_name);
	chdir(path);
	uncompress(file_name, temp_dir);

	recompressDir(temp_dir, false);

	// Compress to 7z
	prints("%sCompressing: %s", padding, out_file);
	chdir(temp_dir);
	compress("*", "../%s".format(out_file), FileType.SevenZip);
	chdir("..");

	// FIXME: This needs to wait for the files to be unlocked?
	import core.thread.osthread : Thread;
	import core.time : dur;
	Thread.sleep(dur!("seconds")(3));

	// Delete the temp directory
	if (exists(temp_dir)) {
		rmdirRecurse(temp_dir);
	}

	// Delete the original zip file
	if (exists(file_name)) {
		remove(file_name);
	}

	chdir(prev_dir);
}

void unRecompressFile(string name) {
	import std.file : remove, rmdirRecurse, exists;
	import std.string : format, stripRight, endsWith;
	import std.traits : EnumMembers;
	import std.file : rename;

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
	string prev_dir = getcwd().absolutePath();
	string full_path = absolutePath(name);
	string path = pathDirName(full_path);
	string file_name = pathBaseName(full_path);
	string temp_dir = "%s.xxx".format(file_name);

	// Get the original file name and type based on the .blah.smol
	string out_file = "";
	FileType file_type;
	foreach (n ; EnumMembers!FileType) {
		string extension = fileExtensionForType(n);
		if (file_name.endsWith(extension)) {
			out_file = "%s".format(file_name.stripRight(extension));
			file_type = n;
			break;
		}
	}

//	prints("!!!!! file_name: %s", file_name);
//	prints("!!!!! file_type: %s", fileExtensionForType(file_type));

	// Extract to temp directory
	prints("%sUncompressing: %s", padding, file_name);
	chdir(path);
	uncompress(file_name, temp_dir);

	unRecompressDir(temp_dir, false);

	final switch (file_type) {
		case FileType.SevenZip:
		case FileType.Zip:
			// Compress to original type
			prints("%sCompressing: %s", padding, out_file);
			chdir(temp_dir);
			compress("*", "../%s".format(out_file), file_type);
			chdir("..");
			break;
		case FileType.Binary:
			// Rename to original file name
			rename("%s/%s".format(temp_dir, out_file), out_file);
			break;
	}

	// Delete the temp directory
	if (exists(temp_dir)) {
		rmdirRecurse(temp_dir);
	}

	// Delete the original .blah.smol file
	if (exists(file_name)) {
		remove(file_name);
	}

	chdir(prev_dir);
}

void recompressDir(string path, bool is_root_dir) {
	import std.array : replace;
	import std.file : dirEntries, SpanMode, isDir, remove, exists;
	import std.string : format;

	g_scope_depth++;
	scope (exit) g_scope_depth--;
	string padding = getScopePadding();

	foreach (string name; dirEntries(path, SpanMode.depth)) {
		name = name.replace(`\`, `/`);
		//prints("%sScanning: %s", padding, name);

		if (isDir(name)) continue;

		auto file_type = getFileType(name);
		final switch (file_type) {
			case FileType.SevenZip:
				break;
			case FileType.Zip:
				recompressFile(name, file_type);
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

void unRecompressDir(string path, bool is_root_dir) {
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
				unRecompressFile(name);
				break;
			case FileType.Zip:
				break;
			case FileType.Binary:
				break;
		}
	}
}
