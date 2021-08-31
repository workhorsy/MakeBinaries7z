// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/MakeBinaries7z

module helpers;

import std.traits : isSomeString;

public import std.file : SpanMode;
public import std.file : DirIterator;

string _root_path = null;

void reset_path(string project_path) {
	import std.file : chdir;
	import helpers : getcwd, buildPath;

	if (! _root_path) {
		_root_path = getcwd();
	}

	chdir(buildPath(_root_path, project_path));
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

void copyTree(string from_path, string to_path) {
	import std.process : execute;
	import std.stdio : stderr;

	string[] command = ["cp", "-r", from_path, to_path];
	//prints("Running command: %s", command);
	auto exe = execute(command);
	if (exe.status != 0) {
		stderr.writefln("%s", exe.output); stderr.flush();
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

string baseName(string path) {
	import std.path : baseName;
	import std.array : replace;
	return baseName(path).replace(`\`, `/`);
}

string dirName(string path) {
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
