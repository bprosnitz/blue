library vdl;

import 'package:test/test.dart';

import 'dart:core';
import 'dart:collection';
import 'dart:mirrors' as mirrors;
import 'dart:typed_data' as typed_data;
import 'package:quiver/core.dart' as quiver_core;
import 'package:quiver/collection.dart' as quiver_collection;
import '../test_util/test_util.dart' as test_util;
import '../../lib/src/collection/collection.dart' as collection;

part '../../lib/src/vdl/casing.part.dart';
part '../../lib/src/vdl/reflect.part.dart';
part '../../lib/src/vdl/type.part.dart';
part '../../lib/src/vdl/types.part.dart';
part '../../lib/src/vdl/value.part.dart';
part '../../lib/src/vdl/value_base.part.dart';
part '../../lib/src/vdl/value_rep.part.dart';

void main() {
  group('vdlTypeOf', () {
    for (var testCase in getTestCases()) {
      if (testCase.expectedExceptionType != null) {
        test('${testCase.name} (should throw exception)}', () {
          expect(() => vdlTypeOf(testCase.input),
            throwsA(new test_util.isInstanceOfType(testCase.expectedExceptionType)));
        });
      } else {
        test(testCase.name, () {
          expect(vdlTypeOf(testCase.input), equals(testCase.expectedOutput));
        });
      }
    }
  });
  group('vdlTypeFromMirror', () {
    for (var testCase in getTestCases()) {
      mirrors.ClassMirror inputMirror = mirrors.reflect(testCase.input).type;
      if (testCase.expectedExceptionType != null) {
        test('${testCase.name} (should throw exception)}', () {
          expect(() => vdlTypeFromMirror(inputMirror),
            throwsA(new test_util.isInstanceOfType(testCase.expectedExceptionType)));
        });
      } else {
        test(testCase.name, () {
          expect(vdlTypeFromMirror(inputMirror), equals(testCase.expectedOutput));
        });
      }
    }
  });
}

class ReflectTestCase {
  String name;
  dynamic input;
  VdlType expectedOutput;
  Type expectedExceptionType;
  ReflectTestCase(this.name, this.input, this.expectedOutput,
    [this.expectedExceptionType = null]);
}

