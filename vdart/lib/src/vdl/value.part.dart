part of vdl;

/// VdlValue is the generic representation of any value in VDL.
/// VdlValue contains a superset of properties that each VDL type can set.
/// When decoding, if no known representation can be used, a VdlValue will be
/// returned.
class VdlValue {
  final VdlType type;

  // Represents all manner of values.
  // null (any/optional),
  // primitives (int, uint, bool, float, string, enum),
  // VdlValue (any)
  // VdlType (typeobject)
  // RepSequence (list/array/struct) Note: A struct's fields are its sequence.
  // typed_data.Uint8List (special case for byte lists and arrays)
  // RepSet (set)
  // RepMap (map)
  // VdlComplex (complex) *new compared to Go*
  dynamic _rep;

  // Constructors; all constructors require that the type be specified.
  VdlValue._(this.type, this._rep) {
    if (type == null) {
      throw new ArgumentError('vdl: VdlValue constructor received null type');
    }
  }

  // Construct the zero VdlValue for the given type.
  VdlValue.zero(VdlType t) : this._(t, _zeroRep(t));

  // Given a VdlValue, construct a copy of it.
  factory VdlValue.copy(VdlValue v) {
    if (v == null) {
      return null;
    }
    return new VdlValue._(v.type, _copyRep(v.type, v._rep));
  }

  // Obtain the zero value for the given type.
  // Note: Structs and Arrays require some internal values to be zero'd as well.
  // These will be initialized lazily, upon first access.
  // Unions also have this requirement, but are initialized immediately.
  static dynamic _zeroRep(VdlType t) {
    // Treat bytes specially; they are Uint8List instead of RepSequence.
    if (t.isBytes) {
      if (t.kind == VdlKind.Array) {
        return new typed_data.Uint8List(t.len);
      }
      return new typed_data.Uint8List(0);
    }
    switch (t.kind) {
      case VdlKind.Bool:
        return false;
      case VdlKind.Byte:
      case VdlKind.Uint16:
      case VdlKind.Uint32:
      case VdlKind.Uint64:
      case VdlKind.Int16:
      case VdlKind.Int32:
      case VdlKind.Int64:
        return 0;
      case VdlKind.Float32:
      case VdlKind.Float64:
        return 0.0;
      case VdlKind.Complex64:
      case VdlKind.Complex128:
        return new VdlComplex.zero();
      case VdlKind.String:
        return '';
      case VdlKind.Enum:
        return 0; // This is the enum index.
      case VdlKind.TypeObject:
        return VdlTypes.Any;
      case VdlKind.List:
      case VdlKind.Array:
      case VdlKind.Struct:
        return new RepSequence._(t);
      case VdlKind.Set:
        return new RepSet._();
      case VdlKind.Map:
        return new RepMap._();
      case VdlKind.Union:
        return new RepUnion._(t, 0, new VdlValue.zero(t.fields[0].type));
      case VdlKind.Any:
      case VdlKind.Optional:
        return null;
      default:
        throw new ArgumentError('vdl: unhandled kind ${t.kind}');
    }
  }

  // Returns true iff the given value represents the 0-value for the given type.
  static bool _isZeroRep(VdlType t, dynamic v) {
    switch (t.kind) {
      case VdlKind.Bool:
      case VdlKind.Byte:
      case VdlKind.Uint16:
      case VdlKind.Uint32:
      case VdlKind.Uint64:
      case VdlKind.Int16:
      case VdlKind.Int32:
      case VdlKind.Int64:
      case VdlKind.Float32:
      case VdlKind.Float64:
      case VdlKind.String:
      case VdlKind.Enum:
      case VdlKind.TypeObject:
      case VdlKind.Any:
      case VdlKind.Optional:
        return v == _zeroRep(t);
      case VdlKind.Complex64:
      case VdlKind.Complex128:
        return v.real == 0.0 && v.imag == 0.0;
      case VdlKind.List:
      case VdlKind.Set:
      case VdlKind.Map:
        return v.length == 0;
      case VdlKind.Array:
      case VdlKind.Struct:
        if (t.isBytes) {
          return v.where((elem) => (elem != 0)).length == 0;
        }
        return v.where((elem) => (!elem.isZero)).length == 0;
      case VdlKind.Union:
        return v.index == 0 && v.value.isZero;
      default:
        throw new ArgumentError('vdl: unhandled kind ${t.kind}');
    }
  }

