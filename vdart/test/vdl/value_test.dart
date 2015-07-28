import 'package:test/test.dart';
import '../../lib/src/vdl/vdl.dart';
import './value_test_types.dart';

void main() {
  group('VdlValue', () {
    // Thest tests check that a VdlValue is valid and that its toString is
    // correct. These are specific tests meant for easier debugging.
    for (VdlValueToStringExample example in makeVdlValueToStringExamples()) {
      test('${example.testName} - toString', () {
        expect(example.testValue.toString(), equals(example.stringValue));
      });
    }

    // These tests check a more generic case that echo the Go version of the
    // tests.
    for (VdlValueExample example in makeVdlValueExamples()) {
      VdlValue x, y, z;

      // Assign y as a VdlValue.zero and check that it is zero.
      test('${example.testName} - zeroValue, isZero', () {
        y = new VdlValue.zero(example.testType);
        expect(y.toString(), equals(example.zeroStringValue));
        expect(y.isZero, isTrue, reason: 'should be zero');
        expect(y.type, equals(example.testType), reason: 'should match type');
      });

      // Start x out as the zero value too and ensure that x == y.
      test('${example.testName} - VdlValue.zero, equalValue', () {
        x = new VdlValue.zero(example.testType);
        expect(x == y, isTrue, reason: 'x == y (both 0)');
      });

      // Now assign non-zero values to x and check that x != y.
      // Note: This uses testAssignFoo, which runs a lot of additional
      // assertions. The methods called depend on kind.
      // Most methods must throw when called; the remaining methods must modify
      // x's internal representation correctly.
      test('${example.testName} - assignFoo, !equalValue', () {
        testAssignFoo(x); // Note: This assignment occurs based on kind.
        expect(x == y, isFalse, reason: 'x != y (x != 0 && y == 0)');
      });

      // Copy y into z, such that y == z && x != z
      test('${example.testName} - copyValue, equalValue', () {
        z = new VdlValue.copy(y);
        expect(x == z, isFalse, reason: 'x != z (z copied y != x)');
        expect(y == z, isTrue, reason: 'y == z (z copied y)');
      });

      // Assign x into y, so y == x and y != z
      test('${example.testName} - assign, equalValue', () {
        y.assign(x);
        expect(x == y, isTrue, reason: 'x == y (y <== x)');
        expect(x == z, isFalse, reason: 'x != z');
        expect(y == z, isFalse, reason: 'y != z (y <== x != z)');
      });

      VdlType optType = optionalType(example.testType);
      VdlValue ox = new VdlValue.zero(optType);

      // Check the optional type's zero value. It should be null.
      test('?${example.testName} - VdlValue.zero', () {
        expect(ox.isZero, isTrue, reason: 'should be zero');
        expect(ox.isNull, isTrue, reason: 'should be null');
        expect(ox.toString(), equals('${optType.toString()}(nil)'));
      });

      // Check the optional type's non-zero value. It should NOT be null.
      test('?${example.testName} - VdlValue assign non-null zero', () {
        ox.assign(new VdlValue.zero(example.testType));
        expect(ox.isZero, isFalse, reason: 'should NOT be zero');
        expect(ox.isNull, isFalse, reason: 'should NOT be null');
        expect(ox.elem == new VdlValue.zero(example.testType), isTrue,
          reason: 'elem should match zero value of elem type');
      });
    }
  });
}

class VdlValueToStringExample {
  String testName;
  VdlValue testValue;  String stringValue;

  VdlValueToStringExample(this.testName, this.testValue, this.stringValue);
}