List<ReflectTestCase> getTestCases() {
  List<ReflectTestCase> tests = [];

  tests.add(new ReflectTestCase('bool', true, VdlTypes.Bool));
  tests.add(new ReflectTestCase('int', 5, VdlTypes.Int64));
  tests.add(new ReflectTestCase('double', 3.4, VdlTypes.Float64));
  tests.add(new ReflectTestCase('complex128', new VdlComplex(0.0, 0.0), VdlTypes.Complex128));
  tests.add(new ReflectTestCase('string', 'str', VdlTypes.String));
  tests.add(new ReflectTestCase('type object', VdlTypes.Bool, VdlTypes.TypeObject));

  var optionalPendingType = new VdlPendingType()
  ..kind = VdlKind.Optional
  ..elem = VdlTypes.Int64;
  tests.add(new ReflectTestCase('optional', new VdlOptional<int>(null),
    optionalPendingType.build()));

  var listPendingType = new VdlPendingType()
  ..kind = VdlKind.List
  ..elem = VdlTypes.Int64;
  tests.add(new ReflectTestCase('list', <int>[1, 2, 3], listPendingType.build()));
  var listWithoutType = new VdlPendingType()
  ..kind = VdlKind.List
  ..elem = VdlTypes.Any;
  tests.add(new ReflectTestCase('list without generic param', [1, 2, 3],
    listWithoutType.build()));
  var customListPendingType = new VdlPendingType()
  // Note: On named lists, the name is stripped when no type is explicitly provided.
  ..kind = VdlKind.List
  ..elem = VdlTypes.String;
  tests.add(new ReflectTestCase('custom list via reflect', new CustomListType(), customListPendingType.build()));
  var namedListPendingType = new VdlPendingType()
  ..name = 'ACustomName'
  ..kind = VdlKind.List
  ..elem = VdlTypes.String;
  tests.add(new ReflectTestCase('custom list via vdlType', new CustomNamedListType(), namedListPendingType.build()));

  var fixedLengthArrayType = new VdlPendingType()
  ..name = 'ACustomName'
  ..kind = VdlKind.Array
  ..len = 5
  ..elem = VdlTypes.String;
  tests.add(new ReflectTestCase('fixed length array via vdlType', new CustomArrayType(), fixedLengthArrayType.build()));

  var mapPendingType = new VdlPendingType()
  ..kind = VdlKind.Map
  ..key = VdlTypes.Bool
  ..elem = VdlTypes.String;
  var mapExample = <bool, String>{true:  'a', false: 'b'};
  tests.add(new ReflectTestCase('map', mapExample, mapPendingType.build()));
  var mapWithoutType = new VdlPendingType()
  ..kind = VdlKind.Map
  ..key = VdlTypes.Any
  ..elem = VdlTypes.Any;
  tests.add(new ReflectTestCase('map without generic param',
    {true: 'a', false:'b'}, mapWithoutType.build()));
  var customMapPendingType = new VdlPendingType()
  // Note: On named maps, the name is stripped when no type is explicitly provided.
  ..kind = VdlKind.Map
  ..key = VdlTypes.String
  ..elem = VdlTypes.Int64;
  tests.add(new ReflectTestCase('custom map via reflect', new CustomMapType(), customMapPendingType.build()));
  var namedMapPendingType = new VdlPendingType()
  ..name = 'ACustomName'
  ..kind = VdlKind.Map
  ..key = VdlTypes.String
  ..elem = VdlTypes.Int32;
  tests.add(new ReflectTestCase('custom map via vdlType', new CustomNamedMapType(), namedMapPendingType.build()));

  var setPendingType = new VdlPendingType()
  ..kind = VdlKind.Set
  ..key = VdlTypes.String;
  var setExample = new Set<String>()
  ..add("a")
  ..add("b");
  tests.add(new ReflectTestCase('set', setExample, setPendingType.build()));
  var setWithoutType = new VdlPendingType()
  ..kind = VdlKind.Set
  ..key = VdlTypes.Any;
  var setWithoutTypeExample = new Set();
  setWithoutTypeExample.add("a");
  setWithoutTypeExample.add("b");
  tests.add(new ReflectTestCase('set without generic param',
    setWithoutTypeExample, setWithoutType.build()));
  var customSetPendingType = new VdlPendingType()
  // Note: On named maps, the name is stripped when no type is explicitly provided.
  ..kind = VdlKind.Set
  ..key = VdlTypes.String;
  tests.add(new ReflectTestCase('custom set via reflect', new CustomSetType(), customSetPendingType.build()));
  var namedSetPendingType = new VdlPendingType()
  ..name = 'ACustomName'
  ..kind = VdlKind.Set
  ..key = VdlTypes.String;
  tests.add(new ReflectTestCase('custom set via vdlType', new CustomNamedSetType(), namedSetPendingType.build()));

  var enumPendingType = new VdlPendingType()
  ..kind = VdlKind.Enum
  ..name = 'vdl.CustomEnumType'
  ..labels = ['A','B','C'];
  tests.add(new ReflectTestCase('enum', CustomEnumType.A, enumPendingType.build()));
  tests.add(new ReflectTestCase('enum - old style', OldStyleEnum.A, OldStyleEnum.vdlType));

  var structPendingType = new VdlPendingType()
  ..kind = VdlKind.Struct
  ..name = 'vdl.CustomStructType'
  ..fields = [
    new VdlPendingField('A', VdlTypes.Int64),
    new VdlPendingField('B', VdlTypes.String)
  ];
  tests.add(new ReflectTestCase('struct', new CustomStructType(), structPendingType.build()));
  var structWithPrivateFieldsPendingType = new VdlPendingType()
  ..kind = VdlKind.Struct
  ..name = 'vdl.StructWithPrivateFields'
  ..fields = [
    new VdlPendingField('A', VdlTypes.Int64)
  ];
  tests.add(new ReflectTestCase('struct with private fields', new StructWithPrivateFields(),
    structWithPrivateFieldsPendingType.build()));
  var getterPendingType = new VdlPendingType()
  ..kind = VdlKind.Struct
  ..name = 'vdl.CustomGetterType'
  ..fields = [
    new VdlPendingField('A', VdlTypes.Int64),
    new VdlPendingField('B', VdlTypes.String)
  ];
  tests.add(new ReflectTestCase('struct with getters', new CustomGetterType(), getterPendingType.build()));
   var privateGetterPendingType = new VdlPendingType()
  ..kind = VdlKind.Struct
  ..name = 'vdl.StructWithPrivateGetter'
  ..fields = [
    new VdlPendingField('A', VdlTypes.Int64)
  ];
  tests.add(new ReflectTestCase('struct with private getter', new StructWithPrivateGetter(), privateGetterPendingType.build()));

  var recursivePendingType = new VdlPendingType()
  ..kind = VdlKind.Struct
  ..name = 'vdl.CustomRecursiveStruct';
  recursivePendingType.fields = [
    new VdlPendingField('X', recursivePendingType)
  ];
  tests.add(new ReflectTestCase('recusive type', new CustomRecursiveStruct(), recursivePendingType.build()));
   var indirectRecursivePendingType = new VdlPendingType()
  ..kind = VdlKind.Struct
  ..name = 'vdl.CustomIndirectRecursiveStruct';
  var indirectListType = new VdlPendingType()
  ..kind = VdlKind.List
  ..elem = indirectRecursivePendingType;
  indirectRecursivePendingType.fields = [
    new VdlPendingField('X', indirectListType)
  ];
  tests.add(new ReflectTestCase('recusive type', new CustomIndirectRecursiveStruct(),
    indirectRecursivePendingType.build()));

  tests.add(new ReflectTestCase('ByteData', new typed_data.ByteData(5),
    _makeListForElem(VdlTypes.Byte)));
  tests.add(new ReflectTestCase('Uint8List', new typed_data.Uint8List(5),
    _makeListForElem(VdlTypes.Byte)));
  tests.add(new ReflectTestCase('Uint8ClampedList',
    new typed_data.Uint8ClampedList(5), _makeListForElem(VdlTypes.Byte)));
  tests.add(new ReflectTestCase('Uint16List', new typed_data.Uint16List(5),
    _makeListForElem(VdlTypes.Uint16)));
  tests.add(new ReflectTestCase('Uint32List', new typed_data.Uint32List(5),
    _makeListForElem(VdlTypes.Uint32)));
  tests.add(new ReflectTestCase('Uint64List', new typed_data.Uint64List(5),
    _makeListForElem(VdlTypes.Uint64)));
  tests.add(new ReflectTestCase('Int8List', new typed_data.Int8List(5),
    _makeListForElem(VdlTypes.Byte)));
  tests.add(new ReflectTestCase('Int16List', new typed_data.Int16List(5),
    _makeListForElem(VdlTypes.Int16)));
  tests.add(new ReflectTestCase('Int32List', new typed_data.Int32List(5),
    _makeListForElem(VdlTypes.Int32)));
  tests.add(new ReflectTestCase('Int32x4List', new typed_data.Int32x4List(5),
    _makeListForElem(_makeVdlInt32x4Type())));
  tests.add(new ReflectTestCase('Int64List', new typed_data.Int64List(5),
    _makeListForElem(VdlTypes.Int64)));
  tests.add(new ReflectTestCase('Float32List', new typed_data.Float32List(5),
    _makeListForElem(VdlTypes.Float32)));
  tests.add(new ReflectTestCase('Float32x4List', new typed_data.Float32x4List(5),
    _makeListForElem(_makeVdlFloat32x4Type())));
  tests.add(new ReflectTestCase('Float64List', new typed_data.Float64List(5),
    _makeListForElem(VdlTypes.Float64)));
  tests.add(new ReflectTestCase('Float64x2List', new typed_data.Float64x2List(5),
    _makeListForElem(_makeVdlFloat64x2Type())));

  // Reflection on vdlType field / getter
  var namedBoolType = makeNamedBoolType();
  var staticFinalVdlType = new KlassStaticFinalVdlType();
  tests.add(new ReflectTestCase('vdlType static final field', staticFinalVdlType, namedBoolType));
  var finalVdlType = new KlassFinalVdlType();
  tests.add(new ReflectTestCase('vdlType final field', finalVdlType, null, StaticFinalVdlTypeError));
  var staticVdlType = new KlassStaticVdlType();
  tests.add(new ReflectTestCase('vdlType static field', staticVdlType, null, StaticFinalVdlTypeError));
  var staticVdlTypeGetter = new KlassVdlTypeGetter();
  tests.add(new ReflectTestCase('vdlType static getter', staticVdlTypeGetter, null, StaticFinalVdlTypeError));
  var staticVdlTypeDiffFieldType = new KlassStaticFinalVdlTypeDiffField();
  tests.add(new ReflectTestCase('vdlType diff field type', staticVdlTypeDiffFieldType, null, StaticFinalVdlTypeError));

  return tests;
}

