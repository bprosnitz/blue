part of vom;

// Define these in vdl!

vdl.VdlType _makeTypeIdType() {
  vdl.VdlPendingType pt = new vdl.VdlPendingType()
  ..kind = vdl.VdlKind.Uint64
  ..name = 'typeId';
  return pt.build();
}

vdl.VdlType _makeListType(vdl.VdlType elem) {
    vdl.VdlPendingType pt = new vdl.VdlPendingType()
    ..kind = vdl.VdlKind.List
    ..elem = elem;
    return pt.build();
}

class _WireNamed {
  static final vdl.VdlType vdlType = _makeVdlType();
  static vdl.VdlType _makeVdlType() {
    vdl.VdlPendingType pt = new vdl.VdlPendingType()
    ..name = 'wireNamed'
    ..kind = vdl.VdlKind.Struct
    ..fields = [
      new vdl.VdlPendingField('Name', vdl.VdlTypes.String),
      new vdl.VdlPendingField('Base', _makeTypeIdType()),
    ];
    return pt.build();
  }

  String name;
  int base;
}

class _WireEnum {
  static final vdl.VdlType vdlType = _makeVdlType();
  static vdl.VdlType _makeVdlType() {
    vdl.VdlPendingType pt = new vdl.VdlPendingType()
    ..name = 'wireEnum'
    ..kind = vdl.VdlKind.Struct
    ..fields = [
      new vdl.VdlPendingField('Name', vdl.VdlTypes.String),
      new vdl.VdlPendingField('Labels', _makeListType(vdl.VdlTypes.String)),
    ];
    return pt.build();
  }

  String name;
  List<String> labels;
}

class _WireArray {
  static final vdl.VdlType vdlType = _makeVdlType();
  static vdl.VdlType _makeVdlType() {
    vdl.VdlPendingType pt = new vdl.VdlPendingType()
    ..name = 'wireArray'
    ..kind = vdl.VdlKind.Struct
    ..fields = [
      new vdl.VdlPendingField('Name', vdl.VdlTypes.String),
      new vdl.VdlPendingField('Elem', _makeTypeIdType()),
      new vdl.VdlPendingField('Len', vdl.VdlTypes.Uint64)
    ];
    return pt.build();
  }

  String name;
  int elem;
  int len;
}


class _WireList {
  static final vdl.VdlType vdlType = _makeVdlType();
  static vdl.VdlType _makeVdlType() {
    vdl.VdlPendingType pt = new vdl.VdlPendingType()
    ..name = 'wireList'
    ..kind = vdl.VdlKind.Struct
    ..fields = [
      new vdl.VdlPendingField('Name', vdl.VdlTypes.String),
      new vdl.VdlPendingField('Elem', _makeTypeIdType()),
    ];
    return pt.build();
  }

  String name;
  int elem;
}

class _WireSet {
  static final vdl.VdlType vdlType = _makeVdlType();
  static vdl.VdlType _makeVdlType() {
    vdl.VdlPendingType pt = new vdl.VdlPendingType()
    ..name = 'wireSet'
    ..kind = vdl.VdlKind.Struct
    ..fields = [
      new vdl.VdlPendingField('Name', vdl.VdlTypes.String),
      new vdl.VdlPendingField('Key', _makeTypeIdType()),
    ];
    return pt.build();
  }

  String name;
  int key;
}

class _WireMap {
  static final vdl.VdlType vdlType = _makeVdlType();
  static vdl.VdlType _makeVdlType() {
    vdl.VdlPendingType pt = new vdl.VdlPendingType()
    ..name = 'wireMap'
    ..kind = vdl.VdlKind.Struct
    ..fields = [
      new vdl.VdlPendingField('Name', vdl.VdlTypes.String),
      new vdl.VdlPendingField('Key', _makeTypeIdType()),
      new vdl.VdlPendingField('Elem', _makeTypeIdType()),
    ];
    return pt.build();
  }

  String name;
  int key;
  int elem;
}

class _WireField {
  static final vdl.VdlType vdlType = _makeVdlType();
  static vdl.VdlType _makeVdlType() {
    vdl.VdlPendingType pt = new vdl.VdlPendingType()
    ..name = 'wireField'
    ..kind = vdl.VdlKind.Struct
    ..fields = [
      new vdl.VdlPendingField('Name', vdl.VdlTypes.String),
      new vdl.VdlPendingField('Type', _makeTypeIdType()),
    ];
    return pt.build();
  }

  String name;
  int type;
}

class _WireStruct {
  static final vdl.VdlType vdlType = _makeVdlType();
  static vdl.VdlType _makeVdlType() {
    vdl.VdlPendingType pt = new vdl.VdlPendingType()
    ..name = 'wireStruct'
    ..kind = vdl.VdlKind.Struct
    ..fields = [
      new vdl.VdlPendingField('Name', vdl.VdlTypes.String),
      new vdl.VdlPendingField('Fields', _makeListType(_WireField.vdlType)),
    ];
    return pt.build();
  }

  String name;
  int type;
}

class _WireUnion {
  static final vdl.VdlType vdlType = _makeVdlType();
  static vdl.VdlType _makeVdlType() {
    vdl.VdlPendingType pt = new vdl.VdlPendingType()
    ..name = 'wireUnion'
    ..kind = vdl.VdlKind.Struct
    ..fields = [
      new vdl.VdlPendingField('Name', vdl.VdlTypes.String),
      new vdl.VdlPendingField('Fields', _makeListType(_WireField.vdlType)),
    ];
    return pt.build();
  }

  String name;
  int type;
}

class _WireOptional {
  static final vdl.VdlType vdlType = _makeVdlType();
  static vdl.VdlType _makeVdlType() {
    vdl.VdlPendingType pt = new vdl.VdlPendingType()
    ..name = 'wireOptional'
    ..kind = vdl.VdlKind.Struct
    ..fields = [
      new vdl.VdlPendingField('Name', vdl.VdlTypes.String),
      new vdl.VdlPendingField('Elem', _makeTypeIdType()),
    ];
    return pt.build();
  }

  String name;
  int elem;
}

const int _WireCtrlNil = 0xe0;
const int _WireCtrlEnd = 0xe1;
