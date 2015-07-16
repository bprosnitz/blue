part of vdl;

enum VdlKind {
  // Variant kinds
  Any, // any type
  Optional, // value might not exist
  // Scalar kinds
  Bool, // boolean
  Byte, // 8 bit unsigned integer
  Uint16, // 16 bit unsigned integer
  Uint32, // 32 bit unsigned integer
  Uint64, // 64 bit unsigned integer
  Int16, // 16 bit signed integer
  Int32, // 32 bit signed integer
  Int64, // 64 bit signed integer
  Float32, // 32 bit IEEE 754 floating point
  Float64, // 64 bit IEEE 754 floating point
  Complex64, // {real,imag} each 32 bit IEEE 754 floating point
  Complex128, // {real,imag} each 64 bit IEEE 754 floating point
  String, // unicode string (encoded as UTF-8 in memory)
  Enum, // one of a set of labels
  TypeObject, // type represented as a value
  // Composite kinds
  Array, // fixed-length ordered sequence of elements
  List, // variable-length ordered sequence of elements
  Set, // unordered collection of distinct keys
  Map, // unordered association between distinct keys and values
  Struct, // conjunction of an ordered sequence of (name,type) fields
  Union, // disjunction of an ordered sequence of (name,type) fields
}

String _vdlKindString(VdlKind kind) {
  switch (kind) {
    case VdlKind.Any:
      return 'any';
    case VdlKind.Optional:
      return 'optional';
    case VdlKind.Bool:
      return 'bool';
    case VdlKind.Byte:
      return 'byte';
    case VdlKind.Uint16:
      return 'uint16';
    case VdlKind.Uint32:
      return 'uint32';
    case VdlKind.Uint64:
      return 'uint64';
    case VdlKind.Int16:
      return 'int16';
    case VdlKind.Int32:
      return 'int32';
    case VdlKind.Int64:
      return 'int64';
    case VdlKind.Float32:
      return 'float32';
    case VdlKind.Float64:
      return 'float64';
    case VdlKind.Complex64:
      return 'complex64';
    case VdlKind.Complex128:
      return 'complex128';
    case VdlKind.String:
      return 'string';
    case VdlKind.Enum:
      return 'enum';
    case VdlKind.TypeObject:
      return 'typeobject';
    case VdlKind.Array:
      return 'array';
    case VdlKind.List:
      return 'list';
    case VdlKind.Set:
      return 'set';
    case VdlKind.Map:
      return 'map';
    case VdlKind.Struct:
      return 'struct';
    case VdlKind.Union:
      return 'union';
  }
}

// Cache of hash cons'd built types.
Map<String, VdlType> _hashConsCache =
  new Map<String, VdlType>();

// _FieldBase represents a field of struct / unions in _TypeBase
abstract class _FieldBase<T extends _TypeBase<T, F>, F extends _FieldBase<T, F>> {
  String get name;
  T get type;
}

// Abstract type base class to share common methods between
// VdlPendingType and VdlType.
abstract class _TypeBase<T extends _TypeBase<T, F>, F extends _FieldBase<T, F>> {
  // Note: Both _FieldBase and _TypeBase take type and field parameters to ensure the
  // correct generic type structure.

  VdlKind get kind;
  String get name;
  List<String> get labels;
  int get len;
  T get elem;
  T get key;
  List<F> get fields;

  String toString() => _uniqueString(new Set<_TypeBase>());

  // Generate a string that uniquely represents the contents of valid types.
  // Invalid types may not have a unique string.
  String _uniqueString(Set<_TypeBase> seen) {
    if (!seen.add(this)) {
      if (name != null) {
        // Recursive types in VDL must have names.
        // TODO consider breaking cycles when processing recursive types without names.
        return name;
      }
    }

    String s;
    if (name == null) {
      s = '';
    } else {
      s = '$name ';
    }
    switch (kind) {
      case VdlKind.Optional:
        if (elem == null) {
          return s + '?[MISSING ELEM FIELD]';
        }
        return s + '?' + elem._uniqueString(seen);
      case VdlKind.Enum:
        if (labels == null) {
          return s + 'enum{[MISSING LABELS FIELD]}';
        }
        return s + 'enum{' + labels.join(';') + '}';
      case VdlKind.Array:
        var lenStr = '[MISSING LEN FIELD]';
        if (len != null) {
          lenStr = len.toString();
        }
        var elemStr = '[MISSING ELEM FIELD]';
        if (elem != null) {
          elemStr = elem._uniqueString(seen);
        }
        return '${s}[${lenStr}]${elemStr}';
      case VdlKind.List:
        if (elem == null) {
          return '${s}[][MISSING ELEM FIELD]';
        }
        return '${s}[]${elem._uniqueString(seen)}';
      case VdlKind.Set:
        if (key == null) {
          return s + 'set[[MISSING KEY FIELD]]';
        }
        return '${s}set[${key._uniqueString(seen)}]';
      case VdlKind.Map:
        var keyStr = '[MISSING KEY FIELD]';
        if (key != null) {
          keyStr = key._uniqueString(seen);
        }
        var elemStr = '[MISSING ELEM FIELD]';
        if (elem != null) {
          elemStr = elem._uniqueString(seen);
        }
        return '${s}map[${keyStr}]${elemStr}';
      case VdlKind.Struct:
      case VdlKind.Union:
        if (kind == VdlKind.Struct) {
          s += 'struct{';
        } else {
          s += 'union{';
        }
        if (fields == null) {
          return s + "[MISSING FIELDS FIELD]}";
        }
        for (var index = 0; index < fields.length; index++) {
          var field = fields[index];
          if (index > 0) {
            s += ';';
          }
          var fieldName = '[MISSING FIELD.NAME FIELD]';
          if (field.name != null) {
            fieldName = field.name;
          }
          var fieldType = '[MISSING FIELD.TYPE FIELD]';
          if (field.type != null) {
            fieldType = field.type._uniqueString(seen);
          }
          s += '$fieldName $fieldType';
        }
        return s + "}";
      default:
        if (kind == null) {
          return '[MISSING KIND FIELD]';
        }
        return s + _vdlKindString(kind);
    }
  }

