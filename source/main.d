// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/MakeBinaries7z



import make_binaries_7z;


int main(string[] args) {
	import std.stdio : stdout, stderr, File;
	import std.file : chdir, getcwd;
	import std.file : exists;
	import std.getopt : getopt, config, GetOptException;
	import helpers : dirName, buildPath, toPosixPath, absolutePath;

	// Change the dir to the location of the current exe
	//chdir(dirName(args[0]));

	// Get the options
	string pack_path = null;
	string unpack_path = null;
	bool is_help = false;
	string getopt_error = null;
	try {
		auto result = getopt(args,
		"pack", &pack_path,
		"unpack", &unpack_path);
		is_help = result.helpWanted;
	} catch (Exception err) {
		getopt_error = err.msg;
		is_help = true;
	}

	// If there was an error, print the help and quit
	if (is_help) {
		stderr.writefln(
		"Make Binaries 7z\n" ~
		"--pack            Directory to re compress. Required:\n" ~
		"--unpack          Directory to un re compress. Required:\n" ~
		"--help            This help information.\n"); stderr.flush();

		if (getopt_error) {
			stderr.writefln("Error: %s", getopt_error); stderr.flush();
		}
		return 1;
	}

	// Make sure we got path to pack
	if (pack_path) {
		pack_path = toPosixPath(pack_path);
		if (! exists(pack_path)) {
			stderr.writefln(`Error: pack path not found: %s`, pack_path); stderr.flush();
			return 1;
		}
	}

	// Make sure we got path to unpack
	if (unpack_path) {
		unpack_path = toPosixPath(unpack_path);
		if (! exists(unpack_path)) {
			stderr.writefln(`Error: unpack path not found: %s`, unpack_path); stderr.flush();
			return 1;
		}
	}

	// Pack or unpack the dir
	if (pack_path) {
		//prints("!!! pack_path: %s", pack_path);
		recompressDir(pack_path, true);
	} else if (unpack_path) {
		//prints("!!! unpack_path: %s", unpack_path);
		unRecompressDir(unpack_path, true);
	} else {
		stderr.writefln(`Error: unpack or pack path required`); stderr.flush();
		return 1;
	}

	return 0;
}