  // Makes a copy of the representation (based on type/kind) and returns it.
  static dynamic _copyRep(VdlType t, dynamic rep) {
    switch(t.kind) {
      case VdlKind.Bool:
      case VdlKind.Byte:
      case VdlKind.Uint16:
      case VdlKind.Uint32:
      case VdlKind.Uint64:
      case VdlKind.Int16:
      case VdlKind.Int32:
      case VdlKind.Int64:
      case VdlKind.Float32:
      case VdlKind.Float64:
      case VdlKind.String:
      case VdlKind.Enum:
      case VdlKind.TypeObject:
        return rep; // nothing to be copied
      case VdlKind.Any:
      case VdlKind.Optional:
        return new VdlValue.copy(rep); // rep is a VdlValue
      case VdlKind.Complex64:
      case VdlKind.Complex128:
        return new VdlComplex(rep.real, rep.imag);
      case VdlKind.List:
      case VdlKind.Array:
      case VdlKind.Struct:
        if (t.isBytes) {
          return new typed_data.Uint8List.fromList(rep); // directly copy out byte lists.
        }
        return new RepSequence._fromList(t, rep);
      case VdlKind.Set:
        return new RepSet._from(rep);
      case VdlKind.Map:
        return new RepMap._from(rep);
      case VdlKind.Union:
        return new RepUnion._(t, rep.index, new VdlValue.copy(rep.value));
      default:
        throw new ArgumentError('vdl: _copyRep unhandled kind ${t.kind}');
    }
  }

  // toString returns a human-readable representation of the value.
  // To retrieve the underlying value of a String, use asString.
  // TODO(alexfandrianto): StringBuffer
  String toString() {
    // Produce the string version of the VdlValue's internal representation.
    // This string is wrapped up in different ways depending on the type.
    String repStr = _stringRep(type, _rep);

    // Unnamed bool and unnamed string do not need the type to be stated.
    if (type == VdlTypes.Bool || type == VdlTypes.String) {
      return repStr;
    }

    // Produce the string version of the VdlValue's type.
    String tStr = type.toString();

    // These kinds don't need extra parens around their value (excluding bytes).
    switch (type.kind) {
      case VdlKind.List:
      case VdlKind.Array:
      case VdlKind.Set:
      case VdlKind.Map:
      case VdlKind.Struct:
      case VdlKind.Union:
        if (!type.isBytes) {
          return '${tStr}${repStr}';
        }
        break;
      default:
        break;
    }
    return '${tStr}(${repStr})';
  }

