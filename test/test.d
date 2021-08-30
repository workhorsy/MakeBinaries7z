



unittest {
	import BDD;
	import make_binaries_7z;
	import std.array : replace;
	import std.file : dirEntries, SpanMode, isDir, isFile, remove, rmdirRecurse, exists, chdir, mkdir, getSize;

	describe("make-binaries-7z",
		before(delegate() {
			// Recreate test file dir
			if (exists("temp_test_files")) {
				rmdirRecurse("temp_test_files");
			}
			mkdir("temp_test_files");

			// Copy test files to test dir
			copyTree("test_data/", "temp_test_files/");
			chdir("temp_test_files");

			// Make sure the default files exists
			"test_data/aaa".exists.shouldEqual(true);
			"test_data/aaa/bbb".exists.shouldEqual(true);
			"test_data/aaa/bbb/ccc.zip".exists.shouldEqual(true);
			"test_data/aaa/bbb/xxx.zip".exists.shouldEqual(true);
			"test_data/aaa/bbb.txt".exists.shouldEqual(true);
			"test_data/aaa/bbb.zip".exists.shouldEqual(true);
		}),
		after(delegate() {
			chdir("..");
			if (exists("temp_test_files")) {
				rmdirRecurse("temp_test_files");
			}
		}),
		it("Should round trip files", delegate() {

			ulong original_size = "test_data/aaa/bbb/ccc.zip".getSize;

			// Recompress the test dir files
			recompressDir(".", true);
			"test_data/aaa/bbb/ccc.zip.7z".exists.shouldEqual(true);
			"test_data/aaa/bbb/ccc.zip".exists.shouldEqual(false);

			unRecompressDir(".", true);
			"test_data/aaa/bbb/ccc.zip".exists.shouldEqual(true);
			"test_data/aaa/bbb/ccc.zip.7z".exists.shouldEqual(false);

			//
			ulong new_size = "test_data/aaa/bbb/ccc.zip".getSize;
			new_size.shouldEqual(original_size);
		}),
		it("Should recompress files", delegate() {
			// Recompress the test dir files
			recompressDir(".", true);

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

// FIXME: This should not be needed
void main() {}
