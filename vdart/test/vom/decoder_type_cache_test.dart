library vom;

import 'package:test/test.dart';

import 'dart:core';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:collection';

import '../test_util/test_util.dart' as test_util;

import 'package:quiver/core.dart' as quiver_core;
import 'package:quiver/collection.dart' as quiver_collection;
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

part 'type_def_tests.part.dart';

void main() {
  group('decoder type cache', () {
    group('building and caching types', () {
      group('valid', () {
        for (var testCase in getTestCases()){
          test(testCase.name, () {
            Stream<VomTypeMessage> typeStream = new Stream.fromIterable(testCase.typeMessages);
            _DecoderTypeCache cache = new _DecoderTypeCache(typeStream);
            cache.finishedReading.then((ignoreValue) {
              expect(cache._typeDefinitions.length, equals(testCase.expectedTypes.length));
              testCase.expectedTypes.forEach((int typeId, vdl.VdlType expectedType) {
                expect(cache[typeId], completion(equals(expectedType)));
              });
            });
            expect(cache.finishedReading, completes);
          });
        };
      });
      group('invalid', () {
        createInvalidTestCases().forEach((String testName, TypeDefTestCase invalidCase) {
          test(testName, () {
            int somewhatArbitraryNumber = 46;
            var msg = new VomTypeMessage(somewhatArbitraryNumber,
              invalidCase.wireDefType, invalidCase.bytes);
            Stream<VomTypeMessage> typeStream = new Stream.fromIterable([msg]);
            _DecoderTypeCache cache = new _DecoderTypeCache(typeStream);
            expect(cache.finishedReading, throwsA(new test_util.isInstanceOfType(
              invalidCase.expectedException)));
          });
        });
        test('duplicate type id', () {
          // Duplicate type definitions should keep the first value.
          // TODO(bprosnitz) Should this throw an exception?
          String firstDupHex =
            '00' //                   Index                              0 [main.wireNamed.Name]
            '05' //                   ByteLen                            5 [string len]
            '616e616d65' //           PrimValue                    'aname' [string]
            '01' //                   Index                              1 [main.wireNamed.Base]
            '05' //                   PrimValue                         5 [uint]
            'e1'; //                   Control                          End [main.wireNamed END]
          String secondDupHex =
            '00' //                   Index                              0 [main.wireNamed.Name]
            '05' //                   ByteLen                            5 [string len]
            '616e616d65' //           PrimValue                    'aname' [string]
            '01' //                   Index                              1 [main.wireNamed.Base]
            '05' //                   PrimValue                         9 [uint]
            'e1'; //                   Control                          End [main.wireNamed END]
          VomTypeMessage firstDupMessage = new VomTypeMessage(41, _WireNamed.vdlType,
            test_util.hex2Bin(firstDupHex));
          VomTypeMessage secondDupMessage = new VomTypeMessage(41, _WireNamed.vdlType,
            test_util.hex2Bin(secondDupHex));
          Stream<VomTypeMessage> typeStream = new Stream.fromIterable([firstDupMessage, secondDupMessage]);
          _DecoderTypeCache cache = new _DecoderTypeCache(typeStream);
          expect(cache.finishedReading, throwsA(new isInstanceOf<VomDecodeException>()));
        });
      });
    });
    test('waiting for delayed type message', () {
      var completer = new Completer<VomTypeMessage>();
      _DecoderTypeCache cache = new _DecoderTypeCache(
        new Stream.fromFuture(completer.future));
      int typeId = 76;
      Future<vdl.VdlType> outType = cache[typeId];

      var example = createValidTestCases()['named'];
      var msg = new VomTypeMessage(typeId, example.wireDefType, example.bytes);
      completer.complete(msg);

      expect(outType, completion(equals(example.expectedFinalType)));
    });
  });
}

class DecoderTypeCacheTest {
  final String name;
  final List<VomTypeMessage> typeMessages;
  final Map<int, vdl.VdlType> expectedTypes; // .. and only these types.
  final Type expectedException;

  DecoderTypeCacheTest(this.name, this.typeMessages, this.expectedTypes) : expectedException = null;
  DecoderTypeCacheTest.failure(this.name, this.typeMessages, this.expectedException) : expectedTypes = null;
}

List<DecoderTypeCacheTest> getTestCases() {
  var testCases = new List<DecoderTypeCacheTest>();

  // Single message test cases:
  createValidTestCases().forEach((String testName, TypeDefTestCase validCase) {
    var msg = new VomTypeMessage(FIRST_NEW_VOM_ID, validCase.wireDefType, validCase.bytes);
    var expectedTypes = new Map<int, vdl.VdlType>();
    expectedTypes[FIRST_NEW_VOM_ID] = validCase.expectedFinalType;
    testCases.add(new DecoderTypeCacheTest(
      'single item ${testName}', [msg], expectedTypes));
  });

  // Test receiving messages before or after their dependencies.
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
  VomTypeMessage depMsgDependent = new VomTypeMessage(222,
    _WireOptional.vdlType, test_util.hex2Bin(depChainDependent));
  VomTypeMessage depMsgDependency = new VomTypeMessage(111,
    _WireSet.vdlType, test_util.hex2Bin(depChainDependency));
  var depTypeDependencyPt = new vdl.VdlPendingType()
    ..name = 'aname'
    ..kind = vdl.VdlKind.Set
    ..key = vdl.VdlTypes.Uint32;
  var depTypeDependent = (new vdl.VdlPendingType()
    ..kind = vdl.VdlKind.Optional
    ..elem = depTypeDependencyPt).build();
  var depTypeDependency = depTypeDependencyPt.build();
  testCases.add(new DecoderTypeCacheTest('in order dependencies',
    [depMsgDependency, depMsgDependent], {111: depTypeDependency, 222: depTypeDependent}));
  testCases.add(new DecoderTypeCacheTest('out of order dependencies',
    [depMsgDependent, depMsgDependency], {111: depTypeDependency, 222: depTypeDependent}));

  // Indirect recursion (direct recursion is in single message tests).
  String indirectRecursionHexA =
    '01' //                   Index                              1 [main.wireOptional.Elem]
    '6f' //                   PrimValue                         111 [uint]
    'e1'; //                   Control                          End [main.wireOptional END]
  String indirectRecursionHexB =
    '00' //                   Index                              0 [main.wireSet.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireSet.Key]
    '40' //                   PrimValue                         64 [uint]
    'e1'; //                   Control                          End [main.wireSet END]
  VomTypeMessage indirectRecursionMsgA = new VomTypeMessage(64,
    _WireOptional.vdlType, test_util.hex2Bin(indirectRecursionHexA));
  VomTypeMessage indirectRecursionMsgB = new VomTypeMessage(111,
    _WireSet.vdlType, test_util.hex2Bin(indirectRecursionHexB));
  var indirectRecursionPtA = new vdl.VdlPendingType()
    ..kind = vdl.VdlKind.Optional;
  var indirectRecursionPtB = new vdl.VdlPendingType()
    ..name = 'aname'
    ..kind = vdl.VdlKind.Set
    ..key = indirectRecursionPtA;
  indirectRecursionPtA.elem = indirectRecursionPtB;
  testCases.add(new DecoderTypeCacheTest('indirect recursion',
    [indirectRecursionMsgA, indirectRecursionMsgB],
    {64: indirectRecursionPtA.build(), 111: indirectRecursionPtB.build()}));

  return testCases;
}
