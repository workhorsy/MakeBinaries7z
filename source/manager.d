// Copyright (c) 2021-2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recursively re compresses directories with lzma2 compression
// https://github.com/workhorsy/smol

import global;
import helpers;
import messages;
import dispatch;
import chunker;
import pack;
import unpack;

import core.thread.osthread : Thread;


class Manager : IMessageThread {
	bool _is_running = false;
	int _retval = 0;
	Dispatch _dispatch;

	this() {
		_dispatch = new Dispatch("manager");
		startMessageThread("manager", ulong.max, this);
		_is_running = true;
	}

	bool onMessage(EncodedMessage encoded) {
		switch (encoded.message_type) {
			case "MessageStop":
				auto message = encoded.decodeMessage!MessageStop();
				_is_running = false;
				break;
			case "MessagePack":
				auto message = encoded.decodeMessage!MessagePack();
				//prints("!!! pack_path: %s", pack_path);
				packDir(message.path, true);
				chunkDirFiles(message.path);
				_dispatch.taskDone(encoded.mid, encoded.from_tid, "packPath");
				break;
			case "MessageUnpack":
				auto message = encoded.decodeMessage!MessageUnpack();
				//prints("!!! unpack_path: %s", unpack_path);
				unChunkDirFiles(message.path);
				unpackDir(message.path, true);
				_dispatch.taskDone(encoded.mid, encoded.from_tid, "unpackPath");
				break;
			default:
				prints_error("!!!! (manager) Unexpected message: %s", encoded);
		}

		return _is_running;
	}

	void onAfterMessage() {

	}
}
