part of vom;


class VomMessage {}

class VomValueMessage extends VomMessage {
  // The type of the value.
  final vdl.VdlType type;
  // Vom bytes representing the value.
  final List<int> bytes;

  VomValueMessage(this.type, this.bytes);

  String toString() => 'VomValueMessage[type=${type}, bytes.length=${bytes.length}]';
}

class VomTypeMessage extends VomMessage {
  // Type ID of the type being declared.
  final int newTypeId;
  // Type used to define the type, e.g. _WireStruct, _WireEnum, etc.
  final vdl.VdlType wireDefType;
  // Bytes representing the type definition.
  final List<int> wireDefBytes;

  VomTypeMessage(this.newTypeId, this.wireDefType, this.wireDefBytes);

  String toString() => 'VomTypeMessage[newTypeId=${newTypeId}, wireDefType=${wireDefType}, wireDefBytes.length=${wireDefBytes.length}]';
}