List<VdlValueToStringExample> makeVdlValueToStringExamples() {
  List<VdlValueToStringExample> examples = new List<VdlValueToStringExample>();

  examples.add(new VdlValueToStringExample('VdlValue - string',
    stringValue('abc'), '"abc"'));
  examples.add(new VdlValueToStringExample('VdlValue - named string',
    new VdlValue.zero(namedStringType)
      ..asString = 'abc', 'NamedString string("abc")'));
  examples.add(new VdlValueToStringExample('VdlValue - bool',
    boolValue(true), 'true'));
  examples.add(new VdlValueToStringExample('VdlValue - uint32',
    uint32Value(5), 'uint32(5)'));
  examples.add(new VdlValueToStringExample('VdlValue - float64',
    float64Value(-3.4), 'float64(-3.4)'));
  examples.add(new VdlValueToStringExample('VdlValue - complex128',
    complex128Value(new VdlComplex(5.8, -46.888)),
      'complex128(5.8-46.888i)'));
  examples.add(new VdlValueToStringExample('VdlValue - BoolArray3',
    new VdlValue.zero(boolArray3Type)..asList[1].asBool = true,
    'BoolArray3 [3]bool{false, true, false}'));

  VdlValue structVal = new VdlValue.zero(abcStructType) // Note: field 0 defaults to ''.
    ..structFieldByIndex(1).asInt = 4
    ..structFieldByIndex(2).asBool = true;
  examples.add(new VdlValueToStringExample('VdlValue - ABCStruct',
    structVal, 'ABCStruct struct{A string;B int32;C bool}'
    '{A: "", B: 4, C: true}'));
  examples.add(new VdlValueToStringExample('VdlValue - typeObject',
    typeObjectValue(abcStructType),
    'typeobject(ABCStruct struct{A string;B int32;C bool})'));
  examples.add(new VdlValueToStringExample('VdlValue - optional',
    optionalValue(typeObjectValue(abcStructType)),
    '?typeobject(typeobject(ABCStruct struct{A string;B int32;C bool}))'));
  examples.add(new VdlValueToStringExample('VdlValue - any',
    anyValue(typeObjectValue(abcStructType)),
    'any(typeobject(ABCStruct struct{A string;B int32;C bool}))'));
  examples.add(new VdlValueToStringExample('VdlValue - map',
    new VdlValue.zero(boolComplexMapType)
      ..asMap[boolValue(true)] = complex64Value(new VdlComplex(3.1, 4.15)),
    'map[bool]complex64{true: 3.1+4.15i}'));
  examples.add(new VdlValueToStringExample('VdlValue - set',
    new VdlValue.zero(intSetType)
      ..asSet.add(int16Value(4))
      ..asSet.add(int16Value(-5)),
    'set[int16]{4, -5}'));

  return examples;
}

class VdlValueExample {
  String testName;
  VdlType testType;
  String zeroStringValue;

  VdlValueExample(this.testName, this.testType, this.zeroStringValue);
}

