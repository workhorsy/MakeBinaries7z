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

bool is_running = false;

class Worker {
	this(Tid parent_tid) {
		spawn(&onWorkerStart, parent_tid);
	}
}

void onWorkerStart(Tid parent_tid) {
	prints("!!!!!!!!!!!!!!!! worker started ...............");

	try {
		setThreadName("worker", thisTid());
		scope (exit) removeThreadName("worker");

		is_running = true;
		while (is_running) {
			Thread.sleep(dur!("msecs")(1000));

			receiveTimeout(0.msecs, &onWorkerMessage);
		}
	} catch (Throwable err) {
		prints_error("(worker) thread threw: %s", err);
	}

	// Have the main loop exit if this ends for any reason
	g_is_running = false;
}

void onWorkerMessage(Variant data) {
	string message_type;
	JSONObject jsoned = getThreadMessage(data, message_type);
	if (jsoned is null) return;
	scope (exit) if (jsoned) Delete(jsoned);

	//prints("!!!!!!!! worker got message %s", message_type);
	switch (message_type) {
		case "MessageStop":
			auto message = jsoned.jsonToStruct!MessageStop();
			is_running = false;
			break;
		default:
			prints_error("!!!! (worker) Unexpected message: %s", jsoned.jsonToString());
	}
}
