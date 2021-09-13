// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/smol

import global;
import helpers;
import messages;
import json;
import structs;

import core.thread.osthread : Thread;
import core.time : dur;
import dlib.serialization.json : JSONObject;


class Worker : IWorker {
	bool _is_running = false;
	int[] _pids;

	this() {
		onMessages("worker", 0, this);
		_is_running = true;
	}

	bool onMessage(string message_type, JSONObject jsoned) {
		switch (message_type) {
			case "MessageStop":
				auto message = jsoned.jsonToStruct!MessageStop();
				_is_running = false;
				return _is_running;
			case "MessageMonitorMemoryUsage":
				auto message = jsoned.jsonToStruct!MessageMonitorMemoryUsage();
				_pids ~= message.pid;
				break;
			default:
				prints_error("!!!! (manager) Unexpected message: %s", jsoned.jsonToString());
		}

		return true;
	}

	void onAfterMessage() {
		import std.algorithm : remove;

		Thread.sleep(dur!("msecs")(1000));
/*
		long total = 0;

		for (int i=0; i<_pids.length; i++) {
			long memory = getProcessMemoryUsage(_pids[i]);
			if (memory > 0) {
				total += memory;
			}
			if (memory == -1) {
				_pids = _pids.remove(i);
				i--;
			}
		}
		prints("!!! total memory: %s", total);
*/
	}
}

long getProcessMemoryUsage(int pid) {
	import std.process : executeShell;
	import std.string : format, split, strip;
	import std.array : replace;
	import std.conv : to;
	import std.algorithm : canFind;

	string command = `tasklist /fi "PID eq %s" /fo list`.format(pid);
	//prints("Running command: %s", command);
	auto exe = executeShell(command);
	if (exe.status != 0) {
		prints_error("%s", exe.output);
	}
	assert(exe.status == 0);

	if (exe.output.strip() == "INFO: No tasks are running which match the specified criteria.") {
		return -1;
	}

	//prints("??? exe.output: %s", exe.output.strip());
	if (! exe.output.canFind("7z.exe")) {
		return -1;
	}

	string raw_size = exe.output.split(`Mem Usage:`)[1].strip().replace(",", "");
	//prints("!!! raw_size: %s", raw_size);
	long a = raw_size.before(" ").to!long;
	string b = raw_size.after(" ");
	long size;
	final switch (b) {
		case "K":
			size = a * 1024;
			break;
	}

	return size;
}
