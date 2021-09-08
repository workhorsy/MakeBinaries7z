// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/MakeBinaries7z

import global;
import helpers;
//import messages;
import base64;
import json;
import structs;

import std.conv : to;
import std.variant : Variant;
import dlib.serialization.json : JSONObject, JSONValue, JSONType;


string encodeMessage(JSONObject jsoned, size_t from_fid=0, string from_tid="unknown") {
	//import bc.string.format;
	import std.string : format;

	// Add from_fid the from_tid if missing
	JSONValue jsoned_fid = null;
	if ("from_fid" in jsoned && jsoned["from_fid"].asNumber == 0) {
		jsoned_fid = New!JSONValue();
		jsoned_fid.type = JSONType.Number;
		jsoned_fid.asNumber = from_fid;
		jsoned["from_fid"] = jsoned_fid;
	}
	JSONValue jsoned_tid = null;
	if ("from_tid" in jsoned && jsoned["from_tid"].asString == "") {
		jsoned_tid = New!JSONValue();
		jsoned_tid.type = JSONType.String;
		jsoned_tid.asString = from_tid;
		jsoned["from_tid"] = jsoned_tid;
	}

	auto buf_json = New!(char[])(1024);
	scope (exit) Delete(buf_json);
	buf_json[0 .. $] = 0;

	auto buf_base64 = New!(char[])(1024);
	scope (exit) Delete(buf_base64);
	buf_base64[0 .. $] = 0;

	auto buf_message = New!(char[])(1024);
	scope (exit) Delete(buf_message);
	buf_message[0 .. $] = 0;

	// Convert JSON to string
	string stringed = jsoned.jsonToString(buf_json);
	//print(">>>>>>> stringed: %s", stringed);

	// Convert string to base64
	string b64ed = cast(string) stringed.stringToBase64(buf_base64);
	//print(">>>>>>> b64ed: %s", b64ed);

	// Convert base64 to message
	string encoded = `%.5s:%s`.format(cast(u16) b64ed.length, b64ed);
	//print(">>>>>>> encoded: %s", encoded);

	return encoded;
}

JSONObject decodeMessage(Variant data) {
	import std.string : endsWith;
	import std.algorithm : canFind;

	// NOTE: data may be string, char[], or immutable(char[]), so just assume string
	string encoded = data.to!string;
	//print("!!!!!!!!!!<<<<<<<< encoded: %s", encoded);

	// Length < "00000:A"
	if (encoded.length < 7) {
		return null;
	// Missing :
	} else if (encoded[5] != ':') {
		return null;
	}

	// Validate size prefix
	immutable char[] NUMBERS = "0123456789";
	foreach (n ; encoded[0 .. 5]) {
		if (! NUMBERS.canFind(n)) {
			return null;
		}
	}

	// Validate base64 payload
	immutable char[] CODES = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
	foreach (n ; encoded[6 .. $]) {
		if (! CODES.canFind(n)) {
			return null;
		}
	}

	int len = encoded[0 .. 5].to!int;
	//print("!!!!!!!!!!<<<<<<<< len: %s", len);
	string b64ed = encoded[6 .. $];
	//print("!!!!!!!!!!<<<<<<<< b64ed: %s", b64ed);

	if (len != b64ed.length) {
		return null;
	}

	auto buf = New!(char[])(1024);
	buf[0 .. $] = 0;
	scope (exit) Delete(buf);

	// Convert base64 to string
	string stringed = cast(string) b64ed.base64ToString(buf);
	//print("!!!!!!!!!!<<<<<<<< stringed: %s", stringed);

	JSONObject jsoned = stringed.stringToJson();
	//print("!!!!!!!!!!<<<<<<<< jsoned: %s", jsoned);
	return jsoned;
}

unittest {
	import BDD;

	struct Cat {
		string name;
		bool is_bad;
		size_t from_fid;
		string from_tid;
	}

	JSONObject jsoned = null;

	describe("encode",
		before(delegate() {
			jsoned = null;
		}),
		after(delegate() {
			deleteJson(jsoned);
		}),
		it("Should encode struct", delegate() {
			string b64ed;

			// Struct has from_fid and from_tid
			Cat cat = Cat("Doomsday", true, 5, "image_loader");
			jsoned = cat.structToJson();
			b64ed = jsoned.encodeMessage();
			// {"type":"Cat","name":"Doomsday","is_bad":true,"from_fid":5,"from_tid":"image_loader"}
			b64ed.shouldEqual("00116:eyJ0eXBlIjoiQ2F0IiwibmFtZSI6IkRvb21zZGF5IiwiaXNfYmFkIjp0cnVlLCJmcm9tX2ZpZCI6NSwiZnJvbV90aWQiOiJpbWFnZV9sb2FkZXIifQ==");

			// Encoder provides from_fid and from_tid
			cat = Cat("Doomsday", true);
			jsoned = cat.structToJson();
			b64ed = jsoned.encodeMessage(7, "timer");
			// {"type":"Cat","name":"Doomsday","is_bad":true,"from_fid":7,"from_tid":"timer"}
			b64ed.shouldEqual("00104:eyJ0eXBlIjoiQ2F0IiwibmFtZSI6IkRvb21zZGF5IiwiaXNfYmFkIjp0cnVlLCJmcm9tX2ZpZCI6NywiZnJvbV90aWQiOiJ0aW1lciJ9");

			// Encoder provides default from_fid and from_tid
			cat = Cat("Doomsday", true);
			jsoned = cat.structToJson();
			b64ed = jsoned.encodeMessage();
			// {"type":"Cat","name":"Doomsday","is_bad":true,"from_fid":0,"from_tid":"unknown"}
			b64ed.shouldEqual("00108:eyJ0eXBlIjoiQ2F0IiwibmFtZSI6IkRvb21zZGF5IiwiaXNfYmFkIjp0cnVlLCJmcm9tX2ZpZCI6MCwiZnJvbV90aWQiOiJ1bmtub3duIn0=");
		}),
		it("Should decode struct", delegate() {
			// {"type":"Cat","name":"Doomsday","is_bad":true,"from_fid":7,"from_tid":"timer"}
			string message = "00104:eyJ0eXBlIjoiQ2F0IiwibmFtZSI6IkRvb21zZGF5IiwiaXNfYmFkIjp0cnVlLCJmcm9tX2ZpZCI6NywiZnJvbV90aWQiOiJ0aW1lciJ9";
			Variant data = Variant(message);
			jsoned = decodeMessage(data);
			Cat cat = jsoned.jsonToStruct!Cat();
			cat.name.shouldEqual("Doomsday");
			cat.is_bad.shouldEqual(true);
			cat.from_fid.shouldEqual(7);
			cat.from_tid.shouldEqual("timer");
		}),

		it("Should fail to decode invalid messages", delegate() {
			// Wrong length
			Variant("").decodeMessage().shouldEqual(null);
			Variant("00092:blah").decodeMessage().shouldEqual(null);

			// No payload
			Variant("00092").decodeMessage().shouldEqual(null);
			Variant("00092:").decodeMessage().shouldEqual(null);

			// Non numeric size prefix
			Variant("abcd:abcd").decodeMessage().shouldEqual(null);

			// Non base64 data payload
			Variant("00005:?????").decodeMessage().shouldEqual(null);
		}),
	);
}
