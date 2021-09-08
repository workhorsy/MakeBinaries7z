// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/MakeBinaries7z

import global;
import helpers;
import messages;
import json;
import structs;

import std.concurrency : Tid, thisTid, spawn, receive;
import core.thread.osthread : Thread;
import core.time : dur;
import std.variant : Variant;
import dlib.serialization.json : JSONObject, JSONValue, JSONType;

bool is_running = false;

class Manager {
	this(Tid parent_tid) {
		spawn(&onManagerStart, parent_tid);
	}
}

void onManagerStart(Tid parent_tid) {
	prints("!!!!!!!!!!!!!!!! manager started ...............");

	try {
		setThreadName("manager", thisTid());
		scope (exit) removeThreadName("manager");

		is_running = true;
		while (is_running) {
			//Thread.sleep(dur!("msecs")(1000));

			receive(&onManagerMessage);
		}
	} catch (Throwable err) {
		prints_error("(manager) thread threw: %s", err);
	}

	// Have the main loop exit if this ends for any reason
	g_is_running = false;
}

void onManagerMessage(Variant data) {
	string message_type;
	JSONObject jsoned = getThreadMessage(data, message_type);
	if (jsoned is null) return;
	scope (exit) if (jsoned) Delete(jsoned);

	//prints("!!!!!!!! manager got message %s", message_type);
	switch (message_type) {
		case "MessageStop":
			auto message = jsoned.jsonToStruct!MessageStop();
			is_running = false;
			break;
		default:
			prints_error("!!!! (manager) Unexpected message: %s", jsoned.jsonToString());
	}
}
