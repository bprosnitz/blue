import 'package:test/test.dart';

import 'dart:collection';
import '../../lib/src/collection/collection.dart' as collection;
import '../../lib/src/vdl/vdl.dart' as vdl;

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
                throwsA(new isInstanceOf<vdl.VdlTypeValidationError>()));
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
              throwsA(new isInstanceOf<vdl.VdlTypeValidationError>()));
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

void deepEquals(vdl.VdlPendingType pt, vdl.VdlType t) {
  var correspondences = new Map<vdl.VdlPendingType, vdl.VdlType>();
  var toProcess = new Queue<collection.Pair<vdl.VdlPendingType, vdl.VdlType>>();
  toProcess.add(new collection.Pair<vdl.VdlPendingType, vdl.VdlType>(pt, t));
  while(toProcess.isNotEmpty) {
    var next = toProcess.removeFirst();
    vdl.VdlPendingType nextPt = next.key;
    vdl.VdlType nextType = next.value;
    expect(nextPt, isNotNull);
    expect(nextType, isNotNull);

    if (correspondences.containsKey(nextPt)) {
      continue;
    }
    correspondences[nextPt] = nextType;

    if (nextPt.elem != null) {
      expect(nextType.elem, isNotNull);
      toProcess.add(new collection.Pair<vdl.VdlPendingType, vdl.VdlType>(nextPt.elem, nextType.elem));
    } else {
      expect(nextType.elem, isNull);
    }
    if (nextPt.key != null) {
      expect(nextType.key, isNotNull);
      toProcess.add(new collection.Pair<vdl.VdlPendingType, vdl.VdlType>(nextPt.key, nextType.key));
    } else {
      expect(nextType.key, isNull);
    }
    if (nextPt.fields != null) {
      for (var i = 0; i < nextPt.fields.length; i++) {
        var ptFieldType = nextPt.fields[i].type;
        var typeFieldType = nextType.fields[i].type;
        expect(ptFieldType, isNotNull);
        expect(typeFieldType, isNotNull);
        toProcess.add(new collection.Pair<vdl.VdlPendingType, vdl.VdlType>(ptFieldType, typeFieldType));
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
  vdl.VdlPendingType input;
  String expectedToString;
  bool isValid;

  PendingTypeExample(String testName, vdl.VdlPendingType input,
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
  var primitive = new vdl.VdlPendingType();
  primitive.kind = vdl.VdlKind.Int32;
  primitive.name = 'aname';
  var primitiveToString = 'aname int32';
  examples.add(new PendingTypeExample('named primitive', primitive,
    primitiveToString, true));

  var namelessPrimitive = new vdl.VdlPendingType();
  namelessPrimitive.kind = vdl.VdlKind.Int32;
  var namelessPrimitiveToString = 'int32';
  examples.add(new PendingTypeExample('nameless primitive', namelessPrimitive,
    namelessPrimitiveToString, true));

  var sameNameDiffType = new vdl.VdlPendingType();
  sameNameDiffType.kind = vdl.VdlKind.String;
  sameNameDiffType.name = 'aname';
  var sameNameDiffTypeToString = 'aname string';
  examples.add(new PendingTypeExample('primitive with same name as other type',
    sameNameDiffType,
    sameNameDiffTypeToString, true));

  var any = new vdl.VdlPendingType();
  any.kind = vdl.VdlKind.Any;
  var anyToString = 'any';
  examples.add(new PendingTypeExample('any', any, anyToString, true));

  var optional = new vdl.VdlPendingType();
  optional.kind = vdl.VdlKind.Optional;
  optional.elem = new vdl.VdlPendingType();
  optional.elem.kind = vdl.VdlKind.Bool;
  optional.elem.name = 'NamedBool';
  var optionalToString = '?NamedBool bool';
  examples.add(new PendingTypeExample('optional', optional,
    optionalToString, true));

  var enumType = new vdl.VdlPendingType();
  enumType.kind = vdl.VdlKind.Enum;
  enumType.name = 'CustomEnum';
  enumType.labels = ['A', 'B'];
  var enumTypeToString = 'CustomEnum enum{A;B}';
  examples.add(new PendingTypeExample('enum', enumType, enumTypeToString,
    true));

  var arrayType = new vdl.VdlPendingType();
  arrayType.kind = vdl.VdlKind.Array;
  arrayType.name = 'CustomArray';
  arrayType.len = 4;
  arrayType.elem = primitive;
  var arrayTypeToString = 'CustomArray [4]aname int32';
  examples.add(new PendingTypeExample('array', arrayType, arrayTypeToString,
    true));

  var listType = new vdl.VdlPendingType();
  listType.kind = vdl.VdlKind.List;
  listType.name = 'CustomList';
  listType.elem = primitive;
  var listTypeToString = 'CustomList []aname int32';
  examples.add(new PendingTypeExample('list', listType, listTypeToString,
    true));

  var setType = new vdl.VdlPendingType();
  setType.kind = vdl.VdlKind.Set;
  setType.name = 'CustomSet';
  setType.key = primitive;
  var setTypeToString = 'CustomSet set[aname int32]';
  examples.add(new PendingTypeExample('set', setType, setTypeToString,
    true));

  var mapType = new vdl.VdlPendingType();
  mapType.kind = vdl.VdlKind.Map;
  mapType.name = 'CustomSet';
  mapType.key = primitive;
  mapType.elem = optional;
  var mapTypeToString = 'CustomSet map[aname int32]?NamedBool bool';
  examples.add(new PendingTypeExample('map', mapType, mapTypeToString,
    true));

  var structType = new vdl.VdlPendingType();
  structType.kind = vdl.VdlKind.Struct;
  structType.name = 'AStruct';
  structType.fields = [
    new vdl.VdlPendingField('A', primitive),
    new vdl.VdlPendingField('B', namelessPrimitive),
  ];
  var structTypeToString = 'AStruct struct{A aname int32;B int32}';
  examples.add(new PendingTypeExample('struct', structType, structTypeToString,
    true));

  var unionType = new vdl.VdlPendingType();
  unionType.kind = vdl.VdlKind.Union;
  unionType.name = 'AUnion';
  unionType.fields = [
    new vdl.VdlPendingField('A', primitive),
    new vdl.VdlPendingField('B', namelessPrimitive),
  ];
  var unionTypeToString = 'AUnion union{A aname int32;B int32}';
  examples.add(new PendingTypeExample('union', unionType, unionTypeToString,
    true));

  var directCycleType = new vdl.VdlPendingType();
  directCycleType.kind = vdl.VdlKind.List;
  directCycleType.name = 'CyclicList';
  directCycleType.elem = directCycleType;
  var directCycleTypeToString = 'CyclicList []CyclicList';
  examples.add(new PendingTypeExample(
      'direct cycle', directCycleType, directCycleTypeToString, true));

  var indirectCycleType = new vdl.VdlPendingType();
  var indirectCycleType2 = new vdl.VdlPendingType();
  indirectCycleType.kind = vdl.VdlKind.List;
  indirectCycleType.name = 'CyclicList1';
  indirectCycleType.elem = indirectCycleType2;
  indirectCycleType2.kind = vdl.VdlKind.List;
  indirectCycleType2.name = 'CyclicList2';
  indirectCycleType2.elem = indirectCycleType;
  var indirectCycleTypeToString = 'CyclicList1 []CyclicList2 []CyclicList1';
  examples.add(new PendingTypeExample(
      'indirect cycle', indirectCycleType, indirectCycleTypeToString, true));

  // Invalid examples:
  var kindless = new vdl.VdlPendingType();
  var kindlessToString = '[MISSING KIND FIELD]';
  examples.add(new PendingTypeExample('kindless type', kindless,
    kindlessToString, false));

  var namedTypeObject = new vdl.VdlPendingType();
  namedTypeObject.kind = vdl.VdlKind.TypeObject;
  namedTypeObject.name = 'InvalidName';
  var namedTypeObjectToString = 'InvalidName typeobject';
  examples.add(new PendingTypeExample('named typeobject',
    namedTypeObject, namedTypeObjectToString, false));

  var namedAny = new vdl.VdlPendingType();
  namedAny.kind = vdl.VdlKind.Any;
  namedAny.name = 'InvalidName';
  var namedAnyToString = 'InvalidName any';
  examples.add(new PendingTypeExample('named any', namedAny,
    namedAnyToString, false));

  var namedOptional = new vdl.VdlPendingType();
  namedOptional.kind = vdl.VdlKind.Optional;
  namedOptional.elem = new vdl.VdlPendingType();
  namedOptional.elem.kind = vdl.VdlKind.Bool;
  namedOptional.elem.name = 'NamedBool';
  namedOptional.name = 'InvalidName';
  var namedOptionalToString = 'InvalidName ?NamedBool bool';
  examples.add(new PendingTypeExample('optional', namedOptional,
    namedOptionalToString, false));

  var extraFieldPrimitive = new vdl.VdlPendingType();
  extraFieldPrimitive.kind = vdl.VdlKind.Float32;
  extraFieldPrimitive.len = 5;
  var extraFieldPrimitiveToString = 'float32';
  examples.add(new PendingTypeExample('extra field primitive',
    extraFieldPrimitive, extraFieldPrimitiveToString, false));

  var enumMissingLabels = new vdl.VdlPendingType();
  enumMissingLabels.kind = vdl.VdlKind.Enum;
  enumMissingLabels.name = 'MissingLabels';
  var enumMissingLabelsToString =
    'MissingLabels enum{[MISSING LABELS FIELD]}';
  examples.add(new PendingTypeExample('enum with missing labels',
    enumMissingLabels, enumMissingLabelsToString, false));

  var arrayMissingLen = new vdl.VdlPendingType();
  arrayMissingLen.kind = vdl.VdlKind.Array;
  arrayMissingLen.elem = primitive;
  var arrayMissingLenToString = '[[MISSING LEN FIELD]]aname int32';
  examples.add(new PendingTypeExample('array missing len',
    arrayMissingLen, arrayMissingLenToString, false));

  var arrayMissingElem = new vdl.VdlPendingType();
  arrayMissingElem.kind = vdl.VdlKind.Array;
  arrayMissingElem.len = 5;
  var arrayMissingElemToString = '[5][MISSING ELEM FIELD]';
  examples.add(new PendingTypeExample('array missing elem',
    arrayMissingElem, arrayMissingElemToString, false));

  var listWithLen = new vdl.VdlPendingType();
  listWithLen.kind = vdl.VdlKind.List;
  listWithLen.elem = primitive;
  listWithLen.len = 4;
  var listWithLenToString = '[]aname int32';
  examples.add(new PendingTypeExample('list with len',
    listWithLen, listWithLenToString, false));

  var listMissingElem = new vdl.VdlPendingType();
  listMissingElem.kind = vdl.VdlKind.List;
  var listMissingElemToString = '[][MISSING ELEM FIELD]';
  examples.add(new PendingTypeExample('list missing elem',
    listMissingElem, listMissingElemToString, false));

  var setMissingKey = new vdl.VdlPendingType();
  setMissingKey.kind = vdl.VdlKind.Set;
  var setMissingKeyToString = 'set[[MISSING KEY FIELD]]';
  examples.add(new PendingTypeExample('set missing key',
    setMissingKey, setMissingKeyToString, false));

  var mapMissingElem = new vdl.VdlPendingType();
  mapMissingElem.kind = vdl.VdlKind.Map;
  mapMissingElem.key = primitive;
  var mapMissingElemToString = 'map[aname int32][MISSING ELEM FIELD]';
  examples.add(new PendingTypeExample('map missing elem',
    mapMissingElem, mapMissingElemToString, false));

  var mapMissingKey = new vdl.VdlPendingType();
  mapMissingKey.kind = vdl.VdlKind.Map;
  mapMissingKey.elem = primitive;
  var mapMissingKeyToString = 'map[[MISSING KEY FIELD]]aname int32';
  examples.add(new PendingTypeExample('map missing key',
    mapMissingKey, mapMissingKeyToString, false));

  var fieldlessStruct = new vdl.VdlPendingType();
  fieldlessStruct.kind = vdl.VdlKind.Struct;
  fieldlessStruct.name = 'StructName';
  var fieldlessStructToString = 'StructName struct{[MISSING FIELDS FIELD]}';
  examples.add(new PendingTypeExample('struct missing fields field',
    fieldlessStruct, fieldlessStructToString, false));

  var missingFieldTypeStruct = new vdl.VdlPendingType();
  missingFieldTypeStruct.kind = vdl.VdlKind.Struct;
  missingFieldTypeStruct.name = 'StructName';
  missingFieldTypeStruct.fields = [
    new vdl.VdlPendingField('structField', null),
  ];
  var missingFieldTypeStructToString =
    'StructName struct{structField [MISSING FIELD.TYPE FIELD]}';
  examples.add(new PendingTypeExample('struct missing field type',
    missingFieldTypeStruct, missingFieldTypeStructToString, false));

  var missingFieldNameStruct = new vdl.VdlPendingType();
  missingFieldNameStruct.kind = vdl.VdlKind.Struct;
  missingFieldNameStruct.name = 'StructName';
  missingFieldNameStruct.fields = [
    new vdl.VdlPendingField(null, primitive),
  ];
  var missingFieldNameStructToString =
    'StructName struct{[MISSING FIELD.NAME FIELD] aname int32}';
  examples.add(new PendingTypeExample('struct missing field type',
    missingFieldNameStruct, missingFieldNameStructToString, false));

  var fieldlessUnion = new vdl.VdlPendingType();
  fieldlessUnion.kind = vdl.VdlKind.Union;
  fieldlessUnion.name = 'UnionName';
  var fieldlessUnionToString = 'UnionName union{[MISSING FIELDS FIELD]}';
  examples.add(new PendingTypeExample('union missing fields field',
    fieldlessUnion, fieldlessUnionToString, false));

  var missingFieldTypeUnion = new vdl.VdlPendingType();
  missingFieldTypeUnion.kind = vdl.VdlKind.Union;
  missingFieldTypeUnion.name = 'UnionName';
  missingFieldTypeUnion.fields = [
    new vdl.VdlPendingField('unionField', null),
  ];
  var missingFieldTypeUnionToString =
    'UnionName union{unionField [MISSING FIELD.TYPE FIELD]}';
  examples.add(new PendingTypeExample('union missing field type',
    missingFieldTypeUnion, missingFieldTypeUnionToString, false));

  var missingFieldNameUnion = new vdl.VdlPendingType();
  missingFieldNameUnion.kind = vdl.VdlKind.Union;
  missingFieldNameUnion.name = 'UnionName';
  missingFieldNameUnion.fields = [
    new vdl.VdlPendingField(null, primitive),
  ];
  var missingFieldNameUnionToString =
    'UnionName union{[MISSING FIELD.NAME FIELD] aname int32}';
  examples.add(new PendingTypeExample('union missing field type',
    missingFieldNameUnion, missingFieldNameUnionToString, false));

  return examples;
}