VdlType makeNamedBoolType() {
  VdlPendingType pt = new VdlPendingType()
  ..kind = VdlKind.Bool
  ..name = 'testname';
  return pt.build();
}

// Test reflection on vdlType field / getter.
class KlassStaticFinalVdlType {
  static final VdlType vdlType = makeNamedBoolType();
}

// Invalid cases:
class KlassFinalVdlType {
  final VdlType vdlType = makeNamedBoolType();
}
class KlassStaticVdlType {
  static VdlType vdlType = makeNamedBoolType();
}
class KlassVdlTypeGetter {
  static VdlType get vdlType => makeNamedBoolType();
}
class KlassStaticFinalVdlTypeDiffField {
  static VdlType vdlType = makeDiffFieldType();
  static VdlType makeDiffFieldType() {
    VdlPendingType pt = new VdlPendingType()
    ..kind = VdlKind.Int32
    ..name = 'testname';
    return pt.build();
  }
}

// Enum
enum CustomEnumType {
  A, B, C
}

// Struct
class CustomStructType {
  int a;
  String b;
}

// Struct with private fields.
class StructWithPrivateFields {
  int a;
  String _b;
  String toString() {
    return _b; // to work around lint warnings
  }
}

// Struct getter
class CustomGetterType {
  int a;
  String get b => 'ok';
}