List<VdlValueExample> makeVdlValueExamples() {
  List<VdlValueExample> examples = new List<VdlValueExample>();
  examples.add(new VdlValueExample('bool', VdlTypes.Bool, 'false'));
  examples.add(new VdlValueExample('byte', VdlTypes.Byte, 'byte(0)'));
  examples.add(new VdlValueExample('uint16', VdlTypes.Uint16, 'uint16(0)'));
  examples.add(new VdlValueExample('uint32', VdlTypes.Uint32, 'uint32(0)'));
  examples.add(new VdlValueExample('uint64', VdlTypes.Uint64, 'uint64(0)'));
  examples.add(new VdlValueExample('int16', VdlTypes.Int16, 'int16(0)'));
  examples.add(new VdlValueExample('int32', VdlTypes.Int32, 'int32(0)'));
  examples.add(new VdlValueExample('int64', VdlTypes.Int64, 'int64(0)'));
  examples.add(new VdlValueExample('float32', VdlTypes.Float32, 'float32(0.0)'));
  examples.add(new VdlValueExample('float64', VdlTypes.Float64, 'float64(0.0)'));
  examples.add(new VdlValueExample('complex64', VdlTypes.Complex64, 'complex64(0.0+0.0i)'));
  examples.add(new VdlValueExample('complex128', VdlTypes.Complex128, 'complex128(0.0+0.0i)'));
  examples.add(new VdlValueExample('string', VdlTypes.String, '""'));
  examples.add(new VdlValueExample('[]byte', listType(VdlTypes.Byte), '[]byte("")'));
  examples.add(new VdlValueExample('[3]byte', arrayType(3, VdlTypes.Byte, 'Byte3Array'), 'Byte3Array [3]byte("\x00\x00\x00")'));
  examples.add(new VdlValueExample('enumABC', enumType(['A', 'B', 'C'], 'ABCEnum'), 'ABCEnum enum{A;B;C}(A)'));
  examples.add(new VdlValueExample('typeobject', VdlTypes.TypeObject, 'typeobject(any)'));
  examples.add(new VdlValueExample('[2]string', arrayType(2, VdlTypes.String, 'String2Array'), 'String2Array [2]string{"", ""}'));
  examples.add(new VdlValueExample('[]string', listType(VdlTypes.String), '[]string{}'));
  examples.add(new VdlValueExample('set[string]', setType(VdlTypes.String), 'set[string]{}'));
  examples.add(new VdlValueExample('set[intStrStructType]', setType(intStrStructType), 'set[IS struct{I int64;S string}]{}'));
  examples.add(new VdlValueExample('map[string]int64', mapType(VdlTypes.String, VdlTypes.Int64), 'map[string]int64{}'));
  examples.add(new VdlValueExample('map[intStrStructType]int64', mapType(intStrStructType, VdlTypes.Int64), 'map[IS struct{I int64;S string}]int64{}'));
  examples.add(new VdlValueExample('ABCStruct', abcStructType, 'ABCStruct struct{A string;B int32;C bool}{A: "", B: 0, C: false}'));
  examples.add(new VdlValueExample('ABCUnion', abcUnionType, 'ABCUnion union{A string;B int32;C bool}{A: ""}'));
  examples.add(new VdlValueExample('any', VdlTypes.Any, 'any(nil)'));

  return examples;
}

void testAssignFoo(VdlValue x) {
  // Based on x's kind, assign a value.
  // Does some testing too, along the way. For example, checks that certain
  // methods cannot be called (expecting an error).
  testAssignBool(x);
  testAssignByte(x);
  testAssignUint(x);
  testAssignInt(x);
  testAssignFloat(x);
  testAssignComplex(x);
  testAssignString(x);
  testAssignEnum(x);
  testAssignTypeObject(x);
  testAssignArray(x);
  testAssignList(x);
  testAssignSet(x);
  testAssignMap(x);
  testAssignStruct(x);
  testAssignUnion(x);
  testAssignAny(x);
}

