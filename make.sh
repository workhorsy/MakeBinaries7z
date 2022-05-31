#!/bin/bash
set -e
set +x


# Get the OS and file extension
if [[ "$OSTYPE" == "linux"* ]]; then
	OS="linux"
	DC="dmd"
	EXE=""
elif [ "$OSTYPE" == "msys" ] || [ "$OSTYPE" == "win32" ]; then
	OS="windows"
	source ~/dlang/ldc-1.26.0/activate
	DC="ldc2"
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
	./build/smol --pack temp
	./build/smol --unpack temp
	set +x
}

exampleXXX() {
	set -x
	dub build --compiler=$DC --build=debug
	rm -f -rf temp
	cp -r templates_backup temp
	#cp -r test_data temp
	./build/smol --pack temp
	#./build/smol --unpack temp
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
	echo "./make.sh build - Build smol"
	echo "./make.sh test - Run test suite"
	echo "./make.sh example - Build and run example"
	echo "./make.sh clean - Remove generated files"
fi