  // Computes the string representation for the type and representation.
  // Switches off kind and may lazily initializes the representation if it was
  // missing some zero values.
  static String _stringRep(VdlType t, dynamic rep) {
    // Handle the bytes case (to make it cleaner for list/array later).
    if (t.isBytes) {
      return '"${new String.fromCharCodes(rep)}"';
    }

    // Handle the null case (to make it cleaner for any/optional later).
    if (rep == null) {
      return 'nil';
    }

    switch (t.kind) {
      case VdlKind.Bool:
      case VdlKind.Byte:
      case VdlKind.Uint16:
      case VdlKind.Uint32:
      case VdlKind.Uint64:
      case VdlKind.Int16:
      case VdlKind.Int32:
      case VdlKind.Int64:
      case VdlKind.Float32:
      case VdlKind.Float64:
      case VdlKind.Complex64:
      case VdlKind.Complex128:
      case VdlKind.TypeObject:
        return rep.toString();
      case VdlKind.String:
        // TODO(alexfandrianto): Dart lacks %q or a string quoting mechanism.
        return '"${rep}"';
      case VdlKind.Enum:
        return t.labels[rep]; // obtain the enum string label
      case VdlKind.List:
      case VdlKind.Array:
      case VdlKind.Struct:
      case VdlKind.Set:
      case VdlKind.Map:
      case VdlKind.Union:
      case VdlKind.Any:
        return rep.toString();
      case VdlKind.Optional:
        return _stringRep(t.elem, rep);
      default:
        throw new ArgumentError('vdl: stringRep unhandled kind ${t.kind}');
    }
  }

  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! VdlValue) {
      return false;
    }

    VdlValue o = other as VdlValue;

    // If the types are not equal, return false.
    if (this.type != o.type) {
      return false;
    }

    // When comparing bytes, use listsEqual to compare the Uint8List.
    if (this.type.isBytes) {
      return quiver_collection.listsEqual(this._rep, o._rep);
    }

    // Otherwise, the representations will satisfy == on each other.
    return this._rep == o._rep;
  }
  int get hashCode {
    // By defining hashCode this way, VdlType and RepUnion and RepSequence
    // need to implement hashCode as well.
    return quiver_core.hash2(type, _rep);
  }

  // Errors if the kind is not one of the kinds.
  static void _checkOneOfKinds(VdlType t, String methodName, List<VdlKind> kinds) {
    for (VdlKind k in kinds) {
      if (t.kind == k) {
        return;
      }
    }
    throw new StateError('vdl: ${methodName} mismatched kind; got: '
      '${t.kind}, want: ${kinds}');
  }
  static void _checkKind(VdlType t, String methodName, VdlKind k) {
    _checkOneOfKinds(t, methodName, [k]);
  }

  // Errors if the type isn't a list or array with byte elements.
  static void _checkIsBytes(VdlType t, String methodName) {
    if (!t.isBytes) {
      throw new ArgumentError('vdl: ${methodName} mismatched type; got: '
        '${t.toString()}');
    }
  }

  // kind returns the VdlKind of the type.
  VdlKind get kind => type.kind;

  // isZero returns true iff the VdlValue contains a zero value for its type.
  bool get isZero => _isZeroRep(type, _rep);

  // isNull returns true iff the value is null for an Any or Optional.
  bool get isNull => (type.kind == VdlKind.Any || type.kind == VdlKind.Optional) &&
    _rep == null;

  // get or set the value in various forms.
  // An error is thrown if a method inappropriate to the kind is called.

  bool get asBool {
    _checkKind(type, 'asBool', VdlKind.Bool);
    return _rep as bool;
  }

  // Assign the underlying bool representation to x.
  void set asBool(bool x) {
    _checkKind(type, 'assignBool', VdlKind.Bool);
    _rep = x;
  }

  int get asByte {
    _checkKind(type, 'asByte', VdlKind.Byte);
    return _rep as int;
  }

  // Assign the underlying byte representation to x.
  void set asByte(int x) {
    _checkKind(type, 'assignByte', VdlKind.Byte);
    _rep = x;
  }

  int get asInt {
    _checkOneOfKinds(type, 'asInt', [VdlKind.Int16, VdlKind.Int32, VdlKind.Int64]);
    return _rep as int;
  }

  // Assign the underlying int representation to x.
  void set asInt(int x) {
    _checkOneOfKinds(type, 'assignInt', [VdlKind.Int16, VdlKind.Int32, VdlKind.Int64]);
    _rep = x;
  }

  int get asUint {
    _checkOneOfKinds(type, 'asUint', [VdlKind.Uint16, VdlKind.Uint32, VdlKind.Uint64]);
    return _rep as int;
  }

  // Assign the underlying uint representation to x.
  void set asUint(int x) {
    _checkOneOfKinds(type, 'assignUint', [VdlKind.Uint16, VdlKind.Uint32, VdlKind.Uint64]);
    _rep = x;
  }

  double get asFloat {
    _checkOneOfKinds(type, 'asFloat', [VdlKind.Float32, VdlKind.Float64]);
    return _rep as double;
  }

  // Assign the underlying float representation to x.
  void set asFloat(double x) {
    _checkOneOfKinds(type, 'assignFloat', [VdlKind.Float32, VdlKind.Float64]);
    _rep = x;
  }

  VdlComplex get asComplex {
    _checkOneOfKinds(type, 'asComplex', [VdlKind.Complex64, VdlKind.Complex128]);
    return _rep as VdlComplex;
  }

  // Assign the underlying complex representation to x.
  void set asComplex(VdlComplex x) {
    _checkOneOfKinds(type, 'assignComplex', [VdlKind.Complex64, VdlKind.Complex128]);
    _rep = new VdlComplex(x.real, x.imag);
  }

  String get asString {
    _checkKind(type, 'asString', VdlKind.String);
    return _rep as String;
  }

  // Assign the underlying string representation to x.
  void set asString(String x) {
    _checkKind(type, 'assignString', VdlKind.String);
    _rep = x;
  }

  // TODO(alexfandrianto): Potentially subtle bug here. Even for [x]byte, you
  // can assign the length of the Uint8List. Ideally, we can accept
  // this edge case, instead of needing to define RepBytes extends Uint8List.
  typed_data.Uint8List get asBytes {
    _checkIsBytes(type, 'asBytes');
    return _rep as typed_data.Uint8List;
  }

  // Assign the underlying bytes representation to x.
  void set asBytes(List<int> x) {
    _checkIsBytes(type, 'assignBytes');
    if (type.kind == VdlKind.Array && type.len != x.length) {
      throw new ArgumentError('vdl: assignBytes on type [${type.len}]byte with '
        'len ${x.length}');
    }
    _rep = new typed_data.Uint8List.fromList(x); // copy the bytes in!
  }

  int get asEnumIndex {
    _checkKind(type, 'asEnumIndex', VdlKind.Enum);
    return _rep as int;
  }

  // Assign the underlying enum representation via enum index.
  void set asEnumIndex(int index) {
    _checkKind(type, 'assignEnumIndex', VdlKind.Enum);
    if (index < 0 || index >= type.labels.length) {
      throw new ArgumentError('vdl: enum "${type.name}" index ${index} is out of '
        'range');
    }
    _rep = index;
  }

  String get asEnumLabel {
    _checkKind(type, 'asEnumLabel', VdlKind.Enum);
    return type.labels[_rep as int];
  }

  // Assign the underlying enum representation via enum label.
  void set asEnumLabel(String label) {
    _checkKind(type, 'assignEnumLabel', VdlKind.Enum);
    for (int i = 0; i < type.labels.length; i++) {
      if (type.labels[i] == label) {
        _rep = i;
        return;
      }
    }
    throw new ArgumentError('vdl: enum "${type.name}" does not have label '
      '"${label}"');
  }

  VdlType get asTypeObject {
    _checkKind(type, 'asTypeObject', VdlKind.TypeObject);
    return _rep as VdlType;
  }

  // Assign the underlying typeobject representation to x.
  void set asTypeObject(VdlType x) {
    _checkKind(type, 'assignTypeObject', VdlKind.TypeObject);
    if (x == null) {
      x = VdlTypes.Any;
    }
    _rep = x;
  }

  RepSequence get asList {
    _checkOneOfKinds(type, 'asList', [VdlKind.Array, VdlKind.List]);
    return _rep as RepSequence;
  }
  RepSet get asSet {
    _checkKind(type, 'asSet', VdlKind.Set);
    return _rep as RepSet;
  }
  RepMap get asMap {
    _checkKind(type, 'asMap', VdlKind.Map);
    return _rep as RepMap;
  }

  // Returns the element value of the underlying Any or Optional.
  // Note: This value could potentially be null.
  VdlValue get elem {
    _checkOneOfKinds(type, 'elem', [VdlKind.Any, VdlKind.Optional]);
    return _rep;
  }

  // structFieldByIndex returns the VdlValue struct field at the given index.
  VdlValue structFieldByIndex(int index) {
    _checkKind(type, 'structField', VdlKind.Struct);
    return _rep[index];
  }

  // structFieldByName returns the VdlValue struct that matches the given name.
  // Note: In VdlValue space, the names should all be capitalized.
  VdlValue structFieldByName(String name) {
    _checkKind(type, 'structFieldByName', VdlKind.Struct);
    for (int i = 0; i < type.fields.length; i++) {
      VdlField f = type.fields[i];
      if (f.name == name) {
        return _rep[i];
      }
    }
    return null; // The struct field was not found.
  }

  // unionField returns the underlying RepUnion (an index, value pair).
  RepUnion unionField() {
    _checkKind(type, 'unionField', VdlKind.Union);
    return _rep;
  }

  // Assign the underlying union to the given index and value.
  void assignUnionField(int index, VdlValue value) {
    _checkKind(type, 'assignUnionField', VdlKind.Union);
    if (index < 0 || index >= type.fields.length) {
      throw new ArgumentError('vdl: union "${type.name}" index ${index} is out '
        'of range');
    }
    _rep = new RepUnion._(type, index, _typedCopy(type.fields[index].type, value));
  }

  // Creates a copy of the VdlValue under the given type.
  VdlValue _typedCopy(VdlType t, VdlValue v) {
    return new VdlValue._(t, null)..assign(v);
  }

  // Assign x to this VdlValue. Depending on the underlying type, copies
  // will be made in order to transfer the representation/value into this one.
  void assign(VdlValue x) {
    // Set the underlying representation to x's.
    if (x == null && (type.kind == VdlKind.Any || type.kind == VdlKind.Optional)) {
      _rep = null;
    } else if (type == x.type) {
      // Copy over x's rep based on its type.
      // Notably, this check must be done before the next one to avoid assigning
      // an any to the inside of an any.
      _rep = _copyRep(x.type, x._rep);
    } else if (type.kind == VdlKind.Any ||
      (type.kind == VdlKind.Optional && x.type == type.elem)) {
      // Copy x directly over as the representation because Any and Optional
      // store a VdlValue.
      _rep = new VdlValue.copy(x);
    } else {
      throw new ArgumentError('vdl: value of type "${type.toString()}" '
        'not assignable from "${x == null ? x.type.toString() : 'null'}"');
    }
  }
}


