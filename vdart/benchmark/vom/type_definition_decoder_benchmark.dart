library vom;

import 'dart:core';
import 'dart:collection';
import 'dart:convert';
import 'dart:mirrors' as mirrors;
import 'dart:typed_data' as typed_data;

import '../../test/test_util/test_util.dart' as test_util;

import '../../lib/src/collection/collection.dart' as collection;
import '../../lib/src/vdl/vdl.dart' as vdl;

import 'package:benchmark_harness/benchmark_harness.dart';

part '../../lib/src/vom/exceptions.part.dart';
part '../../lib/src/vom/byte_buffer_writer.part.dart';
part '../../lib/src/vom/low_level_vom_writer.part.dart';
part '../../lib/src/vom/byte_buffer_reader.part.dart';
part '../../lib/src/vom/low_level_vom_reader.part.dart';
part '../../lib/src/vom/partial_type.part.dart';
part '../../lib/src/vom/wiretypes.part.dart';
part '../../lib/src/vom/message.part.dart';
part '../../lib/src/vom/type_definition_decoder.part.dart';

part '../../test/vom/type_def_tests.part.dart';

var validTestCases = createValidTestCases();

void main() {
  new DecodeTypeDefinitionBenchmark('named').report();
  new DecodeTypeDefinitionBenchmark('enum').report();
  new DecodeTypeDefinitionBenchmark('array').report();
  new DecodeTypeDefinitionBenchmark('struct').report();
}

// Test decoding type definition bytes with the type definition decoder.
class DecodeTypeDefinitionBenchmark extends BenchmarkBase {
  final VomTypeMessage msg;
  DecodeTypeDefinitionBenchmark(String testName) :
    super("type definition decoding - ${testName} - v1"),
    // createValidTestCases is defined in type_def_tests.part.dart
    msg = validTestCases[testName].msg;

  void run() {
      _TypeDefinitionDecoder.decodeTypeMessage(msg);
  }
}
