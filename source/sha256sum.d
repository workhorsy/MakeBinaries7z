// Copyright (c) 2021-2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recursively re compresses directories with lzma2 compression
// https://github.com/workhorsy/smol



import helpers;


version (linux) {
	immutable string ExeSha256Sum = "sha256sum";
} else {
	static assert(0, "Unsupported platform");
}

string getSha256Sum(string in_name) {
	import std.process : pipeProcess, wait, Redirect;
	import std.string : split;
	import std.array : array;
	import std.algorithm : map;

	string[] command = [ExeSha256Sum, in_name];
	auto pipes = pipeProcess(command, Redirect.all);

	// Get output
	int status = wait(pipes.pid);
	string[] output = pipes.stdout.byLine.map!(l => l.idup).array();
	string[] errors = pipes.stderr.byLine.map!(l => l.idup).array();

	if (status != 0) {
		prints_error("%s", errors);
	}
	assert(status == 0);
	return output[0].split(" ")[0];
}
