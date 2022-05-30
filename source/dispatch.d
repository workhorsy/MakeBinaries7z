// Copyright (c) 2021-2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recursively re compresses directories with lzma2 compression
// https://github.com/workhorsy/smol


import global;
import helpers;
import messages;

class Dispatch {
	string _thread_name;

	this(string thread_name) {
		_thread_name = thread_name;
	}

	size_t packPath(string pack_path) {
		auto message = MessagePack(pack_path);
		return sendThreadMessage(_thread_name, "manager", message);
	}

	size_t unpackPath(string unpack_path) {
		auto message = MessageUnpack(unpack_path);
		return sendThreadMessage(_thread_name, "manager", message);
	}

	void monitorMemoryUsage(int pid) {
		auto message = MessageMonitorMemoryUsage("7z.exe", pid);
		sendThreadMessageUnconfirmed("worker", message);
	}

	void taskDone(size_t mid, string from_tid, string receipt) {
		auto message = MessageTaskDone(receipt, mid, from_tid, from_tid);
		sendThreadMessageUnconfirmed(from_tid, message);
	}

	void await(size_t[] awaiting_mids ...) {
		import std.concurrency : receive;
		import std.variant : Variant;
		import std.algorithm : remove;
		import std.string : format;

		while (awaiting_mids.length > 0) {
			receive((Variant data) {
				//print("<<<<<<<<<< Dispatch.await data %s", data.to!string);
				MessageHolder holder = getThreadMessage(data);
				if (holder is MessageHolder.init) return;

				switch (holder.message_type) {
					case "MessageTaskDone":
						auto message = holder.decodeMessage!MessageTaskDone();
						size_t mid = message.mid;
						awaiting_mids = awaiting_mids.remove!(await_mid => await_mid == mid);
						break;
					default:
						prints_error("!!!! (Dispatch.await) Unexpected message: %s", holder);
				}
			});
		}
	}
}
