library vdl;

import 'package:test/test.dart';

import 'dart:collection';

part '../../lib/src/vdl/type.part.dart';


void main() {
  var examples = makePendingTypeExamples();

  group('VdlPendingType', () {
    group('toString() - unique string generation', () {
      for (var example in examples) {
        test(example.testName, () {
          expect(example.input.toString(), equals(example.expectedToString));
        });
      }
    });

    group('validate', () {
      for (var example in examples) {
        if (example.isValid) {
          group('valid', () {
            test(example.testName, () {
              expect(() => example.input.validate(), returnsNormally);
            });
          });
        } else {
          group('invalid', () {
            test(example.testName, () {
              expect(() => example.input.validate(),
                throwsA(new isInstanceOf<VdlTypeValidationError>()));
            });
          });
        }
      }
    });
  });

  group('VdlType', () {
    group('Building VdlType', () {
      for (var example in examples) {
        if (example.isValid) {
          test(example.testName, () {
            deepEquals(example.input, example.input.build());
          });
        } else {
          test(example.testName, () {
            expect(() => example.input.build(),
              throwsA(new isInstanceOf<VdlTypeValidationError>()));
          });
        }
      }
    });
    group('Hash consing', () {
      var validExamples = examples.where((PendingTypeExample e) {
        return e.isValid;
      });
      group('Identical items have the same reference', () {
        for (var example in validExamples) {
          test(example.testName, () {
            var type1 = example.input.build();
            var type2 = example.input.build();
            expect(identical(type1, type2), isTrue);
            expect(type1, equals(type2));
          });
        }
      });
      group('Different items don\'t have the same reference', () {
        for (var example1 in validExamples) {
          for (var example2 in validExamples) {
            if (identical(example1, example2)) {
              continue; // Skip identical
            }
            test('${example1.testName} and ${example2.testName}', () {
              var type1 = example1.input.build();
              var type2 = example2.input.build();
              expect(identical(type1, type2), isFalse);
              expect(type1, isNot(equals(type2)));
            });
          }
        }
      });
    });
  });
}

class Pair<K, V> {
  final K key;
  final V value;
  Pair(K key, V value) :
    key = key,
    value = value;
}
void deepEquals(VdlPendingType pt, VdlType t) {
  var correspondences = new Map<VdlPendingType, VdlType>();
  var toProcess = new Queue<Pair<VdlPendingType, VdlType>>();
  toProcess.add(new Pair<VdlPendingType, VdlType>(pt, t));
  while(toProcess.isNotEmpty) {
    var next = toProcess.removeFirst();
    VdlPendingType nextPt = next.key;
    VdlType nextType = next.value;
    expect(nextPt, isNotNull);
    expect(nextType, isNotNull);

    if (correspondences.containsKey(nextPt)) {
      continue;
    }
    correspondences[nextPt] = nextType;

    if (nextPt.elem != null) {
      expect(nextType.elem, isNotNull);
      toProcess.add(new Pair<VdlPendingType, VdlType>(nextPt.elem, nextType.elem));
    } else {
      expect(nextType.elem, isNull);
    }
    if (nextPt.key != null) {
      expect(nextType.key, isNotNull);
      toProcess.add(new Pair<VdlPendingType, VdlType>(nextPt.key, nextType.key));
    } else {
      expect(nextType.key, isNull);
    }
    if (nextPt.fields != null) {
      for (var i = 0; i < nextPt.fields.length; i++) {
        var ptFieldType = nextPt.fields[i].type;
        var typeFieldType = nextType.fields[i].type;
        expect(ptFieldType, isNotNull);
        expect(typeFieldType, isNotNull);
        toProcess.add(new Pair<VdlPendingType, VdlType>(ptFieldType, typeFieldType));
      }
    }
  }

  correspondences.forEach((pendingType, type) {
    expect(type.kind, equals(pendingType.kind));
    expect(type.name, equals(pendingType.name));
    expect(type.labels, equals(pendingType.labels));
    expect(type.len, equals(pendingType.len));
    if (type.elem != null) {
      expect(type.elem, equals(correspondences[pendingType.elem]));
    } else {
      expect(pendingType.elem, isNull);
    }
    if (type.key != null) {
      expect(type.key, equals(correspondences[pendingType.key]));
    } else {
      expect(pendingType.key, isNull);
    }
    if(type.fields != null) {
      expect(type.fields.length, equals(pendingType.fields.length));
      for (var i = 0; i < type.fields.length; i++) {
        expect(type.fields[i].name, equals(pendingType.fields[i].name));
        expect(type.fields[i].type,
          equals(correspondences[pendingType.fields[i].type]));
      }
    }
  });
}