  void _validate(Set<_TypeBase> seen);
}

// VdlField is hash-consed and immutable as part of type.
class VdlField extends _FieldBase<VdlType, VdlField> {
  // Exposed getters (read only / immutable)
  String get name => _name;
  VdlType get type => _type;

  // Library-private values
  String _name;
  VdlType _type;

  VdlField._(String name, VdlType type) :
    _name = name,
    _type = type;
}

// VdlType is hash-consed and immutable.
// To construct a type, create a VdlPendingType and call
// VdlPendingType.build().
class VdlType extends _TypeBase<VdlType, VdlField> {
  // Exposed getters (read only / immutable).
  VdlKind get kind => _kind;
  String get name => _name;
  List<String> get labels => _labels;
  int get len => _len;
  VdlType get elem => _elem;
  VdlType get key => _key;
  List<VdlField> get fields => _fields;

  // Library-private values.
  VdlKind _kind;
  String _name;
  UnmodifiableListView<String> _labels;
  int _len;
  VdlType _elem;
  VdlType _key;
  UnmodifiableListView<VdlField> _fields;

  static final VdlType vdlType = _createTypeObjectType();
  static VdlType _createTypeObjectType() {
    VdlPendingType pt = new VdlPendingType()
    ..kind = VdlKind.TypeObject;
    return pt.build();
  }

  void _validate(Set<_TypeBase> seen) {} // always validates

  VdlType._createEmpty() {}
}

class VdlTypeValidationError extends StateError {
  VdlTypeValidationError.unexpectedField(VdlKind kind, String fieldName) : super(
          'Unexpected non-null field \'' +
              fieldName +
              '\' in type of kind ' +
              kind.toString());
  VdlTypeValidationError.requiredField(VdlKind kind, String fieldName) : super(
          'Missing required field \'' +
              fieldName +
              '\' in type of kind ' +
              kind.toString());
  VdlTypeValidationError.missingVdlKind() : super('Type is missing kind field');
}

class VdlPendingField extends _FieldBase {
  String name;
  _TypeBase type;

  VdlPendingField(String name, _TypeBase type) :
    name = name,
    type = type;
}

// VdlPendingType should be populated when creating a new type
class VdlPendingType extends _TypeBase {
  VdlKind kind;
  String name;
  List<String> labels;
  int len;
  _TypeBase elem;
  _TypeBase key;
  List< _FieldBase> fields;

  VdlPendingType() {}

  // Build the VdlPendingType into a immutable hash-consed VdlType object.
  VdlType build() {
    // Validate
    validate();

    // Traverse type and build map of VdlPendingType to VdlType that
    // needs to be built.
    // During this process, new types are added to the hash cons cache.
    Map<VdlPendingType, VdlType> toBuild =
      new Map<VdlPendingType, VdlType>();
    Queue<_TypeBase> toProcess = new Queue<_TypeBase>();
    toProcess.addLast(this);
    while(toProcess.isNotEmpty) {
      _TypeBase next = toProcess.removeFirst();

      // Skip type if already created.
      String uniqueStr = next.toString();
      if (_hashConsCache.containsKey(uniqueStr)) {
        continue;
      }

      var type = new VdlType._createEmpty();
      _hashConsCache[uniqueStr] = type;
      toBuild[next] = type;

      if (next.elem != null) {
        toProcess.addLast(next.elem);
      }
      if (next.key != null) {
        toProcess.addLast(next.key);
      }
      if (next.fields != null) {
        for (var pendingField in next.fields) {
          toProcess.addLast(pendingField.type);
        }
      }
    }

    // Iterate over _TypeBase <-> VdlType map and fill in fields.
    toBuild.forEach((pendingType, type) {
      type._kind = pendingType.kind;
      type._name = pendingType.name;
      if (pendingType.labels != null) {
        type._labels = new UnmodifiableListView<String>(pendingType.labels);
      }
      type._len = pendingType.len;
      if (pendingType.elem != null) {
        type._elem = _hashConsCache[pendingType.elem.toString()];
      }
      if (pendingType.key != null) {
        type._key = _hashConsCache[pendingType.key.toString()];
      }
      if (pendingType.fields != null) {
        var fields = new List<VdlField>();
        for (var pendingField in pendingType.fields) {
          fields.add(new VdlField._(
            pendingField.name,
            _hashConsCache[pendingField.type.toString()]
          ));
        }
        type._fields = new UnmodifiableListView(fields);
      }
    });

    return _hashConsCache[toString()];
  }

