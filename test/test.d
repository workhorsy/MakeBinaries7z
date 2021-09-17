// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/smol



unittest {
	import BDD;
	import helpers;
	import pack;
	import unpack;
	import std.file : dirEntries, SpanMode, isDir, isFile, remove, rmdirRecurse, exists, mkdir, getSize;

	describe("make-binaries-7z",
		before(delegate() {
			// Recreate test file dir
			if (exists("temp_test_files")) {
				rmdirRecurse("temp_test_files");
			}
			mkdir("temp_test_files");

			// Copy test files to test dir
			copyDirTree("test_data/", "temp_test_files/");
			chdir("temp_test_files");

			// Make sure the default files exists
			"test_data/aaa".exists.shouldEqual(true);
			"test_data/aaa/bbb".exists.shouldEqual(true);
			"test_data/aaa/bbb/ccc.zip".exists.shouldEqual(true);
			"test_data/aaa/bbb/xxx.zip".exists.shouldEqual(true);
			"test_data/aaa/bbb.txt".exists.shouldEqual(true);
			"test_data/aaa/bbb.zip".exists.shouldEqual(true);

			"test_data/aaa/formats/zzz.7z".exists.shouldEqual(true);
			"test_data/aaa/formats/zzz.txt.bz2".exists.shouldEqual(true);
			"test_data/aaa/formats/zzz.txt.gz".exists.shouldEqual(true);
			"test_data/aaa/formats/zzz.txt.xz".exists.shouldEqual(true);
			"test_data/aaa/formats/zzz.zip".exists.shouldEqual(true);
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
			packDir(".", true);
			"test_data/aaa/bbb/ccc.zip.zip.smol".exists.shouldEqual(true);
			"test_data/aaa/bbb/ccc.zip".exists.shouldEqual(false);

			unpackDir(".", true);
			"test_data/aaa/bbb/ccc.zip".exists.shouldEqual(true);
			"test_data/aaa/bbb/ccc.zip.zip.smol".exists.shouldEqual(false);

			//
			ulong new_size = "test_data/aaa/bbb/ccc.zip".getSize;
			new_size.shouldEqual(original_size);
		}),
		it("Should recompress files", delegate() {
			// Recompress the test dir files
			packDir(".", true);

			// Make sure the files have been recompressed
			"test_data/aaa".exists.shouldEqual(true);
			"test_data/aaa/bbb".exists.shouldEqual(true);
			"test_data/aaa/bbb/ccc.zip.zip.smol".exists.shouldEqual(true);
			"test_data/aaa/bbb/xxx.zip.zip.smol".exists.shouldEqual(true);
			"test_data/aaa/bbb.txt.bin.smol".exists.shouldEqual(true);
			"test_data/aaa/bbb.zip.zip.smol".exists.shouldEqual(true);

			"test_data/aaa/formats".exists.shouldEqual(true);
			"test_data/aaa/formats/zzz.7z".exists.shouldEqual(true);
			"test_data/aaa/formats/zzz.txt.bz2.bzip2.smol".exists.shouldEqual(true);
			"test_data/aaa/formats/zzz.txt.gz.gzip.smol".exists.shouldEqual(true);
			"test_data/aaa/formats/zzz.txt.xz".exists.shouldEqual(true);
			"test_data/aaa/formats/zzz.zip.zip.smol".exists.shouldEqual(true);
		}),
	);
}

// FIXME: This should not be needed
void main() {}