// Convenience methods that create VdlValue (one for each kind).
VdlValue anyValue(VdlValue x) => new VdlValue.zero(VdlTypes.Any)..assign(x);
VdlValue optionalValue(VdlValue x) =>
  new VdlValue._(optionalType(x.type), new VdlValue.copy(x));
VdlValue boolValue(bool x) => new VdlValue.zero(VdlTypes.Bool)..asBool = x;
VdlValue byteValue(int x) => new VdlValue.zero(VdlTypes.Byte)..asByte = x;
VdlValue uint16Value(int x) => new VdlValue.zero(VdlTypes.Uint16)..asUint = x;
VdlValue uint32Value(int x) => new VdlValue.zero(VdlTypes.Uint32)..asUint = x;
VdlValue uint64Value(int x) => new VdlValue.zero(VdlTypes.Uint64)..asUint = x;
VdlValue int16Value(int x) => new VdlValue.zero(VdlTypes.Int16)..asInt = x;
VdlValue int32Value(int x) => new VdlValue.zero(VdlTypes.Int32)..asInt = x;
VdlValue int64Value(int x) => new VdlValue.zero(VdlTypes.Int64)..asInt = x;
VdlValue float32Value(double x) => new VdlValue.zero(VdlTypes.Float32)
  ..asFloat = x;
VdlValue float64Value(double x) => new VdlValue.zero(VdlTypes.Float64)
  ..asFloat = x;
VdlValue complex64Value(VdlComplex x) => new VdlValue.zero(VdlTypes.Complex64)
  ..asComplex = x;
VdlValue complex128Value(VdlComplex x) => new VdlValue.zero(VdlTypes.Complex128)
  ..asComplex = x;
VdlValue stringValue(String x) => new VdlValue.zero(VdlTypes.String)..asString = x;
VdlValue bytesValue(List<int> x) => new VdlValue.zero(listType(VdlTypes.Byte))
  ..asBytes = x;
VdlValue typeObjectValue(VdlType x) => new VdlValue.zero(VdlTypes.TypeObject)
  ..asTypeObject = x;