  // Validation of the pending type:
  void _disallowName(VdlKind kind) {
    if (name != null) {
      throw new VdlTypeValidationError.unexpectedField(kind, 'name');
    }
  }
  void _disallowLabels(VdlKind kind) {
    if (labels != null) {
      throw new VdlTypeValidationError.unexpectedField(kind, 'labels');
    }
  }
  void _disallowLen(VdlKind kind) {
    if (len != null) {
      throw new VdlTypeValidationError.unexpectedField(kind, 'len');
    }
  }
  void _disallowElem(VdlKind kind) {
    if (elem != null) {
      throw new VdlTypeValidationError.unexpectedField(kind, 'elem');
    }
  }
  void _disallowKey(VdlKind kind) {
    if (key != null) {
      throw new VdlTypeValidationError.unexpectedField(kind, 'key');
    }
  }
  void _disallowFields(VdlKind kind) {
    if (fields != null) {
      throw new VdlTypeValidationError.unexpectedField(kind, 'fields');
    }
  }
  void _requireName(VdlKind kind) {
    if (name == null) {
      throw new VdlTypeValidationError.requiredField(kind, 'name');
    }
  }
  void _requireLen(VdlKind kind) {
    if (len == null) {
      throw new VdlTypeValidationError.requiredField(kind, 'len');
    }
  }
  void _requireLabels(VdlKind kind) {
    if (labels == null) {
      throw new VdlTypeValidationError.requiredField(kind, 'enum');
    }
  }
  void _requireElem(VdlKind kind) {
    if (elem == null) {
      throw new VdlTypeValidationError.requiredField(kind, 'elem');
    }
  }
  void _requireKey(VdlKind kind) {
    if (key == null) {
      throw new VdlTypeValidationError.requiredField(kind, 'key');
    }
  }
  void _requireFields(VdlKind kind) {
    if (fields == null) {
      throw new VdlTypeValidationError.requiredField(kind, 'fields');
    }
    for (var i = 0; i < fields.length; i++) {
      var field = fields[i];
      if (field.name == null) {
        throw new VdlTypeValidationError.requiredField(kind,
          'fields[$i].name');
      }
      if (field.type == null) {
        throw new VdlTypeValidationError.requiredField(kind,
          'fields[$i].type');
      }
    }
  }

  void _validateShallow() {
    if (kind == null) {
      throw new VdlTypeValidationError.missingVdlKind();
    }

    switch(kind) {
      case VdlKind.Any:
      case VdlKind.TypeObject:
        _disallowName(kind);
        _disallowLabels(kind);
        _disallowLen(kind);
        _disallowElem(kind);
        _disallowKey(kind);
        _disallowFields(kind);
      break;
      case VdlKind.Optional:
        _disallowName(kind);
        _disallowLabels(kind);
        _disallowLen(kind);
        _requireElem(kind);
        _disallowKey(kind);
        _disallowFields(kind);
      break;
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
      case VdlKind.String:
        _disallowLabels(kind);
        _disallowLen(kind);
        _disallowElem(kind);
        _disallowKey(kind);
        _disallowFields(kind);
      break;
      case VdlKind.Enum:
        _requireName(kind);
        _requireLabels(kind);
        _disallowLen(kind);
        _disallowElem(kind);
        _disallowKey(kind);
        _disallowFields(kind);
      break;
      case VdlKind.Array:
        _requireName(kind);
        _disallowLabels(kind);
        _requireLen(kind);
        _requireElem(kind);
        _disallowKey(kind);
        _disallowFields(kind);
      break;
      case VdlKind.List:
        _disallowLabels(kind);
        _disallowLen(kind);
        _requireElem(kind);
        _disallowKey(kind);
        _disallowFields(kind);
      break;
      case VdlKind.Set:
        _disallowLabels(kind);
        _disallowLen(kind);
        _disallowElem(kind);
        _requireKey(kind);
        _disallowFields(kind);
      break;
      case VdlKind.Map:
        _disallowLabels(kind);
        _disallowLen(kind);
        _requireElem(kind);
        _requireKey(kind);
        _disallowFields(kind);
      break;
      case VdlKind.Struct:
      case VdlKind.Union:
        _requireName(kind);
        _disallowLabels(kind);
        _disallowLen(kind);
        _disallowElem(kind);
        _disallowKey(kind);
        _requireFields(kind);
      break;
    }
  }

  void _validate(Set<_TypeBase> seen) {
    if (!seen.add(this)) {
      return;
    }

    _validateShallow();

    if (elem != null) {
      elem._validate(seen);
    }
    if (key != null) {
      key._validate(seen);
    }
    if (fields != null) {
      for (var field in fields) {
        field.type._validate(seen);
      }
    }
  }

  void validate() {
    _validate(new Set<_TypeBase>());
  }
}
