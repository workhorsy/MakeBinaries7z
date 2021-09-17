// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recursively re compresses directories with lzma2 compression
// https://github.com/workhorsy/smol



import helpers;
import file_type;


string compression_level = "-mx9";
string compression_multi_thread = "-mmt=on";

version (linux) {
	immutable string Exe7Zip = "7z";
	immutable string ExeUnrar = "unrar";
} else version (Windows) {
	immutable string Exe7Zip = "7z.exe";
	immutable string ExeUnrar = "unrar.exe";
} else {
	static assert(0, "Unsupported platform");
}

void compress(string in_name, string out_name, FileType file_type) {
	import std.process : pipeProcess, wait, Redirect;
	import std.string : format;
	import std.file : isDir;
	import std.array : join, array;
	import std.algorithm : map;

	string compression_type;
	final switch (file_type) {
		case FileType.Zip:
			compression_type = "-tZip";
			break;
		case FileType.SevenZip:
			compression_type = "-t7z";
			break;
		case FileType.XZ:
			compression_type = "-tXZ";
			break;
		case FileType.GZip:
			compression_type = "-tGZip";
			break;
		case FileType.BZip2:
			compression_type = "-tBZip2";
			break;
		case FileType.Binary:
			compression_type = "";
			break;
	}

	//prints("%sCompressing: %s", padding, out_name);
	string[] command = ["7z", compression_type, compression_level, compression_multi_thread, "a", out_name, in_name];
	//prints("Running command: %s", command.join(" "));
	auto pipes = pipeProcess(command, Redirect.all);
	//prints("!!!! pid: %s", pipes.pid.processID);
/*
	// FIXME: Use dispatch instead of this
	import messages;
	auto message = MessageMonitorMemoryUsage(Exe7Zip, pipes.pid.processID);
	sendThreadMessageUnconfirmed("worker", message);
*/
	// Get output
	int status = wait(pipes.pid);
	string[] output = pipes.stdout.byLine.map!(l => l.idup).array();
	string[] errors = pipes.stderr.byLine.map!(l => l.idup).array();

	if (status != 0) {
		prints_error("%s", errors);
	}
	assert(status == 0);
}

void uncompress(string in_name, string out_name) {
	import std.process : pipeProcess, wait, Redirect;
	import std.string : format;
	import std.array : join, array;
	import std.algorithm : map;

	string[] command = ["7z", "x", in_name, "-o%s".format(out_name)];
	//prints("Running command: %s", command.join(" "));
	auto pipes = pipeProcess(command, Redirect.all);
	//prints("!!!! pid: %s", pipes.pid.processID);
/*
	// FIXME: Use dispatch instead of this
	import messages;
	auto message = MessageMonitorMemoryUsage(Exe7Zip, pipes.pid.processID);
	sendThreadMessageUnconfirmed("worker", message);
*/
	// Get output
	int status = wait(pipes.pid);
	string[] output = pipes.stdout.byLine.map!(l => l.idup).array();
	string[] errors = pipes.stderr.byLine.map!(l => l.idup).array();

	if (status != 0) {
		prints_error("%s", errors);
	}
	assert(status == 0);
}
