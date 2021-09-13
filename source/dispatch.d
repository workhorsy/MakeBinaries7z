// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/smol

import std.stdio : stdout, stderr;


import global;
import helpers;
import messages;
import structs;
import json;

class Dispatch {
	string _thread_name;

	this(string thread_name) {
		_thread_name = thread_name;
	}

	size_t packPath(string pack_path) {
		auto message = MessagePack("manager", pack_path);
		return sendThreadMessage(_thread_name, message.to_tid, message);
	}

	size_t unpackPath(string unpack_path) {
		auto message = MessageUnpack("manager", unpack_path);
		return sendThreadMessage(_thread_name, message.to_tid, message);
	}

	void monitorMemoryUsage(int pid) {
		auto message = MessageMonitorMemoryUsage("worker", "7z.exe", pid);
		sendThreadMessageUnconfirmed(message.to_tid, message);
	}

	void taskDone(size_t from_fid, string from_tid, string receipt) {
		auto message = MessageTaskDone(from_tid, receipt, from_fid, from_tid);
		sendThreadMessageUnconfirmed(from_tid, message);
	}

	void await(size_t[] awaiting_fids ...) {
		import std.concurrency : receive;
		import std.variant : Variant;
		import dlib.serialization.json : JSONObject, JSONValue, JSONType;
		import std.algorithm : remove;
		import std.string : format;

		while (awaiting_fids.length > 0) {
			receive((Variant data) {
				//print("<<<<<<<<<< Dispatch.await data %s", data.to!string);
				string message_type;
				JSONObject jsoned = getThreadMessage(data, message_type);
				if (jsoned is null) return;
				scope (exit) if (jsoned) Delete(jsoned);

				switch (message_type) {
					case "MessageTaskDone":
						auto message = jsoned.jsonToStruct!MessageTaskDone();
						size_t fid = message.from_fid;
						awaiting_fids = awaiting_fids.remove!(await_fid => await_fid == fid);
						break;
					default:
						stderr.writefln("!!!! (Dispatch.await) Unexpected message: %s", jsoned.jsonToString()); stderr.flush();
				}
			});
		}
	}
}
