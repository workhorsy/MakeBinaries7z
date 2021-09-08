// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/MakeBinaries7z

import global;
import helpers;

import std.traits : isSomeString, isNumeric, isBoolean;
import dlib.serialization.json : JSONDocument, JSONObject, JSONValue, JSONType;

void printJSONObject(JSONObject jsoned) {
	prints(`/////////////////////////////////////////////`);
	foreach (string key, JSONValue value ; jsoned) {
		switch (value.type) {
			case JSONType.Boolean:
				prints("Key:%s, Boolean:%s", key, value.asBoolean);
				break;
			case JSONType.String:
				prints("Key:%s, String:%s", key, value.asString);
				break;
			case JSONType.Number:
				prints("Key:%s, Number:%s", key, value.asNumber);
				break;
			default:
				prints("Key:%s, ?:%s", key, value.type);
				break;
		}
	}
	prints(`\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\`);
}

void deleteJson(JSONObject jsoned) {
	if (jsoned) {
		foreach (string key, JSONValue value ; jsoned) {
			if (value) {
				Delete(value);
			}
		}
		Delete(jsoned);
		jsoned = null;
	}
}

/*@nogc*/ char[] writeToSink(SinkType)(ref SinkType sink, ref size_t pos, string data) {
	sink[pos .. pos + data.length] = data;
	pos += data.length;
	return sink[pos .. $];
}

string jsonToString(JSONObject jsoned) {
	auto sink = new char[1024];
	return jsoned.jsonToString(sink);
}

string jsonToString(SinkType)(JSONObject jsoned, ref SinkType sink) {
	import std.conv : to;
	import std.string : format;
	import bc.string.format;

	// Convert to string
	size_t len = 0;
	size_t pos = 0;
	auto buff = writeToSink(sink, pos, "{");
	foreach (string key, JSONValue value ; jsoned) {
		switch (value.type) {
			case JSONType.Number:
				len = nogcFormatTo!(`"%s":%s,`)(buff, key, value.asNumber);
				break;
			case JSONType.String:
				len = nogcFormatTo!(`"%s":"%s",`)(buff, key, value.asString);
				break;
			case JSONType.Boolean:
				len = nogcFormatTo!(`"%s":%s,`)(buff, key, value.asBoolean);
				break;
			default:
				throw new Exception("Unexpected JSON type: %s".format(value.type));
		}

		pos += len;
		buff = sink[pos .. $];
	}

	// Remove trailing comma
	if (sink[pos-1 .. pos] == ",") {
		pos -= 1;
		buff = sink[pos .. $];
	}

	buff = writeToSink(sink, pos, "}");
	//print("!!!! jsoned: %s", sink[0 .. pos]);
	string stringed = cast(string) sink[0 .. pos];

	return stringed;
}

JSONObject stringToJson(string input) {
	import std.string : format;
	auto doc = New!JSONDocument(input);
	scope (exit) Delete(doc);

	// Copy the document root object
	auto root = doc.root;
	if (root.type == JSONType.Object) {
		auto jsoned = New!JSONObject();
		foreach (string key, JSONValue value ; root.asObject) {
			auto json_value = New!JSONValue();
			json_value.type = value.type;
			switch (value.type) {
				case JSONType.String:
					json_value.asString = value.asString.dup;
					break;
				case JSONType.Boolean:
					json_value.asBoolean = value.asBoolean;
					break;
				case JSONType.Number:
					json_value.asNumber = value.asNumber;
					break;
				default:
					throw new Exception("Unexpected JSON type: %s".format(value.type));
			}
			jsoned[key.dup] = json_value;
		}
		return jsoned;
	}

	return null;
}

unittest {
	import BDD;

	struct Dog {
		string name;
		bool is_bad;
		int age;
		float cuteness;
	}

	JSONObject jsoned = null;

	describe("json",
		before(delegate() {
			jsoned = null;
		}),
		after(delegate() {
			deleteJson(jsoned);
		}),
		it("Should convert JSON to string", delegate() {
			// Create the JSON object
			jsoned = New!JSONObject();

			auto name = New!JSONValue();
			name.type = JSONType.String;
			name.asString = "Rocky";
			jsoned["name"] = name;

			auto is_bad = New!JSONValue();
			is_bad.type = JSONType.Boolean;
			is_bad.asBoolean = true;
			jsoned["is_bad"] = is_bad;

			auto age = New!JSONValue();
			age.type = JSONType.Number;
			age.asNumber = 9;
			jsoned["age"] = age;

			auto cuteness = New!JSONValue();
			cuteness.type = JSONType.Number;
			cuteness.asNumber = 13.1f;
			jsoned["cuteness"] = cuteness;

			char[1024] sink = 0;
			string stringed = jsoned.jsonToString(sink);
			stringed.shouldEqual(`{"name":"Rocky","is_bad":true,"age":9,"cuteness":13.1}`);
		}),
		it("Should convert string to JSON", delegate() {
			// Create a dog in a JSON string
			string stringed = `{"name":"Rocky","is_bad":true,"age":9,"cuteness":13.1}`;

			// Convert the string to JSON
			jsoned = stringToJson(stringed);

			// Make sure the conversion was correct
			jsoned["name"].type.shouldEqual(JSONType.String);
			jsoned["name"].asString.shouldEqual("Rocky");

			jsoned["is_bad"].type.shouldEqual(JSONType.Boolean);
			jsoned["is_bad"].asBoolean.shouldEqual(true);

			jsoned["age"].type.shouldEqual(JSONType.Number);
			jsoned["age"].asNumber.shouldEqual(9);

			jsoned["cuteness"].type.shouldEqual(JSONType.Number);
			jsoned["cuteness"].asNumber.shouldEqual(13.1);
		}),
	);
}
