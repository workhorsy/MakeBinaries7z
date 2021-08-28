
import std.array : replace;
import std.file : remove, rmdirRecurse, exists, chdir, dirEntries, SpanMode;
import std.process : execute;
import std.stdio : stdout;
import std.string : format;

void recompress(string name) {
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
	string out_file = "%s.7z".format(name);

	// Delete the out file
	if (exists(out_file)) {
		remove(out_file);
	}

	// Compress to 7z
	auto zip = execute(["7z", "a", out_file, name]);
	assert(zip.status == 0);
}

char[10] readHeader(string name) {
	import std.stdio : File;

	// Read the file into an array
	auto f = File(name, "r");
	char[10] header = 0;
	f.rawRead(header);
	return header;
}

int main() {
	chdir("templates");
/*
	recompress("android_debug.apk");
	recompress("uwp_arm_debug.zip");
	compress("windows_32_debug.exe");
*/

	foreach (string name; dirEntries(".", SpanMode.depth)) {
		name = name.replace(`\`, `/`);
		stdout.writefln("name: %s", name); stdout.flush();

		auto header = readHeader(name);
		bool is_zip = header[0 .. 4] == [0x50, 0x4B, 0x03, 0x04];
		bool is_7z = header[0 .. 4] == [0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C];
		stdout.writefln("is_zip:%s, is_7z: %s", is_zip, is_7z); stdout.flush();
		// Ignore 7z
		if (is_7z) {

		// Reompress zips
		} else if (is_zip) {
			recompress(name);
		// Compress all other files
		} else {
			compress(name);
		}
	}

	return 0;
}
