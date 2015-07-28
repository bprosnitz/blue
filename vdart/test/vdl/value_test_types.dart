import '../../lib/src/vdl/vdl.dart';

VdlType namedBoolType = (new VdlPendingType()
  ..kind = VdlKind.Bool
  ..name = 'NamedBool'
).build();
class NamedBool extends VdlBool {
  static final VdlType vdlType = namedBoolType;

  const NamedBool.zero() : super.zero();
  const NamedBool(bool value) : super(value);
}

VdlType namedStringType = namedType(VdlTypes.String, 'NamedString');
class NamedString extends VdlString {
  static final VdlType vdlType = namedStringType;

  const NamedString.zero() : super.zero();
  const NamedString(String value) : super(value);
}

VdlType namedByteType = (new VdlPendingType()
  ..kind = VdlKind.Byte
  ..name = 'NamedByte'
).build();
class NamedByte extends VdlByte {
  static final VdlType vdlType = namedByteType;

  const NamedByte.zero() : super.zero();
  const NamedByte(int value) : super(value);
}

VdlType stringListType = (new VdlPendingType()
  ..kind = VdlKind.List
  ..elem = VdlTypes.String
).build();
class StringList extends VdlList<String> {
  static final VdlType vdlType = stringListType;
  StringList.zero() : super.zero();
  StringList(List<String> value) : super(value);
}

VdlType boolListType = (new VdlPendingType()
  ..kind = VdlKind.List
  ..elem = VdlTypes.Bool
).build();
class BoolList extends VdlList<bool> {
  static final VdlType vdlType = boolListType;

  BoolList.zero() : super.zero();
  BoolList(List<bool> value) : super(value);
}

// TODO(alexfandrianto): How does this build? I thought that arrays had to be
// named?
VdlType boolArray3Type = (new VdlPendingType()
  ..kind = VdlKind.Array
  ..name = 'BoolArray3'
  ..elem = VdlTypes.Bool
  ..len = 3
).build();
class BoolArray3 extends VdlArray<bool> {
  static final VdlType vdlType = boolArray3Type;

  BoolArray3.zero() : super.zero();
  BoolArray3(List<bool> value) : super(value);
}

VdlType boolComplexMapType = (new VdlPendingType()
  ..kind = VdlKind.Map
  ..key = VdlTypes.Bool
  ..elem = VdlTypes.Complex64
).build();
class BoolComplexMap extends VdlMap<bool, VdlComplex> {
  static final VdlType vdlType = stringListType;

  BoolComplexMap.zero() : super.zero();
  BoolComplexMap(Map<bool, VdlComplex> value) : super(value);
}

VdlType intSetType = (new VdlPendingType()
  ..kind = VdlKind.Set
  ..key = VdlTypes.Int16
).build();
class IntSet extends VdlSet<int> {
  static final VdlType vdlType = intSetType;

  IntSet.zero() : super.zero();
  IntSet(Set<int> value) : super(value);
}

VdlType inverseMapType = (new VdlPendingType()
  ..kind = VdlKind.Map
  ..key = VdlTypes.Int64
  ..elem = VdlTypes.Float64
).build();
class InverseMap extends VdlMap<int, double> {
  static final VdlType vdlType = inverseMapType;

  InverseMap.zero() : super.zero();
  InverseMap(Map<int, double> value) : super(value);
}

// Struct type
VdlType abcStructType = (new VdlPendingType()
  ..name = 'ABCStruct'
  ..kind = VdlKind.Struct
  ..fields = [
    new VdlPendingField('A', VdlTypes.String),
    new VdlPendingField('B', VdlTypes.Int32),
    new VdlPendingField('C', VdlTypes.Bool),
  ]
).build();
class ABCStruct extends VdlStruct {
  static final VdlType vdlType = abcStructType;

  String a;
  int b;
  bool c;

  ABCStruct(this.a, this.b, this.c);

  String toString() => '{A: ${a}, B: ${b}, C: ${c}}';
}

VdlType abcUnionType = (new VdlPendingType()
  ..name = 'ABCUnion'
  ..kind = VdlKind.Union
  ..fields = [
    new VdlPendingField('A', VdlTypes.String),
    new VdlPendingField('B', VdlTypes.Int32),
    new VdlPendingField('C', VdlTypes.Bool),
  ]
).build();

VdlType intStrStructType = (new VdlPendingType()
  ..name = 'IS'
  ..kind = VdlKind.Struct
  ..fields = [
    new VdlPendingField('I', VdlTypes.Int64),
    new VdlPendingField('S', VdlTypes.String),
  ]
).build();

// Recursive types and their corresponding "generated" classes.
VdlType dct = createDirectCycleType();
VdlType createDirectCycleType() {
  VdlPendingType directCycleType = new VdlPendingType();
  directCycleType.kind = VdlKind.List;
  directCycleType.name = 'CyclicList';
  directCycleType.elem = directCycleType;
  return directCycleType.build();
}
class DirectCycle extends VdlList<DirectCycle> {
  static final VdlType vdlType = dct;

  DirectCycle.zero() : super.zero();
  DirectCycle(List<DirectCycle> value) : super(value);
}

List<VdlType> icts = createIndirectCycleTypes();
List<VdlType> createIndirectCycleTypes() {
  var indirectCycleType = new VdlPendingType();
  var indirectCycleType2 = new VdlPendingType();
  indirectCycleType.kind = VdlKind.List;
  indirectCycleType.name = 'CyclicList1';
  indirectCycleType.elem = indirectCycleType2;
  indirectCycleType2.kind = VdlKind.List;
  indirectCycleType2.name = 'CyclicList2';
  indirectCycleType2.elem = indirectCycleType;

  return [indirectCycleType.build(), indirectCycleType2.build()];
}

VdlType ict = icts[0];
VdlType ict2 = icts[1];
class IndirectCycle extends VdlList<IndirectCycle2> {
  static final VdlType vdlType = ict;

  IndirectCycle.zero() : super.zero();
  IndirectCycle(List<IndirectCycle2> value) : super(value);
}
class IndirectCycle2 extends VdlList<IndirectCycle> {
  static final VdlType vdlType = ict;

  IndirectCycle2.zero() : super.zero();
  IndirectCycle2(List<IndirectCycle> value) : super(value);
}