// Struct with private getter
class StructWithPrivateGetter {
  int a;
  String get _b => 'ok';
  String toString() {
    return _b; // to work around lint warnings
  }
}

// Recursive Test Case
class CustomRecursiveStruct {
  CustomRecursiveStruct x;
}

class CustomIndirectRecursiveStruct {
  List<CustomIndirectRecursiveStruct> x;
}

// Custom list
class CustomListType extends Object with ListMixin<String> {
  List<String> innerList = <String>['A', 'B'];

  int get length => innerList.length;
  set length(int value) {
    innerList.length = value;
  }
  operator  [](int key) => innerList[key];
  operator []=(int key, String value) {
    innerList[key] = value;
  }
}

class CustomNamedListType extends CustomListType {
  static final VdlType vdlType = _makeVdlType();
  static VdlType _makeVdlType() {
    var pt = new VdlPendingType()
    ..kind = VdlKind.List
    ..name = 'ACustomName'
    ..elem = VdlTypes.String;
    return pt.build();
  }
}

// Custom map
class CustomMapType extends Object with MapMixin<String, int> {
  Map<String, int> innerMap = {
    'A': 1,
    'B': 2
  };

  operator [](String key) => innerMap[key];
  operator []=(String key, int value) {
    innerMap[key] = value;
  }
  void clear() => innerMap.clear();
  int remove(String key) => innerMap.remove(key);
  Iterable<String> get keys => innerMap.keys;
}

class CustomNamedMapType extends CustomMapType {
  static final VdlType vdlType = _makeVdlType();
  static VdlType _makeVdlType() {
    var pt = new VdlPendingType()
    ..kind = VdlKind.Map
    ..name = 'ACustomName'
    ..key = VdlTypes.String
    ..elem = VdlTypes.Int32;
    return pt.build();
  }
}

// Custom set
class CustomSetType extends Object with SetMixin<String> {
  Set<String> innerSet = new Set<String>();

  bool contains(String key) => innerSet.contains(key);
  Iterator<String> get iterator => innerSet.iterator;
  bool add(String value) => innerSet.add(value);
  Set<String> toSet() => innerSet.toSet();
  int get length => innerSet.length;
  bool remove(String key) => innerSet.remove(key);
  String lookup(Object obj) => innerSet.lookup(obj);

  CustomSetType() {
    innerSet.add('A');
    innerSet.add('B');
  }
}

class CustomNamedSetType extends CustomSetType {
  static final VdlType vdlType = _makeVdlType();
  static VdlType _makeVdlType() {
    var pt = new VdlPendingType()
    ..kind = VdlKind.Set
    ..name = 'ACustomName'
    ..key = VdlTypes.String;
    return pt.build();
  }
}

// Fixed length array
class CustomArrayType extends CustomListType {
  static final VdlType vdlType = _makeVdlType();
  static VdlType _makeVdlType() {
    var pt = new VdlPendingType()
    ..kind = VdlKind.Array
    ..len = 5
    ..name = 'ACustomName'
    ..elem = VdlTypes.String;
    return pt.build();
  }
}

// Old-style enum
class OldStyleEnum {
  static const A = const OldStyleEnum._(0);
  static const B = const OldStyleEnum._(1);

  static final VdlType vdlType = _makeVdlType();
  static VdlType _makeVdlType() {
    var pt = new VdlPendingType()
    ..kind = VdlKind.Enum
    ..name = 'OldStyleEnum'
    ..labels = ['A', 'B'];
    return pt.build();
  }

  final int value;

  static get values => [A, B];

  const OldStyleEnum._(this.value);
}

// TODO(bprosnitz) Add a test for union (using the vdlType field) once the format is known.