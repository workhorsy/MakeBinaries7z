// Copyright (c) 2021-2022 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recursively re compresses directories with lzma2 compression
// https://github.com/workhorsy/smol



enum FileType {
	Zip,
	GZip,
	BZip2,
	SevenZip,
	XZ,
	Binary,
}

// https://en.wikipedia.org/wiki/List_of_file_signatures
FileType getFileType(string file_name) {
	import std.stdio : File;

	// Read first 10 bytes of file
	char[10] header = 0;
	{
		auto f = File(file_name, "rb");
		f.rawRead(header);
	}

	// Return file type based on magic numbers
	if (header[0 .. 4] == [0x50, 0x4B, 0x03, 0x04]) {
		return FileType.Zip;
	} else if (header[0 .. 2] == [0x1F, 0x8B]) {
		return FileType.GZip;
	} else if (header[0 .. 3] == [0x42, 0x5A, 0x68]) {
		return FileType.BZip2;
	} else if (header[0 .. 6] == [0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C]) {
		return FileType.SevenZip;
	} else if (header[0 .. 6] == [0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00]) {
		return FileType.XZ;
	} else {
		return FileType.Binary;
	}
}
