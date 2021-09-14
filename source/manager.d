// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/smol

import global;
import helpers;
import messages;
import json;
import structs;
import dispatch;
import chunker;
import pack;
import unpack;
import smol;

import core.thread.osthread : Thread;
import dlib.serialization.json : JSONObject;


class Manager : IWorker {
	bool _is_running = false;
	int _retval = 0;
	Dispatch _dispatch;

	this() {
		_dispatch = new Dispatch("manager");
		onMessages("manager", ulong.max, this);
		_is_running = true;
	}

	bool onMessage(string message_type, JSONObject jsoned) {
		switch (message_type) {
			case "MessageStop":
				auto message = jsoned.jsonToStruct!MessageStop();
				_is_running = false;
				break;
			case "MessagePack":
				auto message = jsoned.jsonToStruct!MessagePack();
				//prints("!!! pack_path: %s", pack_path);
				recompressDir(message.path, true);
				chunkDirFiles(message.path);
				_dispatch.taskDone(message.from_fid, message.from_tid, "packPath");
				break;
			case "MessageUnpack":
				auto message = jsoned.jsonToStruct!MessageUnpack();
				//prints("!!! unpack_path: %s", unpack_path);
				unChunkDirFiles(message.path);
				unRecompressDir(message.path, true);
				_dispatch.taskDone(message.from_fid, message.from_tid, "unpackPath");
				break;
			default:
				prints_error("!!!! (manager) Unexpected message: %s", jsoned.jsonToString());
		}

		return _is_running;
	}

	void onAfterMessage() {

	}
}