// (Taken from value_test.go)
// Each of the below assign{KIND} functions assigns a nonzero value to x for
// matching kinds, otherwise it expects a mismatched-kind panic when trying the
// kind-specific methods.  The point is to ensure we've tried all combinations
// of kinds and methods.
void testAssignBool(VdlValue x) {
  bool newval = true;
  String newstr = 'true';
  if (x.kind == VdlKind.Bool) {
    expect(x.asBool, isFalse);
    x.asBool = newval;
    expect(x.asBool, equals(newval));
    expect(x.toString(), equals(newstr));
  } else {
    expect(() => x.asBool,
      throwsA(new isInstanceOf<StateError>()));
    expect(() => x.asBool = newval,
      throwsA(new isInstanceOf<StateError>()));
  }
}
void testAssignByte(VdlValue x) {
  int newval = 123;
  String newstr = 'byte(123)';
  if (x.kind == VdlKind.Byte) {
    expect(x.asByte, isZero);
    x.asByte = newval;
    expect(x.asByte, equals(newval));
    expect(x.toString(), equals(newstr));
  } else {
    expect(() => x.asByte,
      throwsA(new isInstanceOf<StateError>()));
    expect(() => x.asByte = newval,
      throwsA(new isInstanceOf<StateError>()));
  }
}
void testAssignUint(VdlValue x) {
  int newval = 400;
  String newsubstr = '(400)';
  if (x.kind == VdlKind.Uint16 || x.kind == VdlKind.Uint32 || x.kind == VdlKind.Uint64) {
    expect(x.asUint, isZero);
    x.asUint = newval;
    expect(x.asUint, equals(newval));
    expect(x.toString(), contains(newsubstr));
  } else {
    expect(() => x.asUint,
      throwsA(new isInstanceOf<StateError>()));
    expect(() => x.asUint = newval,
      throwsA(new isInstanceOf<StateError>()));
  }
}
void testAssignInt(VdlValue x) {
  int newval = -400;
  String newsubstr = '(-400)';
  if (x.kind == VdlKind.Int16 || x.kind == VdlKind.Int32 || x.kind == VdlKind.Int64) {
    expect(x.asInt, isZero);
    x.asInt = newval;
    expect(x.asInt, equals(newval));
    expect(x.toString(), contains(newsubstr));
  } else {
    expect(() => x.asInt,
      throwsA(new isInstanceOf<StateError>()));
    expect(() => x.asInt = newval,
      throwsA(new isInstanceOf<StateError>()));
  }
}
void testAssignFloat(VdlValue x) {
  double newval = 1.23;
  String newsubstr = '(1.23)';
  if (x.kind == VdlKind.Float32 || x.kind == VdlKind.Float64) {
    expect(x.asFloat, equals(0.0));
    x.asFloat = newval;
    expect(x.asFloat, equals(newval));
    expect(x.toString(), contains(newsubstr));
  } else {
    expect(() => x.asFloat,
      throwsA(new isInstanceOf<StateError>()));
    expect(() => x.asFloat = newval,
      throwsA(new isInstanceOf<StateError>()));
  }
}
void testAssignComplex(VdlValue x) {
  VdlComplex newval = new VdlComplex(1.2, 2.3);
  String newsubstr = '1.2+2.3i';
  if (x.kind == VdlKind.Complex64 || x.kind == VdlKind.Complex128) {
    expect(x.asComplex, equals(new VdlComplex(0.0, 0.0)));
    x.asComplex = newval;
    expect(x.asComplex, equals(newval));
    expect(x.toString(), contains(newsubstr));
  } else {
    expect(() => x.asComplex,
      throwsA(new isInstanceOf<StateError>()));
    expect(() => x.asComplex = newval,
      throwsA(new isInstanceOf<StateError>()));
  }
}
void testAssignString(VdlValue x) {
  String newval = 'abc';
  String newstr = '"abc"';
  if (x.kind == VdlKind.String) {
    expect(x.asString, equals(''));
    x.asString = newval;
    expect(x.asString, equals(newval));
    expect(x.toString(), equals(newstr));
  } else {
    expect(() => x.asString,
      throwsA(new isInstanceOf<StateError>()));
    expect(() => x.asString = newval,
      throwsA(new isInstanceOf<StateError>()));
  }
}
void testAssignEnum(VdlValue x) {
  // This one is different, in that we'll be assigning 2 times.
  // Recall that the enum is the ABC enum.
  if (x.kind == VdlKind.Enum) {
    expect(x.asEnumIndex, isZero);
    expect(x.asEnumLabel, equals('A'));
    expect(x.toString(), equals('ABCEnum enum{A;B;C}(A)'));

    x.asEnumIndex = 1;
    expect(x.asEnumIndex, equals(1));
    expect(x.asEnumLabel, equals('B'));
    expect(x.toString(), equals('ABCEnum enum{A;B;C}(B)'));

    x.asEnumLabel = 'C';
    expect(x.asEnumIndex, equals(2));
    expect(x.asEnumLabel, equals('C'));
    expect(x.toString(), equals('ABCEnum enum{A;B;C}(C)'));
  } else {
    expect(() => x.asEnumIndex,
      throwsA(new isInstanceOf<StateError>()));
    expect(() => x.asEnumLabel,
      throwsA(new isInstanceOf<StateError>()));
    expect(() => x.asEnumIndex = 1,
      throwsA(new isInstanceOf<StateError>()));
    expect(() => x.asEnumLabel = 'C',
      throwsA(new isInstanceOf<StateError>()));
  }
}
void testAssignTypeObject(VdlValue x) {
  VdlType newval = VdlTypes.Bool;
  String newstr = 'typeobject(bool)';
  if (x.kind == VdlKind.TypeObject) {
    expect(x.asTypeObject, equals(VdlTypes.Any));
    x.asTypeObject = newval;
    expect(x.asTypeObject, equals(newval));
    expect(x.toString(), equals(newstr));
  } else {
    expect(() => x.asTypeObject,
      throwsA(new isInstanceOf<StateError>()));
    expect(() => x.asTypeObject = newval,
      throwsA(new isInstanceOf<StateError>()));
  }
}
void testAssignArray(VdlValue x) {
  String arrayName = 'String2Array'; // is [2]string

  if (x.kind == VdlKind.Array) {
    if (x.type.isBytes) {
      testAssignBytes(x);
      return;
    }
    expect(x.asList.length, equals(2));
    expect(x.asList[0].toString(), equals('""'));

    x.asList[0].asString = 'a';
    x.asList[1].asString = 'b';
    expect(x.asList[0].toString(), equals('"a"'));
    expect(x.asList[1].toString(), equals('"b"'));

    expect(x.toString(), equals('${arrayName} [2]string{"a", "b"}'));
  } else {
    // Only Array and List may call 'asList'.
    if (x.kind != VdlKind.List) {
      expect(() => x.asList[0],
        throwsA(new isInstanceOf<StateError>()));
    }
  }

}
void testAssignList(VdlValue x) {
  if (x.kind == VdlKind.List) {
    if (x.type.isBytes) {
      testAssignBytes(x);
      return;
    }

    expect(x.asList.length, isZero);

    x.asList.length = 2;
    expect(x.asList.length, equals(2));
    expect(x.asList[0].toString(), equals('""'));
    expect(x.asList[1].toString(), equals('""'));
    expect(x.toString(), equals('[]string{"", ""}'));

    x.asList[0].asString = 'a';
    x.asList[1].asString = 'b';
    expect(x.asList[0].toString(), equals('"a"'));
    expect(x.asList[1].toString(), equals('"b"'));

    expect(x.toString(), equals('[]string{"a", "b"}'));

    // Drop value when reducing the length of the list.
    x.asList.length = 1;
    expect(x.toString(), equals('[]string{"a"}'));

    x.asList.length = 3;
    expect(x.toString(), equals('[]string{"a", "", ""}'));
  } else {
    // Only list and array may call 'asList'.
    if (x.kind != VdlKind.Array) {
      expect(() => x.asList,
        throwsA(new isInstanceOf<StateError>()));
    }
  }
}
void testAssignBytes(VdlValue x) {
  // This is only called when we are certain that x represents a list of bytes.
  List<int> zeroValue = [];
  var bytesPrefix = '[]byte';
  if (x.kind == VdlKind.Array) {
    zeroValue = [0, 0, 0];
    bytesPrefix = 'Byte3Array [3]byte';
  }

  expect(x.asBytes, equals(zeroValue));

  List<int> b = 'abc'.codeUnits;
  x.asBytes = b;
  expect(x.asBytes, equals(b));
  expect(x.toString(), equals('${bytesPrefix}("abc")'));

  // When assigning bytes, we actually assigned a copy.
  x.asBytes[1] = 'd'.codeUnits[0];
  expect(x.asBytes, isNot(equals(b)));
  expect(x.asBytes, equals('adc'.codeUnits));
  expect(x.toString(), equals('${bytesPrefix}("adc")'));
}


