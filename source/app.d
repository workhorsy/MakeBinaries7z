
import std.array : replace;
import std.file : remove, rmdirRecurse, exists, chdir, dirEntries, SpanMode, isDir;
import std.process : execute;
import std.stdio : stdout;
import std.string : format;


void prints(string message) {
	import std.stdio : stdout;
	debug {
		stdout.writeln(message); stdout.flush();
	}
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
	debug {
		stdout.writefln(fmt, args); stdout.flush();
	}
}


void recompress(string name) {
	stdout.writefln("    recompressing: %s", name); stdout.flush();
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
	auto unzip = execute(["7z", "x", name, "-o%s".format(temp_dir)]);
	assert(unzip.status == 0);

	// Compress to 7z
	auto zip = execute(["7z", "a", out_file, temp_dir]);
	assert(zip.status == 0);

	// Delete the temp directory
	if (exists(temp_dir)) {
		rmdirRecurse(temp_dir);
	}
}

void compress(string name) {
	stdout.writefln("    compressing: %s", name); stdout.flush();
	string out_file = "%s.7z".format(name);

	// Delete the out file
	if (exists(out_file)) {
		remove(out_file);
	}

	// Compress to 7z
	auto zip = execute(["7z", "a", out_file, name]);
	assert(zip.status == 0);

	// Delete the original file
	if (exists(name)) {
		remove(name);
	}
}

char[10] readHeader(string name) {
	import std.stdio : File;

	// Read the file into an array
	auto f = File(name, "r");
	char[10] header = 0;
	f.rawRead(header);
	return header;
}

void fuck(string file_name) {
	string temp_dir = "%s.extracted".format(file_name);
	string out_file = "%s.7z".format(file_name);

	// Delete the out file
	if (exists(out_file)) {
		remove(out_file);
	}

	// Delete the temp directory
	if (exists(temp_dir)) {
		rmdirRecurse(temp_dir);
	}

	// Extract to temp directory
	auto unzip = execute(["7z", "x", file_name, "-o%s".format(temp_dir)]);
	assert(unzip.status == 0);

	foreach (string name; dirEntries(temp_dir, SpanMode.depth)) {
		if (isDir(name)) continue;

		name = name.replace(`\`, `/`);
		//stdout.writefln("    name: %s", name); stdout.flush();

		auto header = readHeader(name);
		bool is_zip = header[0 .. 4] == [0x50, 0x4B, 0x03, 0x04];
		bool is_7z = header[0 .. 4] == [0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C];
		//stdout.writefln("is_zip:%s, is_7z: %s", is_zip, is_7z); stdout.flush();

		// Ignore 7z
		if (is_7z) {

		// Reompress zips
		} else if (is_zip) {
			recompress(name);

			// Delete the original zip
			if (exists(name)) {
				remove(name);
			}
		// Compress all other files
		} else {
			//compress(name);
		}
	}

	// Compress to 7z
	//prints("out_file: %s", out_file);
	//prints("file_name: %s", file_name);
	auto zip = execute(["7z", "a", out_file, "%s.extracted".format(file_name)]);
	assert(zip.status == 0);

	// Delete the temp directory
	if (exists(temp_dir)) {
		rmdirRecurse(temp_dir);
	}

	// Delete the original file
	if (exists(file_name)) {
		remove(file_name);
	}
}

int main() {
	chdir("templates");

	foreach (string name; dirEntries(".", SpanMode.depth)) {
		name = name.replace(`\`, `/`);
		stdout.writefln("scanning: %s", name); stdout.flush();

		auto header = readHeader(name);
		bool is_zip = header[0 .. 4] == [0x50, 0x4B, 0x03, 0x04];
		bool is_7z = header[0 .. 4] == [0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C];
		//stdout.writefln("is_zip:%s, is_7z: %s", is_zip, is_7z); stdout.flush();

		// Ignore 7z
		if (is_7z) {

		// Reompress zips
		} else if (is_zip) {
			fuck(name);
		// Compress all other files
		} else {
			compress(name);
		}
	}

	return 0;
}
