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
	rm -f -rf temp_test_data
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
	dub build --compiler=$DC
	set +x
}

example() {
	set -x
	dub build --compiler=$DC
	rm -f -rf temp_test_data
	cp -r test_data temp_test_data
	./build/make_binaries_7z.exe --pack temp_test_data
	./build/make_binaries_7z.exe --unpack temp_test_data
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
