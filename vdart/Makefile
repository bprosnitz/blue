# Get the packages used by the dart project, according to pubspec.yaml
get-packages: pubspec.yaml
	pub get

SRC_FILES := $(shell find lib/src -name *.dart ! -name *.part.dart)
TEST_FILES := $(shell find test -name *.dart ! -name *.part.dart)

# Check that the dart-style is being met. Note: Comments are ignored when
# checking whitespace.
check-fmt:
	dartfmt -n $(SRC_FILES) $(TEST_FILES)

# Lint src and test files with dartanalyzer. This step takes a few seconds, so
# it may be better to rely on the dart-sublime plugin.
lint: get-packages
	dartanalyzer $(SRC_FILES) $(TEST_FILES)

# Run benchmarks
benchmark: lint
	dart benchmark/vom/decoder_type_cache_benchmark.dart
	dart benchmark/vom/type_definition_decoder_benchmark.dart
	dart benchmark/vom/low_level_vom_benchmark.dart
	dart benchmark/vdl/type_building_benchmark.dart
	dart benchmark/vdl/type_reflect_benchmark.dart
	dart benchmark/vdl/type_benchmark.dart
	dart benchmark/vdl/value_benchmark.dart

# Run the tests with dartium.
test: lint
	pub run --mode=debug test

# Run the tests with chrome (and dart2js). Slower: this involves a compile step.
test-js: lint
	pub run --mode=debug test -p chrome

clean:
	rm -rf packages

.PHONY: test
.PHONY: test-js
.PHONY: benchmark
