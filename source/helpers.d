// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/smol

module helpers;

import std.traits : isSomeString;
import std.random : MinstdRand0;

public import std.file : SpanMode;
public import std.file : DirIterator;

MinstdRand0 g_rand;

void initRandom() {
	import core.stdc.time : time;

	g_rand = MinstdRand0(1);

	// Seed random number generator
	g_rand.seed(cast(uint) time(null));
}

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

void prints_error(string message) {
	import std.stdio : stderr;
	stderr.writeln(message); stderr.flush();
}

void prints_error(alias fmt, A...)(A args)
if (isSomeString!(typeof(fmt))) {
	import std.format : checkFormatException;

	alias e = checkFormatException!(fmt, A);
	static assert(!e, e.msg);
	return prints_error(fmt, args);
}

void prints_error(Char, A...)(in Char[] fmt, A args) {
	import std.stdio : stderr;
	stderr.writefln(fmt, args); stderr.flush();
}

void copyDirTree(string from_path, string to_path) {
	import std.process : execute;

	string[] command = ["cp", "-r", from_path, to_path];
	//prints("Running command: %s", command);
	auto exe = execute(command);
	if (exe.status != 0) {
		prints_error("%s", exe.output);
	}
	assert(exe.status == 0);
}

// FIXME: Have it change all path seps from \ to /
DirIterator dirEntries(string path, SpanMode mode, bool followSymlink = true) {
	import std.file : dirEntries;
	return dirEntries(path, mode, followSymlink);
}

string absolutePath(string path) {
	import std.path : absolutePath;
	import std.array : replace;
	return absolutePath(path).replace(`\`, `/`);
}

string getcwd() {
	import std.file : getcwd;
	import std.array : replace;
	return getcwd().replace(`\`, `/`);
}

void chdir(string path) {
	import std.file : chdir;
	chdir(path);
}

string buildPath(string[] args ...) {
	import std.path : buildPath;
	import std.array : replace;
	return buildPath(args).replace(`\`, `/`);
}

string pathBaseName(string path) {
	import std.path : baseName;
	import std.array : replace;
	return baseName(path).replace(`\`, `/`);
}

string pathDirName(string path) {
	import std.path : dirName;
	import std.array : replace;
	return dirName(path).replace(`\`, `/`);
}

string toPosixPath(string path) {
	import std.array : replace;
	import std.algorithm : endsWith;
	path = path.replace(`\`, `/`);
	if (! path.endsWith(`/`)) {
		path ~= `/`;
	}
	return path;
}

auto sortBy(string field_name, T)(T things) {
	import std.algorithm : sort;
	import std.string : format;

	alias sortFilter = (a, b) => mixin("a.%s < b.%s".format(field_name, field_name));

	return things.sort!(sortFilter);
}

S before(S)(S value, S separator) if (isSomeString!S) {
	import std.string : indexOf;
	long i = indexOf(value, separator);

	if (i == -1)
		return value;

	return value[0 .. i];
}

S after(S)(S value, S separator) if (isSomeString!S) {
	import std.string : indexOf;
	long i = indexOf(value, separator);

	if (i == -1)
		return "";

	size_t start = i + separator.length;

	return value[start .. $];
}

S between(S)(S value, S front, S back) if (isSomeString!S) {
	return value.after(front).before(back);
}