class PendingTypeExample {
  String testName;
  VdlPendingType input;
  String expectedToString;
  bool isValid;

  PendingTypeExample(String testName, VdlPendingType input,
    String expectedToString, bool isValid) {
    this.testName = testName;
    this.input = input;
    this.expectedToString = expectedToString;
    this.isValid = isValid;
  }
}


List<PendingTypeExample> makePendingTypeExamples() {
  List<PendingTypeExample> examples = [];

  // Valid examples first.
  var primitive = new VdlPendingType();
  primitive.kind = VdlKind.Int32;
  primitive.name = 'aname';
  var primitiveToString = 'aname int32';
  examples.add(new PendingTypeExample('named primitive', primitive,
    primitiveToString, true));

  var namelessPrimitive = new VdlPendingType();
  namelessPrimitive.kind = VdlKind.Int32;
  var namelessPrimitiveToString = 'int32';
  examples.add(new PendingTypeExample('nameless primitive', namelessPrimitive,
    namelessPrimitiveToString, true));

  var any = new VdlPendingType();
  any.kind = VdlKind.Any;
  var anyToString = 'any';
  examples.add(new PendingTypeExample('any', any, anyToString, true));

  var optional = new VdlPendingType();
  optional.kind = VdlKind.Optional;
  optional.elem = new VdlPendingType();
  optional.elem.kind = VdlKind.Bool;
  optional.elem.name = 'NamedBool';
  var optionalToString = '?NamedBool bool';
  examples.add(new PendingTypeExample('optional', optional,
    optionalToString, true));

  var enumType = new VdlPendingType();
  enumType.kind = VdlKind.Enum;
  enumType.name = 'CustomEnum';
  enumType.labels = ['A', 'B'];
  var enumTypeToString = 'CustomEnum enum{A;B}';
  examples.add(new PendingTypeExample('enum', enumType, enumTypeToString,
    true));

  var arrayType = new VdlPendingType();
  arrayType.kind = VdlKind.Array;
  arrayType.name = 'CustomArray';
  arrayType.len = 4;
  arrayType.elem = primitive;
  var arrayTypeToString = 'CustomArray [4]aname int32';
  examples.add(new PendingTypeExample('array', arrayType, arrayTypeToString,
    true));

  var listType = new VdlPendingType();
  listType.kind = VdlKind.List;
  listType.name = 'CustomList';
  listType.elem = primitive;
  var listTypeToString = 'CustomList []aname int32';
  examples.add(new PendingTypeExample('list', listType, listTypeToString,
    true));

  var setType = new VdlPendingType();
  setType.kind = VdlKind.Set;
  setType.name = 'CustomSet';
  setType.key = primitive;
  var setTypeToString = 'CustomSet set[aname int32]';
  examples.add(new PendingTypeExample('set', setType, setTypeToString,
    true));

  var mapType = new VdlPendingType();
  mapType.kind = VdlKind.Map;
  mapType.name = 'CustomSet';
  mapType.key = primitive;
  mapType.elem = optional;
  var mapTypeToString = 'CustomSet map[aname int32]?NamedBool bool';
  examples.add(new PendingTypeExample('map', mapType, mapTypeToString,
    true));

  var structType = new VdlPendingType();
  structType.kind = VdlKind.Struct;
  structType.name = 'AStruct';
  structType.fields = [
    new VdlPendingField('A', primitive),
    new VdlPendingField('B', namelessPrimitive),
  ];
  var structTypeToString = 'AStruct struct{A aname int32;B int32}';
  examples.add(new PendingTypeExample('struct', structType, structTypeToString,
    true));

  var unionType = new VdlPendingType();
  unionType.kind = VdlKind.Union;
  unionType.name = 'AUnion';
  unionType.fields = [
    new VdlPendingField('A', primitive),
    new VdlPendingField('B', namelessPrimitive),
  ];
  var unionTypeToString = 'AUnion union{A aname int32;B int32}';
  examples.add(new PendingTypeExample('union', unionType, unionTypeToString,
    true));

  var directCycleType = new VdlPendingType();
  directCycleType.kind = VdlKind.List;
  directCycleType.name = 'CyclicList';
  directCycleType.elem = directCycleType;
  var directCycleTypeToString = 'CyclicList []CyclicList';
  examples.add(new PendingTypeExample(
      'direct cycle', directCycleType, directCycleTypeToString, true));

  var indirectCycleType = new VdlPendingType();
  var indirectCycleType2 = new VdlPendingType();
  indirectCycleType.kind = VdlKind.List;
  indirectCycleType.name = 'CyclicList1';
  indirectCycleType.elem = indirectCycleType2;
  indirectCycleType2.kind = VdlKind.List;
  indirectCycleType2.name = 'CyclicList2';
  indirectCycleType2.elem = indirectCycleType;
  var indirectCycleTypeToString = 'CyclicList1 []CyclicList2 []CyclicList1';
  examples.add(new PendingTypeExample(
      'indirect cycle', indirectCycleType, indirectCycleTypeToString, true));

  // Invalid examples:
  var kindless = new VdlPendingType();
  var kindlessToString = '[MISSING KIND FIELD]';
  examples.add(new PendingTypeExample('kindless type', kindless,
    kindlessToString, false));

  var namedTypeObject = new VdlPendingType();
  namedTypeObject.kind = VdlKind.TypeObject;
  namedTypeObject.name = 'InvalidName';
  var namedTypeObjectToString = 'InvalidName typeobject';
  examples.add(new PendingTypeExample('named typeobject',
    namedTypeObject, namedTypeObjectToString, false));

  var namedAny = new VdlPendingType();
  namedAny.kind = VdlKind.Any;
  namedAny.name = 'InvalidName';
  var namedAnyToString = 'InvalidName any';
  examples.add(new PendingTypeExample('named any', namedAny,
    namedAnyToString, false));

  var namedOptional = new VdlPendingType();
  namedOptional.kind = VdlKind.Optional;
  namedOptional.elem = new VdlPendingType();
  namedOptional.elem.kind = VdlKind.Bool;
  namedOptional.elem.name = 'NamedBool';
  namedOptional.name = 'InvalidName';
  var namedOptionalToString = 'InvalidName ?NamedBool bool';
  examples.add(new PendingTypeExample('optional', namedOptional,
    namedOptionalToString, false));

  var extraFieldPrimitive = new VdlPendingType();
  extraFieldPrimitive.kind = VdlKind.Float32;
  extraFieldPrimitive.len = 5;
  var extraFieldPrimitiveToString = 'float32';
  examples.add(new PendingTypeExample('extra field primitive',
    extraFieldPrimitive, extraFieldPrimitiveToString, false));

  var enumMissingLabels = new VdlPendingType();
  enumMissingLabels.kind = VdlKind.Enum;
  enumMissingLabels.name = 'MissingLabels';
  var enumMissingLabelsToString =
    'MissingLabels enum{[MISSING LABELS FIELD]}';
  examples.add(new PendingTypeExample('enum with missing labels',
    enumMissingLabels, enumMissingLabelsToString, false));

  var arrayMissingLen = new VdlPendingType();
  arrayMissingLen.kind = VdlKind.Array;
  arrayMissingLen.elem = primitive;
  var arrayMissingLenToString = '[[MISSING LEN FIELD]]aname int32';
  examples.add(new PendingTypeExample('array missing len',
    arrayMissingLen, arrayMissingLenToString, false));

  var arrayMissingElem = new VdlPendingType();
  arrayMissingElem.kind = VdlKind.Array;
  arrayMissingElem.len = 5;
  var arrayMissingElemToString = '[5][MISSING ELEM FIELD]';
  examples.add(new PendingTypeExample('array missing elem',
    arrayMissingElem, arrayMissingElemToString, false));

  var listWithLen = new VdlPendingType();
  listWithLen.kind = VdlKind.List;
  listWithLen.elem = primitive;
  listWithLen.len = 4;
  var listWithLenToString = '[]aname int32';
  examples.add(new PendingTypeExample('list with len',
    listWithLen, listWithLenToString, false));

  var listMissingElem = new VdlPendingType();
  listMissingElem.kind = VdlKind.List;
  var listMissingElemToString = '[][MISSING ELEM FIELD]';
  examples.add(new PendingTypeExample('list missing elem',
    listMissingElem, listMissingElemToString, false));

  var setMissingKey = new VdlPendingType();
  setMissingKey.kind = VdlKind.Set;
  var setMissingKeyToString = 'set[[MISSING KEY FIELD]]';
  examples.add(new PendingTypeExample('set missing key',
    setMissingKey, setMissingKeyToString, false));

  var mapMissingElem = new VdlPendingType();
  mapMissingElem.kind = VdlKind.Map;
  mapMissingElem.key = primitive;
  var mapMissingElemToString = 'map[aname int32][MISSING ELEM FIELD]';
  examples.add(new PendingTypeExample('map missing elem',
    mapMissingElem, mapMissingElemToString, false));

  var mapMissingKey = new VdlPendingType();
  mapMissingKey.kind = VdlKind.Map;
  mapMissingKey.elem = primitive;
  var mapMissingKeyToString = 'map[[MISSING KEY FIELD]]aname int32';
  examples.add(new PendingTypeExample('map missing key',
    mapMissingKey, mapMissingKeyToString, false));

  var fieldlessStruct = new VdlPendingType();
  fieldlessStruct.kind = VdlKind.Struct;
  fieldlessStruct.name = 'StructName';
  var fieldlessStructToString = 'StructName struct{[MISSING FIELDS FIELD]}';
  examples.add(new PendingTypeExample('struct missing fields field',
    fieldlessStruct, fieldlessStructToString, false));

  var missingFieldTypeStruct = new VdlPendingType();
  missingFieldTypeStruct.kind = VdlKind.Struct;
  missingFieldTypeStruct.name = 'StructName';
  missingFieldTypeStruct.fields = [
    new VdlPendingField('structField', null),
  ];
  var missingFieldTypeStructToString =
    'StructName struct{structField [MISSING FIELD.TYPE FIELD]}';
  examples.add(new PendingTypeExample('struct missing field type',
    missingFieldTypeStruct, missingFieldTypeStructToString, false));

  var missingFieldNameStruct = new VdlPendingType();
  missingFieldNameStruct.kind = VdlKind.Struct;
  missingFieldNameStruct.name = 'StructName';
  missingFieldNameStruct.fields = [
    new VdlPendingField(null, primitive),
  ];
  var missingFieldNameStructToString =
    'StructName struct{[MISSING FIELD.NAME FIELD] aname int32}';
  examples.add(new PendingTypeExample('struct missing field type',
    missingFieldNameStruct, missingFieldNameStructToString, false));

  var fieldlessUnion = new VdlPendingType();
  fieldlessUnion.kind = VdlKind.Union;
  fieldlessUnion.name = 'UnionName';
  var fieldlessUnionToString = 'UnionName union{[MISSING FIELDS FIELD]}';
  examples.add(new PendingTypeExample('union missing fields field',
    fieldlessUnion, fieldlessUnionToString, false));

  var missingFieldTypeUnion = new VdlPendingType();
  missingFieldTypeUnion.kind = VdlKind.Union;
  missingFieldTypeUnion.name = 'UnionName';
  missingFieldTypeUnion.fields = [
    new VdlPendingField('unionField', null),
  ];
  var missingFieldTypeUnionToString =
    'UnionName union{unionField [MISSING FIELD.TYPE FIELD]}';
  examples.add(new PendingTypeExample('union missing field type',
    missingFieldTypeUnion, missingFieldTypeUnionToString, false));

  var missingFieldNameUnion = new VdlPendingType();
  missingFieldNameUnion.kind = VdlKind.Union;
  missingFieldNameUnion.name = 'UnionName';
  missingFieldNameUnion.fields = [
    new VdlPendingField(null, primitive),
  ];
  var missingFieldNameUnionToString =
    'UnionName union{[MISSING FIELD.NAME FIELD] aname int32}';
  examples.add(new PendingTypeExample('union missing field type',
    missingFieldNameUnion, missingFieldNameUnionToString, false));

  return examples;
}