VdlValue strValA = stringValue('A');
VdlValue strValB = stringValue('B');
VdlValue strValC = stringValue('C');
VdlValue keyVal1 = new VdlValue.zero(intStrStructType)
  ..structFieldByName('I').asInt = 1
  ..structFieldByName('S').asString = 'A';
VdlValue keyVal2 = new VdlValue.zero(intStrStructType)
  ..structFieldByName('I').asInt = 2
  ..structFieldByName('S').asString = 'B';
VdlValue keyVal3 = new VdlValue.zero(intStrStructType)
  ..structFieldByName('I').asInt = 3
  ..structFieldByName('S').asString = 'C';

void testAssignSet(VdlValue x) {
  if (x.kind == VdlKind.Set) {
    // The VdlValue is for a set of structs, that have I: int64, S: string
    // OR it's set[string]
    VdlValue k1, k2, k3;
    String s1, s2;
    if (x.type.key == VdlTypes.String) {
      k1 = strValA;
      k2 = strValB;
      k3 = strValC;
      s1 = 'set[string]{"A", "B"}';
      s2 = 'set[string]{"B"}';
    } else {
      k1 = keyVal1;
      k2 = keyVal2;
      k3 = keyVal3;
      s1 = 'set[IS struct{I int64;S string}]{{I: 1, S: "A"}, {I: 2, S: "B"}}';
      s2 = 'set[IS struct{I int64;S string}]{{I: 2, S: "B"}}';
    }

    // The set starts out as empty and has no keys.
    expect(x.asSet.length, isZero, reason: 'set should be empty');
    expect(x.asSet.contains(k1), isFalse, reason: 'set should be empty');
    expect(x.asSet.contains(k2), isFalse, reason: 'set should be empty');
    expect(x.asSet.contains(k3), isFalse, reason: 'set should be empty');

    // Let's assign the first two keys.
    x.asSet.add(k1);
    x.asSet.add(k2);
    expect(x.asSet.length, equals(2), reason: 'set should have k1 and k2');
    expect(x.asSet.contains(k1), isTrue, reason: 'set should have k1 and k2');
    expect(x.asSet.contains(k2), isTrue, reason: 'set should have k1 and k2');
    expect(x.asSet.contains(k3), isFalse, reason: 'set should have k1 and k2');
    expect(x.toString(), equals(s1), reason: 'set should have k1 and k2');

    // Then unset one of those two. Let's unset a COPY of the key.
    bool res = x.asSet.remove(new VdlValue.copy(k1));
    expect(res, isTrue, reason: 'set should have removed k1');
    expect(x.asSet.length, equals(1), reason: 'set should have k2');
    expect(x.asSet.contains(k1), isFalse, reason: 'set should k2');
    expect(x.asSet.contains(k2), isTrue, reason: 'set should k2');
    expect(x.asSet.contains(k3), isFalse, reason: 'set should k2');
    expect(x.toString(), equals(s2), reason: 'set should have k2');
  } else {
    // Nothing else can do asSet.
    expect(() => x.asSet,
      throwsA(new isInstanceOf<StateError>()));
  }
}
void testAssignMap(VdlValue x) {
  if (x.kind == VdlKind.Map) {
    // The VdlValue is for a set of structs, that have I: int64, S: string
    // OR it's set[string]
    VdlValue k1, k2, k3;
    VdlValue v1 = int64Value(12);
    VdlValue v2 = int64Value(-5);
    String s1, s2;
    if (x.type.key == VdlTypes.String) {
      k1 = strValA;
      k2 = strValB;
      k3 = strValC;
      s1 = 'map[string]int64{"A": 12, "B": -5}';
      s2 = 'map[string]int64{"B": -5}';
    } else {
      k1 = keyVal1;
      k2 = keyVal2;
      k3 = keyVal3;
      s1 = 'map[IS struct{I int64;S string}]int64{{I: 1, S: "A"}: 12, {I: 2, S: "B"}: -5}';
      s2 = 'map[IS struct{I int64;S string}]int64{{I: 2, S: "B"}: -5}';
    }

    // The map starts out as empty and has no keys.
    expect(x.asMap.length, isZero, reason: 'map should be empty');
    expect(x.asMap[k1], isNull, reason: 'map should be empty');
    expect(x.asMap[k2], isNull, reason: 'map should be empty');
    expect(x.asMap[k3], isNull, reason: 'map should be empty');

    // Let's assign the first two keys.
    x.asMap[k1] = v1;
    x.asMap[k2] = v2;
    expect(x.asMap.length, equals(2), reason: 'map should have k1 and k2');
    expect(x.asMap[k1], equals(v1), reason: 'map should have k1 and k2');
    expect(x.asMap[k2], equals(v2), reason: 'map should have k1 and k2');
    expect(x.asMap[k3], isNull, reason: 'map should have k1 and k2');
    expect(x.toString(), equals(s1), reason: 'map should have k1 and k2');

    // Then unset one of those two. Let's unset a COPY of the key.
    VdlValue res = x.asMap.remove(new VdlValue.copy(k1));
    expect(res, isNotNull, reason: 'map should have removed k1');
    expect(x.asMap.length, equals(1), reason: 'map should have k2');
    expect(x.asMap[k1], isNull, reason: 'map should k2');
    expect(x.asMap[k2], equals(v2), reason: 'map should k2');
    expect(x.asMap[k3], isNull, reason: 'map should k2');
    expect(x.toString(), equals(s2), reason: 'map should have k2');
  } else {
    // Nothing else can do asMap.
    expect(() => x.asMap,
      throwsA(new isInstanceOf<StateError>()));
  }
}
void testAssignStruct(VdlValue x) {
  if (x.kind == VdlKind.Struct) {
    // This is an ABC struct (A string, B int32, C bool)
    x.structFieldByIndex(1).asInt = 1;
    expect(x.isZero, isFalse);
    expect(x.toString(), equals('ABCStruct struct{A string;B int32;C bool}{A: "", B: 1, C: false}'));

    // Can also assign a different field.
    x.structFieldByIndex(0).asString = 'a';

    // Can access the same field in 2 ways.
    expect(x.structFieldByIndex(2) == x.structFieldByName('C'), isTrue);

    // Can copy a struct and modify it independently.
    VdlValue y = new VdlValue.copy(x);
    expect(x == y, isTrue);
    y.structFieldByIndex(0).asString = 'boo';
    expect(x == y, isFalse);

    expect(y.isZero, isFalse);
    expect(y.toString(), equals('ABCStruct struct{A string;B int32;C bool}{A: "boo", B: 1, C: false}'));
  } else {
    expect(() => x.structFieldByIndex(0),
      throwsA(new isInstanceOf<StateError>()));
    expect(() => x.structFieldByName('A'),
      throwsA(new isInstanceOf<StateError>()));
  }
}
void testAssignUnion(VdlValue x) {
  if (x.kind == VdlKind.Union) {
    RepUnion u = x.unionField();
    expect(u.index, isZero);
    expect(u.value == stringValue(''), isTrue);

    VdlValue v2 = int32Value(2);
    x.assignUnionField(1, v2);
    RepUnion u2 = x.unionField();
    expect(u2.index, equals(1));
    expect(u2.value == v2, isTrue);

    expect(x.isZero, isFalse);
    expect(x.toString(), equals('ABCUnion union{A string;B int32;C bool}{B: 2}'));
  } else {
    expect(() => x.unionField(),
      throwsA(new isInstanceOf<StateError>()));
    expect(() => x.assignUnionField(0, null),
      throwsA(new isInstanceOf<StateError>()));
  }
}
void testAssignAny(VdlValue x) {
  if (x.kind == VdlKind.Any) {
    expect(x.elem, equals(null));

    VdlValue v1 = int64Value(1);
    x.assign(v1);
    expect(x.elem == v1, isTrue);
    expect(x.toString(), equals('any(int64(1))'));

    VdlValue strA = stringValue('A');
    x.assign(strA);
    expect(x.elem == v1, isFalse);
    expect(x.elem == strA, isTrue);
    expect(x.toString(), equals('any("A")'));
  } else {
    if (x.kind != VdlKind.Optional) {
      // Then we can't call elem.
      expect(() => x.elem,
        throwsA(new isInstanceOf<StateError>()));
    }
  }
}