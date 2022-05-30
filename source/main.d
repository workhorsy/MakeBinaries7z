// Copyright (c) 2021-2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recursively re compresses directories with lzma2 compression
// https://github.com/workhorsy/smol


import global;
import helpers;
import messages;
import manager;
import worker;
import dispatch;
import pack;
import unpack;

import std.concurrency : Tid, thisTid;
import core.thread.osthread : Thread;
import core.time : dur;

immutable string VERSION = "0.1";

/*
Dispatch _dispatch;
*/
int main(string[] args) {
	import std.file : exists;
	import std.getopt : getopt;
	import std.string : format;

	initRandom();
/*
	setThreadName("main", thisTid());
	scope (exit) removeThreadName("main");
*/
	// Change the dir to the location of the current exe
	//chdir(pathDirName(args[0]));
/*
	_dispatch = new Dispatch("main");
	auto worker = new Worker();
	auto manager = new Manager();
*/
	// Get the options
	string pack_path = null;
	string unpack_path = null;
	bool is_help = false;
	bool is_version = false;
	string getopt_error = null;
	try {
		auto result = getopt(args,
		"pack", &pack_path,
		"unpack", &unpack_path,
		"version", &is_version);
		is_help = result.helpWanted;
	} catch (Exception err) {
		getopt_error = err.msg;
		is_help = true;
	}

	if (is_version) {
		prints("smol v%s\n".format(VERSION) ~
		"Copyright (c) 2021-2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>\n" ~
		"Licensed under: Boost Software License - Version 1.0\n" ~
		"Hosted at: https://github.com/workhorsy/smol\n");
		return 0;
	}

	// If there was an error, print the help and quit
	if (is_help) {
		prints_error(
		"smol v%s\n".format(VERSION) ~
		"Copyright (c) 2021-2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>\n" ~
		"Licensed under: Boost Software License - Version 1.0\n" ~
		"Hosted at: https://github.com/workhorsy/smol\n" ~
		"\n" ~
		"Recursively re compresses directories with lzma2 compression\n" ~
		"    * Requires 7zip\n" ~
		"    * Re compresses Zip, BZip2, and GZip to lzma2\n" ~
		"    * Files inside of compressed files are also re compressed\n" ~
		"    * Directories that start with a \".\" are ignored\n" ~
		"    * All other files are compressed using lzma2\n" ~
		"    * After compression, files are broken into 10 MB chunks\n" ~
		"    * --pack re compresses all files, while --unpack changes all files back to normal\n" ~
		"\n" ~
		"usage:\n" ~
		"smol --pack <dir>\n" ~
		"smol --unpack <dir>\n" ~
		"--help    This help information.\n" ~
		"--version    Program version.\n");

		if (getopt_error) {
			prints_error("Error: %s", getopt_error);
			return 1;
		} else {
			return 0;
		}
	}

	// Make sure we got path to pack
	if (pack_path) {
		pack_path = toPosixPath(pack_path);
		if (! exists(pack_path)) {
			prints_error(`Error: pack path not found: %s`, pack_path);
			return 1;
		}
	}

	// Make sure we got path to unpack
	if (unpack_path) {
		unpack_path = toPosixPath(unpack_path);
		if (! exists(unpack_path)) {
			prints_error(`Error: unpack path not found: %s`, unpack_path);
			return 1;
		}
	}

	if (! pack_path && ! unpack_path) {
		prints_error(`Error: unpack or pack path required`);
		return 1;
	}
/*
	// FIXME: Wait for workers to start
	Thread.sleep(dur!("seconds")(3));
*/

	import chunker;
	if (pack_path) {
/*
		auto b = _dispatch.packPath(pack_path);
		_dispatch.await(b);
*/
		packDir(pack_path, true);
		chunkDirFiles(pack_path);
	} else if (unpack_path) {
/*
		auto b = _dispatch.unpackPath(unpack_path);
		_dispatch.await(b);
*/
		unChunkDirFiles(unpack_path);
		unpackDir(unpack_path, true);
	}

	prints("smol done");
/*
	sendThreadMessageUnconfirmed("worker", MessageStop());
	sendThreadMessageUnconfirmed("manager", MessageStop());
	return manager._retval;
*/
	return 0;
}
