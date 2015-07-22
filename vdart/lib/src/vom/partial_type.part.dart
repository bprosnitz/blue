part of vom;

/// _PartialVdlType is like VdlType, but directly corresponds to the wire type
/// representation as it is being read from the wire.
/// Consequentially, other referenced types may be missing or incomplete and
/// the type ids from the vom stream are stored instead.
class _PartialVdlType {
  final vdl.VdlKind kind;
  final String name;
  final List<String> labels;
  final int len;
  final int elemId;
  final int keyId;
  final List<_PartialVdlField> fields;

  final int baseId; // base type id for a named type

  _PartialVdlType._({this.kind, this.name, this.labels, this.len, this.elemId, this.keyId, this.fields, this.baseId});
  _PartialVdlType.namedType(name, baseId) :
    this._(name: name, baseId: baseId);
  _PartialVdlType.enumType(name, labels) :
    this._(kind: vdl.VdlKind.Enum, name: name, labels: labels);
  _PartialVdlType.arrayType(name, elemId, len) :
    this._(kind: vdl.VdlKind.Array, name: name, elemId: elemId, len: len);
  _PartialVdlType.listType(name, elemId) :
    this._(kind: vdl.VdlKind.List, name: name, elemId: elemId);
  _PartialVdlType.setType(name, keyId) :
    this._(kind: vdl.VdlKind.Set, name: name, keyId: keyId);
  _PartialVdlType.mapType(name, keyId, elemId) :
    this._(kind: vdl.VdlKind.Map, name: name, keyId: keyId, elemId: elemId);
  _PartialVdlType.structType(name, fields) :
    this._(kind: vdl.VdlKind.Struct, name: name, fields: fields);
  _PartialVdlType.unionType(name, fields) :
    this._(kind: vdl.VdlKind.Union, name: name, fields: fields);
  _PartialVdlType.optionalType(name, elemId) :
    this._(kind: vdl.VdlKind.Optional, name: name, elemId: elemId);

  String toString() => '_PartialVdlType[kind=${kind}, name=${name}, labels=${labels}, len=${len}, keyId=${keyId}, elemId=${elemId}, fields=${fields}, baseId=${baseId}';
  bool operator ==(other) {
    if (other is! _PartialVdlType) {
      return false;
    }
    return kind == other.kind &&
      name == other.name &&
      quiver_collection.listsEqual(labels, other.labels) &&
      len == other.len &&
      elemId == other.elemId &&
      keyId == other.keyId &&
      quiver_collection.listsEqual(fields, other.fields) &&
      baseId == other.baseId;
  }


  int _makeHashcode() {
      int labelHashCode = 0;
      if (labels != null) {
        labelHashCode = quiver_core.hashObjects(labels);
      }
      int fieldsHashCode = 0;
      if (fields != null) {
        fieldsHashCode = quiver_core.hashObjects(fields);
      }
      return quiver_core.hashObjects([
        kind, name, labelHashCode, len, elemId, keyId, fieldsHashCode, baseId
      ]);
  }
  int _cachedHashcode;
  int get hashCode {
    if (_cachedHashcode == null) {
      _cachedHashcode = _makeHashcode();
    }
    assert(_cachedHashcode == _makeHashcode());
    return _cachedHashcode;
  }
}

class _PartialVdlField {
  final String name;
  final int type;
  _PartialVdlField(this.name, this.type);

  String toString() => '_PartialVdlField[name=${name}, type=${type}]';
  bool operator ==(other) {
    if (other is! _PartialVdlField) {
      return false;
    }
    return name == other.name && type == other.type;
  }
  int get hashCode => quiver_core.hash2(name, type);
}
