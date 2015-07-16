# Get the packages used by the dart project, according to pubspec.yaml
get-packages:
	pub get

SRC_FILES := $(shell find lib/src -name *.dart ! -name *.part.dart)
TEST_FILES := $(shell find test -name *.dart ! -name *.part.dart)

# Check that the dart-style is being met. Note: Comments are ignored when
# checking whitespace.
check-fmt:
	dartfmt -n $(SRC_FILES) $(TEST_FILES)

# Lint src and test files with dartanalyzer. This step takes a few seconds, so
# it may be better to rely on the dart-sublime plugin.
lint:
	dartanalyzer $(SRC_FILES) $(TEST_FILES)

# Run benchmarks
benchmark:
	pub run lib/src/vom/low_level_vom_benchmark.dart
	pub run lib/src/vdl/type_building_benchmark.dart
	pub run lib/src/vdl/type_reflect_benchmark.dart

# Run the tests with dartium.
runtest: get-packages lint
	pub run --mode=debug test

# Run the tests with chrome (and dart2js). Slower: this involves a compile step.
runtest-js: get-packages lint
	pub run --mode=debug test -p chrome

clean:
	rm -rf packages
