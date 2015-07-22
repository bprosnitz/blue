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
      var validTestCases = createTestCases().where((tc) => tc.expectedException == null);
      for (TypeDefinitionDecodeTestCase testCase in validTestCases) {
        test(testCase.name, () {
          VomTypeMessage msg = new VomTypeMessage(testCase.defType,
            test_util.hex2Bin(testCase.inputHex));
          _PartialVdlType pt = _TypeDefinitionDecoder.decodeTypeMessage(msg);
          expect(pt, equals(testCase.expectedOutput));
        });
      }
    });
    group('invalid', () {
      var invalidTestCases = createTestCases().where((tc) => tc.expectedException != null);
      for (TypeDefinitionDecodeTestCase testCase in invalidTestCases) {
        test(testCase.name, () {
          VomTypeMessage msg = new VomTypeMessage(testCase.defType,
            test_util.hex2Bin(testCase.inputHex));
          expect(() => _TypeDefinitionDecoder.decodeTypeMessage(msg),
            throwsA(new test_util.isInstanceOfType(testCase.expectedException)));
        });
      };
    });
  });
}

class TypeDefinitionDecodeTestCase {
  String name;
  vdl.VdlType defType;
  String inputHex;
  _PartialVdlType expectedOutput;
  Type expectedException;

  TypeDefinitionDecodeTestCase(this.name, this.defType, this.inputHex, this.expectedOutput);
  TypeDefinitionDecodeTestCase.failure(this.name, this.defType, this.inputHex, this.expectedException);
}

