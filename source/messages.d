// Copyright (c) 2021-2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recursively re compresses directories with lzma2 compression
// https://github.com/workhorsy/smol


import global;
import helpers;

import std.concurrency : Tid, thisTid, spawn, receive, receiveTimeout;
import std.variant : Variant;
import core.thread : msecs;

// FIXME: Rename to EncodedMessage
struct MessageHolder {
	string message_type;
	ubyte[] message;
	size_t mid;
	string from_tid;
	string to_tid;

	T decodeMessage(T)() {
		import cbor : decodeCborSingle;

		return decodeCborSingle!T(message);
	}
}

// FIXME: Move these structs out of this module, because they
// are app specific
struct MessageStop {
}

struct MessagePack {
	string path;
}

struct MessageUnpack {
	string path;
}

struct MessageTaskDone {
	string receipt;
	size_t mid;
	string from_tid;
	string to_tid;
}

struct MessageMonitorMemoryUsage {
	string exe_name;
	int pid;
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
	import std.concurrency : send, Tid;
	import core.atomic : atomicOp;
	import std.string : format;
	import std.array : appender;
	import std.base64 : Base64;
	import cbor : encodeCbor;

	Tid target_thread = getThreadTid(to_thread_name);
	if (target_thread == Tid.init) {
		throw new Exception(`No thread with name "%s" found`.format(to_thread_name));
	}

	// Convert the message to a blob
	auto message_buffer = appender!(ubyte[])();
	encodeCbor(message_buffer, message);
	ubyte[] message_blob = message_buffer.data;

	// Get a message holder
	size_t mid = _next_message_id.atomicOp!"+="(1);
	string from_tid = from_thread_name;
	string message_type = MessageType.stringof;
	auto holder = MessageHolder(message_type, message_blob, mid, from_tid);

	// Convert the holder to a blob
	auto holder_buffer = appender!(ubyte[])();
	encodeCbor(holder_buffer, holder);
	ubyte[] holder_blob = holder_buffer.data;

	// Base64 the holder blob
	string b64ed = Base64.encode(holder_blob);
	string encoded = `%.5s:%s`.format(cast(u16) b64ed.length, b64ed);

	send(target_thread, encoded);
	return mid;
}

void sendThreadMessageUnconfirmed(MessageType)(string to_thread_name, MessageType message) {
	import std.concurrency : send, Tid;
	import core.atomic : atomicOp;
	import std.string : format;
	import std.array : appender;
	import std.base64 : Base64;
	import cbor : encodeCbor;

	// Convert the message to a blob
	auto message_buffer = appender!(ubyte[])();
	encodeCbor(message_buffer, message);
	ubyte[] message_blob = message_buffer.data;

	// Get a message holder
	string message_type = MessageType.stringof;
	auto holder = MessageHolder(message_type, message_blob);

	// Convert the holder to a blob
	auto holder_buffer = appender!(ubyte[])();
	encodeCbor(holder_buffer, holder);
	ubyte[] holder_blob = holder_buffer.data;

	// Base64 the holder blob
	string b64ed = Base64.encode(holder_blob);
	string encoded = `%.5s:%s`.format(cast(u16) b64ed.length, b64ed);

	try {
		send(getThreadTid(to_thread_name), encoded);
	} catch (Throwable err) {
		prints_error("Failed to send message to %s, %s", to_thread_name, err);
	}
}

MessageHolder getThreadMessage(Variant data) {
	import cbor : decodeCborSingle;
	import std.base64 : Base64;
	import std.conv : to;
	import std.algorithm : canFind;

	// NOTE: data may be string, char[], or immutable(char[]), so just assume string
	string encoded = data.to!string;

	// Length < "00000:A"
	if (encoded.length < 7) {
		return MessageHolder.init;
	// Missing :
	} else if (encoded[5] != ':') {
		return MessageHolder.init;
	}

	// Validate size prefix
	immutable char[] NUMBERS = "0123456789";
	foreach (n ; encoded[0 .. 5]) {
		if (! NUMBERS.canFind(n)) {
			return MessageHolder.init;
		}
	}

	// Validate base64 payload
	immutable char[] CODES = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
	foreach (n ; encoded[6 .. $]) {
		if (! CODES.canFind(n)) {
			return MessageHolder.init;
		}
	}

	int len = encoded[0 .. 5].to!int;
	//print("!!!!!!!!!!<<<<<<<< len: %s", len);
	ubyte[] b64ed = cast(ubyte[]) encoded[6 .. $];
	//print("!!!!!!!!!!<<<<<<<< b64ed: %s", b64ed);

	if (len != b64ed.length) {
		return MessageHolder.init;
	}

	// UnBase64 the blob
	ubyte[] blob = cast(ubyte[]) Base64.decode(b64ed);

	auto message_holder = decodeCborSingle!MessageHolder(blob);
	return message_holder;
}

interface IMessageThread {
	bool onMessage(MessageHolder message_holder);
	void onAfterMessage();
}

void startMessageThread(string name, ulong receive_ms, IMessageThread message_thread) {
	spawn(function(string _name, ulong _receive_ms, size_t _ptr) {
		prints("!!!!!!!!!!!!!!!! %s started ...............", _name);

		try {
			setThreadName(_name, thisTid());
			scope (exit) removeThreadName(_name);

			bool is_running = true;
			while (is_running) {

				// Get the actual message thread from the pointer
				void* ptr = cast(void*) _ptr;
				IMessageThread message_thread = cast(IMessageThread) ptr;

				// Get a cb to run the onMessage
				auto cb = delegate(Variant data) {
					MessageHolder holder = getThreadMessage(data);
					if (holder is MessageHolder.init) return;

					//prints("!!!!!!!! got message %s", message_type);
					is_running = message_thread.onMessage(holder);
				};

				// If ms is max, then block forever waiting for messages
				if (_receive_ms == ulong.max) {
					receive(cb);
				// Otherwise only block for the ms
				} else {
					receiveTimeout(_receive_ms.msecs, cb);
				}

				// Run the after message cb
				message_thread.onAfterMessage();
			}
		} catch (Throwable err) {
			prints_error("(%s) thread threw: %s", _name, err);
		}
	}, name, receive_ms, cast(size_t) (cast(void*) message_thread));
}

private:

shared size_t _next_message_id;
