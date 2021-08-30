



unittest {
	import make_binaries_7z;
	import BDD;
	import std.array : replace;
	import std.file : dirEntries, SpanMode, isDir, isFile, remove, rmdirRecurse, exists, chdir, mkdir;

	describe("make-binaries-7z",
		before(delegate() {
			// Recreate test file dir
			if (exists("temp_test_files")) {
				rmdirRecurse("temp_test_files");
			}
			mkdir("temp_test_files");

			// Copy test files to test dir
			copyTree("test_data/", "temp_test_files/");
		}),
		after(delegate() {
			if (exists("temp_test_files")) {
				rmdirRecurse("temp_test_files");
			}
		}),
		it("Should recompress files", delegate() {
			chdir("temp_test_files");

			// Make sure the default files exists
			"test_data/aaa".exists.shouldEqual(true);
			"test_data/aaa/bbb".exists.shouldEqual(true);
			"test_data/aaa/bbb/ccc.zip".exists.shouldEqual(true);
			"test_data/aaa/bbb/xxx.zip".exists.shouldEqual(true);
			"test_data/aaa/bbb.txt".exists.shouldEqual(true);
			"test_data/aaa/bbb.zip".exists.shouldEqual(true);

			// Recompress the test dir files
			recompressDir(".", true);
			//chdir("..");

			// Make sure the files have been recompressed
			"test_data/aaa".exists.shouldEqual(true);
			"test_data/aaa/bbb".exists.shouldEqual(true);
			"test_data/aaa/bbb/ccc.zip.7z".exists.shouldEqual(true);
			"test_data/aaa/bbb/xxx.zip.7z".exists.shouldEqual(true);
			"test_data/aaa/bbb.txt.7z".exists.shouldEqual(true);
			"test_data/aaa/bbb.zip.7z".exists.shouldEqual(true);
		}),
	);
}

void copyTree(string from_path, string to_path) {
	import std.process : execute;
	import std.stdio : stderr;

	string[] command = ["cp", "-r", from_path, to_path];
	//prints("Running command: %s", command);
	auto exe = execute(command);
	if (exe.status != 0) {
		stderr.writefln("%s", exe.output); stderr.flush();
	}
	assert(exe.status == 0);
}
