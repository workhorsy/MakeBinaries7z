// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/MakeBinaries7z


import global;
import helpers;
import encode;
import structs;
import json;

import std.concurrency : Tid, thisTid, spawn, receive, receiveTimeout;
import std.variant : Variant;
import core.thread : msecs;
import dlib.serialization.json : JSONObject, JSONValue, JSONType;

struct MessageStop {
	string to_tid;
	string from_tid;
}

__gshared Tid[string] _tid_names;

void setThreadName(string name, Tid tid) {
	synchronized {
		_tid_names[name] = tid;
	}
}

void removeThreadName(string name) {
	synchronized {
		_tid_names.remove(name);
	}
}

Tid getThreadTid(string name) {
	synchronized {
		if (name in _tid_names) {
			return _tid_names[name];
		}
	}

	return Tid.init;
}

size_t sendThreadMessage(MessageType)(string from_thread_name, string to_thread_name, MessageType message) {
	import core.atomic : atomicOp;
	import std.string : format;

	Tid target_thread = getThreadTid(to_thread_name);
	if (target_thread == Tid.init) {
		throw new Exception(`No thread with name "%s" found`.format(to_thread_name));
	}

	size_t fid = _next_fiber_id.atomicOp!"+="(1);
	string tid = from_thread_name;

	JSONObject jsoned = message.structToJson();
	scope (exit) deleteJson(jsoned);

	string b64ed = jsoned.encodeMessage(fid, tid);

	send(target_thread, b64ed);
	return fid;
}

void sendThreadMessageUnconfirmed(MessageType)(string to_thread_name, MessageType message) {
	import std.concurrency : receive, send, thisTid, Tid;

	JSONObject jsoned = message.structToJson();
	scope (exit) deleteJson(jsoned);

	string b64ed = jsoned.encodeMessage();
	//print("!!!! b64ed: %s", b64ed);
	//printJSONObject(jsoned);

	try {
		send(getThreadTid(to_thread_name), b64ed);
	} catch (Throwable err) {
		prints_error("Failed to send message %s", err);
	}
}

JSONObject getThreadMessage(Variant data, ref string message_type) {
	JSONObject jsoned;
	try {
		jsoned = decodeMessage(data);
	} catch (Exception err) {
		prints_error("Failed to decode message %s", err);
	}

	if (jsoned && "type" in jsoned && jsoned["type"].type == JSONType.String) {
		message_type = jsoned["type"].asString;
	}
	return jsoned;
}

void onMessages(string name, ulong receive_ms, void* data,
	bool function(void* d, string message_type, JSONObject jsoned) cb,
	void function() after_message_cb = null) {

	spawn(function(string _name, ulong _receive_ms, size_t _data,
		bool function(void* d, string message_type, JSONObject jsoned) _cb,
		void function() _after_message_cb = null) {

		prints("!!!!!!!!!!!!!!!! %s started ...............", _name);

		try {
			setThreadName(_name, thisTid());
			scope (exit) removeThreadName(_name);

			bool is_running = true;
			while (is_running) {
				//Thread.sleep(dur!("msecs")(1000));

				if (_receive_ms == ulong.max) {
					receive((Variant data) {
						string message_type;
						JSONObject jsoned = getThreadMessage(data, message_type);
						if (jsoned is null) return;
						scope (exit) if (jsoned) Delete(jsoned);

						//prints("!!!!!!!! manager got message %s", message_type);
						is_running = _cb(cast(void*) _data, message_type, jsoned);
					});
				} else {
					receiveTimeout(_receive_ms.msecs, (Variant data) {
						string message_type;
						JSONObject jsoned = getThreadMessage(data, message_type);
						if (jsoned is null) return;
						scope (exit) if (jsoned) Delete(jsoned);

						//prints("!!!!!!!! manager got message %s", message_type);
						is_running = _cb(cast(void*) _data, message_type, jsoned);
					});

					if (_after_message_cb) {
						_after_message_cb();
					}
				}
			}
		} catch (Throwable err) {
			prints_error("(%s) thread threw: %s", _name, err);
		}
	}, name, receive_ms, cast(size_t) data, cb, after_message_cb);
}
