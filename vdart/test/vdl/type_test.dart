library vdl;

import 'package:test/test.dart';

part '../../lib/src/vdl/type.part.dart';


void main() {
  group('PendingType', () {
    var examples = makePendingTypeExamples();

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
                throwsA(new isInstanceOf<TypeValidationError>()));
            });
          });
        }
      }
    });
  });
}

class PendingTypeExample {
  String testName;
  PendingType input;
  String expectedToString;
  bool isValid;

  PendingTypeExample(String testName, PendingType input,
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
  var primitive = new PendingType();
  primitive.kind = Kind.Int32;
  primitive.name = 'aname';
  var primitiveToString = 'aname int32';
  examples.add(new PendingTypeExample('named primitive', primitive,
    primitiveToString, true));

  var namelessPrimitive = new PendingType();
  namelessPrimitive.kind = Kind.Int32;
  var namelessPrimitiveToString = 'int32';
  examples.add(new PendingTypeExample('nameless primitive', namelessPrimitive,
    namelessPrimitiveToString, true));

  var any = new PendingType();
  any.kind = Kind.Any;
  var anyToString = 'any';
  examples.add(new PendingTypeExample('any', any, anyToString, true));

  var optional = new PendingType();
  optional.kind = Kind.Optional;
  optional.elem = new PendingType();
  optional.elem.kind = Kind.Bool;
  optional.elem.name = 'NamedBool';
  var optionalToString = '?NamedBool bool';
  examples.add(new PendingTypeExample('optional', optional,
    optionalToString, true));

  var enumType = new PendingType();
  enumType.kind = Kind.Enum;
  enumType.name = 'CustomEnum';
  enumType.labels = ['A', 'B'];
  var enumTypeToString = 'CustomEnum enum{A;B}';
  examples.add(new PendingTypeExample('enum', enumType, enumTypeToString,
    true));

  var arrayType = new PendingType();
  arrayType.kind = Kind.Array;
  arrayType.name = 'CustomArray';
  arrayType.len = 4;
  arrayType.elem = primitive;
  var arrayTypeToString = 'CustomArray [4]aname int32';
  examples.add(new PendingTypeExample('array', arrayType, arrayTypeToString,
    true));

  var listType = new PendingType();
  listType.kind = Kind.List;
  listType.name = 'CustomList';
  listType.elem = primitive;
  var listTypeToString = 'CustomList []aname int32';
  examples.add(new PendingTypeExample('list', listType, listTypeToString,
    true));

  var setType = new PendingType();
  setType.kind = Kind.Set;
  setType.name = 'CustomSet';
  setType.key = primitive;
  var setTypeToString = 'CustomSet set[aname int32]';
  examples.add(new PendingTypeExample('set', setType, setTypeToString,
    true));

  var mapType = new PendingType();
  mapType.kind = Kind.Map;
  mapType.name = 'CustomSet';
  mapType.key = primitive;
  mapType.elem = optional;
  var mapTypeToString = 'CustomSet map[aname int32]?NamedBool bool';
  examples.add(new PendingTypeExample('map', mapType, mapTypeToString,
    true));

  var structType = new PendingType();
  structType.kind = Kind.Struct;
  structType.name = 'AStruct';
  structType.fields = [
    new PendingField('A', primitive),
    new PendingField('B', namelessPrimitive),
  ];
  var structTypeToString = 'AStruct struct{A aname int32;B int32}';
  examples.add(new PendingTypeExample('struct', structType, structTypeToString,
    true));

  var unionType = new PendingType();
  unionType.kind = Kind.Union;
  unionType.name = 'AUnion';
  unionType.fields = [
    new PendingField('A', primitive),
    new PendingField('B', namelessPrimitive),
  ];
  var unionTypeToString = 'AUnion union{A aname int32;B int32}';
  examples.add(new PendingTypeExample('union', unionType, unionTypeToString,
    true));

  var directCycleType = new PendingType();
  directCycleType.kind = Kind.List;
  directCycleType.name = 'CyclicList';
  directCycleType.elem = directCycleType;
  var directCycleTypeToString = 'CyclicList []CyclicList';
  examples.add(new PendingTypeExample(
      'direct cycle', directCycleType, directCycleTypeToString, true));

  var indirectCycleType = new PendingType();
  var indirectCycleType2 = new PendingType();
  indirectCycleType.kind = Kind.List;
  indirectCycleType.name = 'CyclicList1';
  indirectCycleType.elem = indirectCycleType2;
  indirectCycleType2.kind = Kind.List;
  indirectCycleType2.name = 'CyclicList2';
  indirectCycleType2.elem = indirectCycleType;
  var indirectCycleTypeToString = 'CyclicList1 []CyclicList2 []CyclicList1';
  examples.add(new PendingTypeExample(
      'indirect cycle', indirectCycleType, indirectCycleTypeToString, true));

  // Invalid examples:
  var kindless = new PendingType();
  var kindlessToString = '[MISSING KIND FIELD]';
  examples.add(new PendingTypeExample('kindless type', kindless,
    kindlessToString, false));

  var namedTypeObject = new PendingType();
  namedTypeObject.kind = Kind.TypeObject;
  namedTypeObject.name = 'InvalidName';
  var namedTypeObjectToString = 'InvalidName typeobject';
  examples.add(new PendingTypeExample('named typeobject',
    namedTypeObject, namedTypeObjectToString, false));

  var namedAny = new PendingType();
  namedAny.kind = Kind.Any;
  namedAny.name = 'InvalidName';
  var namedAnyToString = 'InvalidName any';
  examples.add(new PendingTypeExample('named any', namedAny,
    namedAnyToString, false));

  var namedOptional = new PendingType();
  namedOptional.kind = Kind.Optional;
  namedOptional.elem = new PendingType();
  namedOptional.elem.kind = Kind.Bool;
  namedOptional.elem.name = 'NamedBool';
  namedOptional.name = 'InvalidName';
  var namedOptionalToString = 'InvalidName ?NamedBool bool';
  examples.add(new PendingTypeExample('optional', namedOptional,
    namedOptionalToString, false));

  var extraFieldPrimitive = new PendingType();
  extraFieldPrimitive.kind = Kind.Float32;
  extraFieldPrimitive.len = 5;
  var extraFieldPrimitiveToString = 'float32';
  examples.add(new PendingTypeExample('extra field primitive',
    extraFieldPrimitive, extraFieldPrimitiveToString, false));

  var enumMissingLabels = new PendingType();
  enumMissingLabels.kind = Kind.Enum;
  enumMissingLabels.name = 'MissingLabels';
  var enumMissingLabelsToString =
    'MissingLabels enum{[MISSING LABELS FIELD]}';
  examples.add(new PendingTypeExample('enum with missing labels',
    enumMissingLabels, enumMissingLabelsToString, false));

  var arrayMissingLen = new PendingType();
  arrayMissingLen.kind = Kind.Array;
  arrayMissingLen.elem = primitive;
  var arrayMissingLenToString = '[[MISSING LEN FIELD]]aname int32';
  examples.add(new PendingTypeExample('array missing len',
    arrayMissingLen, arrayMissingLenToString, false));

  var arrayMissingElem = new PendingType();
  arrayMissingElem.kind = Kind.Array;
  arrayMissingElem.len = 5;
  var arrayMissingElemToString = '[5][MISSING ELEM FIELD]';
  examples.add(new PendingTypeExample('array missing elem',
    arrayMissingElem, arrayMissingElemToString, false));

  var listWithLen = new PendingType();
  listWithLen.kind = Kind.List;
  listWithLen.elem = primitive;
  listWithLen.len = 4;
  var listWithLenToString = '[]aname int32';
  examples.add(new PendingTypeExample('list with len',
    listWithLen, listWithLenToString, false));

  var listMissingElem = new PendingType();
  listMissingElem.kind = Kind.List;
  var listMissingElemToString = '[][MISSING ELEM FIELD]';
  examples.add(new PendingTypeExample('list missing elem',
    listMissingElem, listMissingElemToString, false));

  var setMissingKey = new PendingType();
  setMissingKey.kind = Kind.Set;
  var setMissingKeyToString = 'set[[MISSING KEY FIELD]]';
  examples.add(new PendingTypeExample('set missing key',
    setMissingKey, setMissingKeyToString, false));

  var mapMissingElem = new PendingType();
  mapMissingElem.kind = Kind.Map;
  mapMissingElem.key = primitive;
  var mapMissingElemToString = 'map[aname int32][MISSING ELEM FIELD]';
  examples.add(new PendingTypeExample('map missing elem',
    mapMissingElem, mapMissingElemToString, false));

  var mapMissingKey = new PendingType();
  mapMissingKey.kind = Kind.Map;
  mapMissingKey.elem = primitive;
  var mapMissingKeyToString = 'map[[MISSING KEY FIELD]]aname int32';
  examples.add(new PendingTypeExample('map missing key',
    mapMissingKey, mapMissingKeyToString, false));

  var fieldlessStruct = new PendingType();
  fieldlessStruct.kind = Kind.Struct;
  fieldlessStruct.name = 'StructName';
  var fieldlessStructToString = 'StructName struct{[MISSING FIELDS FIELD]}';
  examples.add(new PendingTypeExample('struct missing fields field',
    fieldlessStruct, fieldlessStructToString, false));

  var missingFieldTypeStruct = new PendingType();
  missingFieldTypeStruct.kind = Kind.Struct;
  missingFieldTypeStruct.name = 'StructName';
  missingFieldTypeStruct.fields = [
    new PendingField('structField', null),
  ];
  var missingFieldTypeStructToString =
    'StructName struct{structField [MISSING FIELD.TYPE FIELD]}';
  examples.add(new PendingTypeExample('struct missing field type',
    missingFieldTypeStruct, missingFieldTypeStructToString, false));

  var missingFieldNameStruct = new PendingType();
  missingFieldNameStruct.kind = Kind.Struct;
  missingFieldNameStruct.name = 'StructName';
  missingFieldNameStruct.fields = [
    new PendingField(null, primitive),
  ];
  var missingFieldNameStructToString =
    'StructName struct{[MISSING FIELD.NAME FIELD] aname int32}';
  examples.add(new PendingTypeExample('struct missing field type',
    missingFieldNameStruct, missingFieldNameStructToString, false));

  var fieldlessUnion = new PendingType();
  fieldlessUnion.kind = Kind.Union;
  fieldlessUnion.name = 'UnionName';
  var fieldlessUnionToString = 'UnionName union{[MISSING FIELDS FIELD]}';
  examples.add(new PendingTypeExample('union missing fields field',
    fieldlessUnion, fieldlessUnionToString, false));

  var missingFieldTypeUnion = new PendingType();
  missingFieldTypeUnion.kind = Kind.Union;
  missingFieldTypeUnion.name = 'UnionName';
  missingFieldTypeUnion.fields = [
    new PendingField('unionField', null),
  ];
  var missingFieldTypeUnionToString =
    'UnionName union{unionField [MISSING FIELD.TYPE FIELD]}';
  examples.add(new PendingTypeExample('union missing field type',
    missingFieldTypeUnion, missingFieldTypeUnionToString, false));

  var missingFieldNameUnion = new PendingType();
  missingFieldNameUnion.kind = Kind.Union;
  missingFieldNameUnion.name = 'UnionName';
  missingFieldNameUnion.fields = [
    new PendingField(null, primitive),
  ];
  var missingFieldNameUnionToString =
    'UnionName union{[MISSING FIELD.NAME FIELD] aname int32}';
  examples.add(new PendingTypeExample('union missing field type',
    missingFieldNameUnion, missingFieldNameUnionToString, false));

  return examples;
}