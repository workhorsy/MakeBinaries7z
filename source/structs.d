// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/MakeBinaries7z

import global;
import helpers;
import json;

import std.traits : isSomeString, isNumeric, isBoolean;
import dlib.serialization.json : JSONObject, JSONValue, JSONType;

JSONObject structToJson(T)(T thing) {
	import std.string : format;

	auto jsoned = New!JSONObject();
	auto type_info = New!JSONValue();
	type_info.type = JSONType.String;
	type_info.asString = T.stringof;
	jsoned["type"] = type_info;
	foreach (member; __traits(allMembers, T)) {
		auto value = mixin("thing.%s".format(member));
		auto json_value = New!JSONValue();
		static if (isSomeString!(typeof(value))) {
			json_value.type = JSONType.String;
			json_value.asString = value;
		} else static if (isNumeric!(typeof(value))) {
			json_value.type = JSONType.Number;
			json_value.asNumber = cast(double) value;
		} else static if (isBoolean!(typeof(value))) {
			json_value.type = JSONType.Boolean;
			json_value.asBoolean = value;
		} else {
			static assert(0, `Unexpected JSON member type`);
		}
		jsoned[member] = json_value;
	}
	return jsoned;
}

T jsonToStruct(T)(JSONObject jsoned) {
	import std.string : format;

	T thing;
	foreach (member; __traits(allMembers, T)) {
		auto value = mixin("thing.%s".format(member));
		static if (isSomeString!(typeof(value))) {
			mixin(`thing.%s`.format(member)) = jsoned[member].asString;
		} else static if (isNumeric!(typeof(value))) {
			static if (is(typeof(value) == int)) {
				mixin(`thing.%s`.format(member)) = cast(int) jsoned[member].asNumber;
			} else static if (is(typeof(value) == size_t)) {
				mixin(`thing.%s`.format(member)) = cast(size_t) jsoned[member].asNumber;
			} else static if (is(typeof(value) == float)) {
				mixin(`thing.%s`.format(member)) = cast(float) jsoned[member].asNumber;
			} else static if (is(typeof(value) == double)) {
				mixin(`thing.%s`.format(member)) = cast(double) jsoned[member].asNumber;
			} else {
				assert(0, "Unexpected type %s".format(typeof(value)));
			}
		} else static if (isBoolean!(typeof(value))) {
			mixin(`thing.%s`.format(member)) = jsoned[member].asBoolean;
		} else {
			assert(0, "Unexpected type %s".format(typeof(value)));
		}
	}

	return thing;
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

	describe("structs",
		before(delegate() {
			jsoned = null;
		}),
		after(delegate() {
			deleteJson(jsoned);
		}),
		it("Should convert struct to JSON", delegate() {
			// Create the dog object
			Dog dog = Dog("Rover", true, 5, 7.0f);

			// Convert the dog to JSON
			jsoned = dog.structToJson();

			// Make sure the conversion was correct
			jsoned["name"].type.shouldEqual(JSONType.String);
			jsoned["name"].asString.shouldEqual("Rover");

			jsoned["is_bad"].type.shouldEqual(JSONType.Boolean);
			jsoned["is_bad"].asBoolean.shouldEqual(true);

			jsoned["age"].type.shouldEqual(JSONType.Number);
			jsoned["age"].asNumber.shouldEqual(5);

			jsoned["cuteness"].type.shouldEqual(JSONType.Number);
			jsoned["cuteness"].asNumber.shouldEqual(7.0f);
		}),
		it("Should convert JSON to struct", delegate() {
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

			// Convert the JSON object into a dog
			Dog dog = jsoned.jsonToStruct!Dog();

			// Make sure the conversion was correct
			dog.name.shouldEqual("Rocky");
			dog.is_bad.shouldEqual(true);
			dog.age.shouldEqual(9);
			dog.cuteness.shouldEqual(13.1f);
		}),
	);
}
