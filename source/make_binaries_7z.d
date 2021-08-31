// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/MakeBinaries7z


module make_binaries_7z;

int g_scope_depth = 0;
string compression_level = "-mx9";
string compression_multi_thread = "-mmt=on";

void prints(string message) {
	import std.stdio : stdout;
	stdout.writeln(message); stdout.flush();
}

void prints(alias fmt, A...)(A args)
if (isSomeString!(typeof(fmt))) {
	import std.format : checkFormatException;

	alias e = checkFormatException!(fmt, A);
	static assert(!e, e.msg);
	return prints(fmt, args);
}

void prints(Char, A...)(in Char[] fmt, A args) {
	import std.stdio : stdout;
	stdout.writefln(fmt, args); stdout.flush();
}

enum FileType {
	Zip,
	SevenZip,
	Binary,
}

FileType getFileType(string name) {
	import std.stdio : File;

	// Read first 10 bytes of file
	auto f = File(name, "r");
	char[10] header = 0;
	f.rawRead(header);

	// Return file type based on magic numbers
	if (header[0 .. 4] == [0x50, 0x4B, 0x03, 0x04]) {
		return FileType.Zip;
	} else if (header[0 .. 6] == [0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C]) {
		return FileType.SevenZip;
	} else {
		return FileType.Binary;
	}
}

string getScopePadding() {
	import std.range : repeat, take;
	import std.array : array, join;
	return "    ".repeat.take(g_scope_depth).array.join("");
}

void recompressFile(string name) {
	import std.file : remove, rmdirRecurse, exists;
	import std.string : format;

	g_scope_depth++;
	scope (exit) g_scope_depth--;
	string padding = getScopePadding();

	string temp_dir = "%s.xxx".format(name);
	string out_file = "%s.7z".format(name);

	// Delete the out file
	if (exists(out_file)) {
		remove(out_file);
	}

	// Delete the temp directory
	if (exists(temp_dir)) {
		rmdirRecurse(temp_dir);
	}

	// Extract to temp directory
	prints("%sUncompressing: %s", padding, name);
	uncompress(name, temp_dir);

	recompressDir(temp_dir, false);

	// Compress to 7z
	//prints("out_file: %s", out_file);
	//prints("file_name: %s", file_name);
	prints("%sCompressing: %s", padding, out_file);
	compress(temp_dir, out_file, FileType.SevenZip);

	// Delete the temp directory
	if (exists(temp_dir)) {
		rmdirRecurse(temp_dir);
	}

	// Delete the original zip file
	if (exists(name)) {
		remove(name);
	}
}

void unRecompressFile(string name) {
	import std.file : remove, rmdirRecurse, exists;
	import std.string : format;

	g_scope_depth++;
	scope (exit) g_scope_depth--;
	string padding = getScopePadding();

	string extracted_dir = "%s.xxx".format(name);
	string to_file = name[0 .. $-3];
	string from_file = name;

	// Delete the out file
	if (exists(to_file)) {
		remove(to_file);
	}

	// Delete the temp directory
	if (exists(extracted_dir)) {
		rmdirRecurse(extracted_dir);
	}

	// Extract to temp directory
	prints("%sUncompressing: %s", padding, name);
	uncompress(name, extracted_dir);

	unRecompressDir(extracted_dir, false);

	// Compress to 7z
	//prints("to_file: %s", to_file);
	//prints("file_name: %s", file_name);
	prints("%sCompressing: %s", padding, to_file);
	compress(extracted_dir, to_file, FileType.Zip);

	// Delete the temp directory
	if (exists(extracted_dir)) {
		rmdirRecurse(extracted_dir);
	}

	// Delete the original zip file
	if (exists(name)) {
		remove(name);
	}
}

void recompressDir(string path, bool is_root_dir) {
	import std.array : replace;
	import std.file : dirEntries, SpanMode, isDir, remove, rmdirRecurse, exists;
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
				recompressFile(name);
				break;
			case FileType.Binary:
				if (is_root_dir) {
					compress(name, "%s.7z".format(name), FileType.SevenZip);

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
	import std.file : dirEntries, SpanMode, isDir, remove, rmdirRecurse, exists;
	import std.string : format;
	import std.algorithm.searching : endsWith;

	g_scope_depth++;
	scope (exit) g_scope_depth--;
	string padding = getScopePadding();

	foreach (string name; dirEntries(path, SpanMode.depth)) {
		name = name.replace(`\`, `/`);
		//prints("%sScanning: %s", padding, name);

		if (isDir(name) || ! name.endsWith(".7z")) continue;

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

void compress(string in_name, string out_name, FileType file_type) {
	import std.process : execute;
	import std.stdio : stderr;
	import std.array : array, join;
	import std.string : format;
	import std.file : isDir;

	string compression_type;
	final switch (file_type) {
		case FileType.Zip:
			compression_type = "-tZip";
			break;
		case FileType.SevenZip:
			compression_type = "-t7z";
			break;
		case FileType.Binary:
			compression_type = "";
			break;
	}

	// If compressing a directory, use the files in the directory
	if (isDir(in_name)) {
		in_name = "%s/*".format(in_name);
	}

	//prints("%sCompressing: %s", padding, out_name);
	string[] command = ["7z", compression_type, compression_level, compression_multi_thread, "a", out_name, in_name];
	//prints("Running command: %s", command.join(" "));
	auto exe = execute(command);
	if (exe.status != 0) {
		stderr.writefln("%s", exe.output); stderr.flush();
	}
	assert(exe.status == 0);
}

void uncompress(string in_name, string out_name) {
	import std.process : execute;
	import std.string : format;
	import std.stdio : stderr;
	import std.array : array, join;

	string[] command = ["7z", "x", in_name, "-o%s".format(out_name)];
	//prints("Running command: %s", command.join(" "));
	auto exe = execute(command);
	if (exe.status != 0) {
		stderr.writefln("%s", exe.output); stderr.flush();
	}
	assert(exe.status == 0);
}
