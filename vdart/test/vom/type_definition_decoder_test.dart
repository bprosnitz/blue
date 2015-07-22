library vom;

import 'package:test/test.dart';

import 'dart:core';
import 'dart:typed_data';
import 'dart:convert';

import '../test_util/test_util.dart' as test_util;

import 'package:quiver/core.dart' as quiver_core;
import 'package:quiver/collection.dart' as quiver_collection;
import '../../lib/src/vdl/vdl.dart' as vdl;

part '../../lib/src/vom/exceptions.part.dart';
part '../../lib/src/vom/byte_buffer_writer.part.dart';
part '../../lib/src/vom/low_level_vom_writer.part.dart';
part '../../lib/src/vom/byte_buffer_reader.part.dart';
part '../../lib/src/vom/low_level_vom_reader.part.dart';
part '../../lib/src/vom/partial_type.part.dart';
part '../../lib/src/vom/wiretypes.part.dart';
part '../../lib/src/vom/message.part.dart';
part '../../lib/src/vom/type_definition_decoder.part.dart';

part 'type_def_tests.part.dart';

void main() {
  group('_PartialType equality and hash code', () {
    test('same named', () {
      var first = new _PartialVdlType.namedType('AName', 4);
      var second = new _PartialVdlType.namedType('AName', 4);
      expect(first, isNot(same(second)));
      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
    });
    test('different named', () {
      var first = new _PartialVdlType.namedType('AName', 4);
      var second = new _PartialVdlType.namedType('AName', 5);
      expect(first, isNot(same(second)));
      expect(first, isNot(equals(second)));
      expect(first.hashCode, isNot(equals(second.hashCode)));
    });
    test('same enum labels', () {
      var first = new _PartialVdlType.enumType('enum', ['A', 'B']);
      var second = new _PartialVdlType.enumType('enum', ['A', 'B']);
      expect(first, isNot(same(second)));
      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
    });
    test('different enum labels', () {
      var first = new _PartialVdlType.enumType('enum', ['A', 'B']);
      var second = new _PartialVdlType.enumType('enum', ['A', 'C']);
      expect(first, isNot(same(second)));
      expect(first, isNot(equals(second)));
      expect(first.hashCode, isNot(equals(second.hashCode)));
    });
    test('same struct fields', () {
      var first = new _PartialVdlType.structType('enum', [new _PartialVdlField('A', 5), new _PartialVdlField('B', 6)]);
      var second = new _PartialVdlType.structType('enum', [new _PartialVdlField('A', 5), new _PartialVdlField('B', 6)]);
      expect(first, isNot(same(second)));
      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
    });
    test('different struct fields', () {
      var first = new _PartialVdlType.structType('enum', [new _PartialVdlField('A', 5), new _PartialVdlField('B', 6)]);
      var second = new _PartialVdlType.structType('enum', [new _PartialVdlField('A', 5), new _PartialVdlField('B', 4)]);
      expect(first, isNot(same(second)));
      expect(first, isNot(equals(second)));
      expect(first.hashCode, isNot(equals(second.hashCode)));
    });
  });
  group('type definition decoding', () {
    group('valid', () {
      createValidTestCases().forEach((String testName, TypeDefTestCase testCase) {
        test(testName, () {
          _PartialVdlType pt = _TypeDefinitionDecoder.decodeTypeMessage(testCase.msg);
          expect(pt, equals(testCase.expectedOutput));
        });
      });
    });
    group('invalid', () {
      createInvalidTestCases().forEach((String testName, TypeDefTestCase testCase) {
        test(testName, () {
          expect(() => _TypeDefinitionDecoder.decodeTypeMessage(testCase.msg),
            throwsA(new test_util.isInstanceOfType(testCase.expectedException)));
        });
      });
    });
  });
}
