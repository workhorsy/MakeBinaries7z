
import std.array : replace;
import std.file : remove, rmdirRecurse, exists, chdir, dirEntries, SpanMode, isDir;
import std.process : execute;
import std.stdio : stdout, stderr;
import std.string : format;

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
	import std.range : repeat, take, chain;
	import std.array : array, join;
	import std.conv : to;
	return "    ".repeat.take(g_scope_depth).array.join("");
}

void recompressFile(string name) {
	g_scope_depth++;
	scope (exit) g_scope_depth--;
	string padding = getScopePadding();

	string temp_dir = "%s.extracted".format(name);
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
	auto unzip = execute(["7z", "x", name, "-o%s".format(temp_dir)]);
	if (unzip.status != 0) {
		stderr.writefln("%s", unzip.output); stderr.flush();
	}
	assert(unzip.status == 0);

	recompressDir(temp_dir, false);

	// Compress to 7z
	//prints("out_file: %s", out_file);
	//prints("file_name: %s", file_name);
	prints("%sCompressing: %s", padding, out_file);
	auto zip = execute(["7z", "-t7z", compression_level, compression_multi_thread, "a", out_file, "%s.extracted".format(name)]);
	if (zip.status != 0) {
		stderr.writefln("%s", zip.output); stderr.flush();
	}
	assert(zip.status == 0);

	// Delete the temp directory
	if (exists(temp_dir)) {
		rmdirRecurse(temp_dir);
	}

	// Delete the original zip file
	if (exists(name)) {
		remove(name);
	}
}

void recompressDir(string path, bool is_root_dir) {
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
					//compress(name);
				}
				break;
		}
	}
}

int main() {
	chdir("templates");
	recompressDir(".", true);

	return 0;
}
