#!/bin/bash
set -e
set +x

# Get the D compiler
if [ "$OSTYPE" == "msys" ] || [ "$OSTYPE" == "win32" ]; then
	source ~/dlang/ldc-1.25.1/activate
fi
DC="dmd"

# Get the OS and file extension
if [[ "$OSTYPE" == "linux"* ]]; then
	OS="linux"
	EXE=""
elif [ "$OSTYPE" == "msys" ] || [ "$OSTYPE" == "win32" ]; then
	OS="windows"
	EXE=".exe"
else
	echo "Unknown OS: $OSTYPE"
	exit
fi

clean() {
	set -x
	rm -f -rf temp_test_files
	rm -f -rf .dub/
	rm -f dub.selections.json
	rm -f *.exe
	rm -f -rf build/
	set +x
}

test() {
	set -x
	dub test --compiler=$DC
	set +x
}

build() {
	set -x
	dub build --compiler=$DC --build=debug
	set +x
}

example() {
	set -x
	dub build --compiler=$DC --build=debug
	rm -f -rf temp
	#cp -r templates temp
	cp -r test_data temp
	./build/make_binaries_7z --pack temp
	./build/make_binaries_7z --unpack temp
	set +x
}

exampleXXX() {
	set -x
	dub build --compiler=$DC --build=debug
	rm -f -rf temp
	cp -r templates_backup temp
	#cp -r test_data temp
	./build/make_binaries_7z.exe --pack temp
	#./build/make_binaries_7z.exe --unpack temp
	set +x
}

if [[ "$1" == "build" ]]; then
	build
elif [[ "$1" == "test" ]]; then
	test
elif [[ "$1" == "example" ]]; then
	example
elif [[ "$1" == "clean" ]]; then
	clean
else
	echo "./make.sh build - build the game"
	echo "./make.sh clean - remove generated files"
fi
