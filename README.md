# smol

Recursively re compresses directories with lzma2 compression:

* Requires 7zip
* Re compresses Zip, BZip2, and GZip to lzma2
* Files inside of compressed files are also re compressed
* Directories that start with a "." are ignored
* All other files are compressed using lzma2
* After compression, files are broken into 10 MB chunks
* --pack re compresses all files, while --unpack changes all files back to normal
