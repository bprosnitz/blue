library vom;

import 'package:benchmark_harness/benchmark_harness.dart';

import 'dart:core';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:collection';

import '../../test/test_util/test_util.dart' as test_util;

import 'package:quiver/core.dart' as quiver_core;
import 'package:quiver/collection.dart' as quiver_collection;
import 'package:quiver/streams.dart' as quiver_streams;
import '../../lib/src/vdl/vdl.dart' as vdl;
import '../../lib/src/collection/collection.dart' as collection;

part '../../lib/src/vom/exceptions.part.dart';
part '../../lib/src/vom/byte_buffer_writer.part.dart';
part '../../lib/src/vom/low_level_vom_writer.part.dart';
part '../../lib/src/vom/byte_buffer_reader.part.dart';
part '../../lib/src/vom/low_level_vom_reader.part.dart';
part '../../lib/src/vom/partial_type.part.dart';
part '../../lib/src/vom/wiretypes.part.dart';
part '../../lib/src/vom/message.part.dart';
part '../../lib/src/vom/type_definition_decoder.part.dart';
part '../../lib/src/vom/decoder_type_cache.part.dart';

part '../../test/vom/type_def_tests.part.dart';

void main() {
  new DecodeTypeCacheBuildPrimitiveBenchmark().report();
  new DecodeTypeCacheBuildDependentTypeBenchmark().report();
  new DecodeTypeCacheHitBenchmark().report();
}

// Benchmark building and caching an unseen named primitive type.
class DecodeTypeCacheBuildPrimitiveBenchmark extends BenchmarkBase {
  DecodeTypeCacheBuildPrimitiveBenchmark() :
    super('decode type cache miss with named primitive type - v1');

  StreamController<VomTypeMessage> controller;
  TypeDefTestCase namedTestCase;
  _DecoderTypeCache cache;

  static int last_id = 100;

  void setup() {
    namedTestCase = createValidTestCases()['named'];
    controller = new StreamController<VomTypeMessage>();
    cache = new _DecoderTypeCache(controller.stream);
  }

  Future run() async {
    int type_id = last_id;
    last_id++;

    VomTypeMessage msg = new VomTypeMessage(type_id,
      namedTestCase.wireDefType, namedTestCase.bytes);
    controller.add(msg);
    await cache[type_id];
  }
}

// Benchmark building and caching an type that involves waiting for dependencies.
class DecodeTypeCacheBuildDependentTypeBenchmark extends BenchmarkBase {
  DecodeTypeCacheBuildDependentTypeBenchmark() :
    super('decode type cache miss with type with dependencies - v1');

  List<int> dependentBytes, dependencyBytes;
  StreamController<VomTypeMessage> controller;
  _DecoderTypeCache cache;

  static int last_id = 100;

  void setup() {
    String depChainDependent =
      '01' //                   Index                              1 [main.wireOptional.Elem]
      '6f' //                   PrimValue                         111 [uint]
      'e1'; //                   Control                          End [main.wireOptional END]
    String depChainDependency =
      '00' //                   Index                              0 [main.wireSet.Name]
      '05' //                   ByteLen                            5 [string len]
      '616e616d65' //           PrimValue                    'aname' [string]
      '01' //                   Index                              1 [main.wireSet.Key]
      '05' //                   PrimValue                         5 [uint]
      'e1'; //                   Control                          End [main.wireSet END]
    dependentBytes = test_util.hex2Bin(depChainDependent);
    dependencyBytes = test_util.hex2Bin(depChainDependency);

    controller = new StreamController<VomTypeMessage>();
    cache = new _DecoderTypeCache(controller.stream);
  }

  Future run() async {
    int first_type_id = last_id;
    int second_type_id = last_id + 1;
    last_id += 2;

    VomTypeMessage firstMsg = new VomTypeMessage(first_type_id,
      _WireOptional.vdlType, dependentBytes);
    controller.add(firstMsg);
    VomTypeMessage secondMsg = new VomTypeMessage(second_type_id,
      _WireSet.vdlType, dependencyBytes);
    controller.add(secondMsg);
    await cache[first_type_id];
  }
}

// Benchmark referencing already seen types in the decode type cache.
class DecodeTypeCacheHitBenchmark extends BenchmarkBase {
  DecodeTypeCacheHitBenchmark() : super('decode type cache hit - v1');

  static const int TYPE_ID = 100;
  _DecoderTypeCache cache;

  Stream<VomTypeMessage> createMsgStream() async* {
    var namedTestCase = createValidTestCases()['named'];
    yield new VomTypeMessage(TYPE_ID, namedTestCase.wireDefType,
    namedTestCase.bytes);
  }

  void setup() {
    cache = new _DecoderTypeCache(createMsgStream());
    cache[TYPE_ID];
  }

  Future run() async {
    await cache[TYPE_ID];
  }
}
