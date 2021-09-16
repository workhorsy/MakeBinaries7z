# smol

Recursively re compresses directories with lzma2 compression:

* Requires 7zip
* Files compressed with Zip are re compressed, including Zip files inside Zip files et cetera
* All other files are compressed using lzma2
* After compression, files are broken into 10 MB chunks
* --pack re compressed all files, while --unpack changes all files back to normal
