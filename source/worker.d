// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/MakeBinaries7z

import global;
import helpers;
import messages;
import encode;
import json;
import structs;

import std.concurrency : Tid, thisTid, spawn, receive, receiveTimeout;
import core.thread.osthread : Thread;
import core.time : dur;
import std.variant : Variant;
import core.thread : msecs;
import dlib.serialization.json : JSONObject, JSONValue, JSONType;


class Worker : IWorker {
	bool _is_running = false;

	this() {
		onMessages("worker", 0, this);
	}

	bool onMessage(string message_type, JSONObject jsoned) {
		switch (message_type) {
			case "MessageStop":
				auto message = jsoned.jsonToStruct!MessageStop();
				_is_running = false;
				return _is_running;
			default:
				prints_error("!!!! (manager) Unexpected message: %s", jsoned.jsonToString());
		}

		return true;
	}

	void onAfterMessage() {
		Thread.sleep(dur!("msecs")(1000));
		// FIXME: Get pids to monitor here
		ulong memory = getProcessMemoryUsage(172);
		prints("!!! memory; %s", memory);
	}
}

ulong getProcessMemoryUsage(int pid) {
	import std.process : executeShell;
	import std.string : format, split, strip;
	import std.array : replace;
	import std.conv : to;

	string command = `tasklist /fi "PID eq %s" /fo list`.format(pid);
	//prints("Running command: %s", command);
	auto exe = executeShell(command);
	if (exe.status != 0) {
		prints_error("%s", exe.output);
	}
	assert(exe.status == 0);

	string raw_size = exe.output.split(`Mem Usage:`)[1].strip().replace(",", "");
	//prints("!!! raw_size: %s", raw_size);
	ulong a = raw_size.before(" ").to!ulong;
	string b = raw_size.after(" ");
	ulong size;
	final switch (b) {
		case "K":
			size = a * 1024;
			break;
	}

	return size;
}