List<TypeDefinitionDecodeTestCase> createTestCases() {
  var testCases = <TypeDefinitionDecodeTestCase>[];

  String wireNamedHex =
    '00' //                   Index                              0 [main.wireNamed.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireNamed.Base]
    '58' //                   PrimValue                         88 [uint]
    'e1'; //                   Control                          End [main.wireNamed END]
  _PartialVdlType wireNamedPt = new _PartialVdlType.namedType('aname', 88);
  testCases.add(new TypeDefinitionDecodeTestCase('named', _WireNamed.vdlType, wireNamedHex, wireNamedPt));

  String enumHex =
    '00' //                   Index                              0 [main.wireEnum.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireEnum.Labels]
    '02' //                   ValueLen                           2 [list len]
    '01' //                   ByteLen                            1 [string len]
    '41' //                   PrimValue                        'A' [string]
    '02' //                   ByteLen                            2 [string len]
    '4242' //                 PrimValue                       'BB' [string]
    'e1'; //                   Control                          End [main.wireEnum END]
    _PartialVdlType enumPt = new _PartialVdlType.enumType('aname', <String>['A', 'BB']);
    testCases.add(new TypeDefinitionDecodeTestCase('enum', _WireEnum.vdlType, enumHex, enumPt));

  String arrayHex =
    '00' //                   Index                              0 [main.wireArray.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireArray.Elem]
    '58' //                   PrimValue                         88 [uint]
    '02' //                   Index                              2 [main.wireArray.Len]
    '0b' //                   PrimValue                         11 [uint]
    'e1'; //                   Control                          End [main.wireArray END]
  _PartialVdlType arrayPt = new _PartialVdlType.arrayType('aname', 88, 11);
  testCases.add(new TypeDefinitionDecodeTestCase('array', _WireArray.vdlType, arrayHex, arrayPt));

  String listHex =
    '00' //                   Index                              0 [main.wireList.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireList.Elem]
    '58' //                   PrimValue                         88 [uint]
    'e1'; //                   Control                          End [main.wireList END]
  _PartialVdlType listPt = new _PartialVdlType.listType('aname', 88);
  testCases.add(new TypeDefinitionDecodeTestCase('list', _WireList.vdlType, listHex, listPt));

  String setHex =
    '00' //                   Index                              0 [main.wireSet.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireSet.Key]
    '58' //                   PrimValue                         88 [uint]
    'e1'; //                   Control                          End [main.wireSet END]
  _PartialVdlType setPt = new _PartialVdlType.setType('aname', 88);
  testCases.add(new TypeDefinitionDecodeTestCase('set', _WireSet.vdlType, setHex, setPt));

  String mapHex =
    '00' //                   Index                              0 [main.wireMap.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireMap.Key]
    '58' //                   PrimValue                         88 [uint]
    '02' //                   Index                              2 [main.wireMap.Elem]
    '63' //                   PrimValue                         99 [uint]
    'e1'; //                   Control                          End [main.wireMap END]
  _PartialVdlType mapPt = new _PartialVdlType.mapType('aname', 88, 99);
  testCases.add(new TypeDefinitionDecodeTestCase('map', _WireMap.vdlType, mapHex, mapPt));

  String unionStructHex =
    '00' //                   Index                              0 [main.wireStruct.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireStruct.Fields]
    '02' //                   ValueLen                           2 [list len]
    '00' //                   Index                              0 [main.wireField.Name]
    '01' //                   ByteLen                            1 [string len]
    '41' //                   PrimValue                        'A' [string]
    '01' //                   Index                              1 [main.wireField.Type]
    '58' //                   PrimValue                         88 [uint]
    'e1' //                   Control                          End [main.wireField END]
    '00' //                   Index                              0 [main.wireField.Name]
    '01' //                   ByteLen                            1 [string len]
    '42' //                   PrimValue                        'B' [string]
    '01' //                   Index                              1 [main.wireField.Type]
    '63' //                   PrimValue                         99 [uint]
    'e1' //                   Control                          End [main.wireField END]
    'e1'; //                   Control                          End [main.wireStruct END]
  _PartialVdlType structPt = new _PartialVdlType.structType('aname', <_PartialVdlField>[new _PartialVdlField('A', 88), new _PartialVdlField('B', 99)]);
  testCases.add(new TypeDefinitionDecodeTestCase('struct', _WireStruct.vdlType, unionStructHex, structPt));
  _PartialVdlType unionPt = new _PartialVdlType.unionType('aname', <_PartialVdlField>[new _PartialVdlField('A', 88), new _PartialVdlField('B', 99)]);
  testCases.add(new TypeDefinitionDecodeTestCase('union', _WireUnion.vdlType, unionStructHex, unionPt));


  String optionalHex =
    '00' //                   Index                              0 [main.wireOptional.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireOptional.Elem]
    '58' //                   PrimValue                         88 [uint]
    'e1'; //                   Control                          End [main.wireOptional END]
  _PartialVdlType optionalPt = new _PartialVdlType.optionalType('aname', 88);
  testCases.add(new TypeDefinitionDecodeTestCase('optional', _WireOptional.vdlType, optionalHex, optionalPt));

 String invalidIndexHex =
    '00' //                   Index                              0 [main.wireNamed.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '04' //                  Bad Index!
    '58' //                   PrimValue                         88 [uint]
    'e1'; //                   Control                          End [main.wireNamed END]
  testCases.add(new TypeDefinitionDecodeTestCase.failure('invalid index', _WireNamed.vdlType, invalidIndexHex, VomDecodeException));

  testCases.add(new TypeDefinitionDecodeTestCase.failure('unrecognized type', vdl.VdlTypes.Int32, wireNamedHex, UnrecognizedTypeMessageException));

 String invalidControlHex =
    '00' //                   Index                              0 [main.wireNamed.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '04' //                   Index                              1 [main.wireNamed.Base]
    '58' //                   PrimValue                         88 [uint]
    'e7'; //                  Invalid Control Byte!
  testCases.add(new TypeDefinitionDecodeTestCase.failure('invalid control byte', _WireNamed.vdlType, invalidControlHex, VomDecodeException));

String earlyEofHex =
    '00' //                   Index                              0 [main.wireNamed.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '04'; //                   Index                              1 [main.wireNamed.Base]
    // Early end!
  testCases.add(new TypeDefinitionDecodeTestCase.failure('early eof', _WireNamed.vdlType, earlyEofHex, VomDecodeException));


  return testCases;
}