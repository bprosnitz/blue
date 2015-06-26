part of vdl;

enum Kind {
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

String _vdlKindString(Kind kind) {
  switch (kind) {
    case Kind.Any:
      return 'any';
    case Kind.Optional:
      return 'optional';
    case Kind.Bool:
      return 'bool';
    case Kind.Byte:
      return 'byte';
    case Kind.Uint16:
      return 'uint16';
    case Kind.Uint32:
      return 'uint32';
    case Kind.Uint64:
      return 'uint64';
    case Kind.Int16:
      return 'int16';
    case Kind.Int32:
      return 'int32';
    case Kind.Int64:
      return 'int64';
    case Kind.Float32:
      return 'float32';
    case Kind.Float64:
      return 'float64';
    case Kind.Complex64:
      return 'complex64';
    case Kind.Complex128:
      return 'complex128';
    case Kind.String:
      return 'string';
    case Kind.Enum:
      return 'enum';
    case Kind.TypeObject:
      return 'typeobject';
    case Kind.Array:
      return 'array';
    case Kind.List:
      return 'list';
    case Kind.Set:
      return 'set';
    case Kind.Map:
      return 'map';
    case Kind.Struct:
      return 'struct';
    case Kind.Union:
      return 'union';
  }
}
/*
// Field is hash-consed and immutable as part of type.
class Field {
  // Exposed getters (read only / immutable)
  String get name => _name;
  Type get type => _type;

  // Library-private values
  String _name;
  Type _type;

  Field._(String name, Type type) {}
}

// Type is hash-consed and immutable.
// Use the TypeBuilder to construct a type.
class Type {
  // Exposed getters (read only / immutable)
  Kind get kind => _kind; // TODO(bprosnitz) Can just be final?
  String get name => _name;
  List<String> get labels => _labels;
  int get len => _len;
  Type get elem => _elem;
  Type get key => _key;
  Type get fields => _fields;

  // Library-private values
  Kind _kind;
  String _name;
  UnmodifiableListView<String> _labels;
  int _len;
  Type _elem;
  Type _key;
  UnmodifiableListView<Field> _fields;

  // Build the partial type into a hash-consed type.
  factory Type._(int typeId, List<PartialType> partialTypes) {}
}*/

class TypeValidationError extends StateError {
  TypeValidationError.unexpectedField(Kind kind, String fieldName) : super(
          'Unexpected non-null field \'' +
              fieldName +
              '\' in type of kind ' +
              kind.toString());
  TypeValidationError.requiredField(Kind kind, String fieldName) : super(
          'Missing required field \'' +
              fieldName +
              '\' in type of kind ' +
              kind.toString());
  TypeValidationError.missingKind() : super('Type is missing kind field');
}

class PendingField {
  String name;
  PendingType type;

  PendingField(String name, PendingType type) {
    this.name = name;
    this.type = type;
  }
}

class PendingType {
  Kind kind;
  String name;
  List<String> labels;
  int len;
  PendingType elem;
  PendingType key;
  List<PendingField> fields;

  PartialType() {}

  String toString([Set<PendingType> seen]) {
    if (seen == null) {
      seen = new Set<PendingType>();
    }

    if (!seen.add(this)) {
      return name;
    }

    String s;
    if (name == null) {
      s = '';
    } else {
      s = '$name ';
    }
    switch (kind) {
      case Kind.Optional:
        if (elem == null) {
          return s + '?[MISSING ELEM FIELD]';
        }
        return s + '?' + elem.toString(seen);
      case Kind.Enum:
        if (labels == null) {
          return s + 'enum{[MISSING LABELS FIELD]}';
        }
        return s + 'enum{' + labels.join(';') + '}';
      case Kind.Array:
        var lenStr = '[MISSING LEN FIELD]';
        if (len != null) {
          lenStr = len.toString();
        }
        var elemStr = '[MISSING ELEM FIELD]';
        if (elem != null) {
          elemStr = elem.toString(seen);
        }
        return '$s[$lenStr]$elemStr';
      case Kind.List:
        if (elem == null) {
          return s + '[][MISSING ELEM FIELD]';
        }
        return s + '[]' + elem.toString(seen);
      case Kind.Set:
        if (key == null) {
          return s + 'set[[MISSING KEY FIELD]]';
        }
        return s + 'set[' + key.toString(seen) + ']';
      case Kind.Map:
        var keyStr = '[MISSING KEY FIELD]';
        if (key != null) {
          keyStr = key.toString(seen);
        }
        var elemStr = '[MISSING ELEM FIELD]';
        if (elem != null) {
          elemStr = elem.toString(seen);
        }
        return s + 'map[$keyStr]$elemStr';
      case Kind.Struct:
      case Kind.Union:
        if (kind == Kind.Struct) {
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
            fieldType = field.type.toString(seen);
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


  // Validation:
  void _disallowName(Kind kind) {
    if (name != null) {
      throw new TypeValidationError.unexpectedField(kind, 'name');
    }
  }
  void _disallowLabels(Kind kind) {
    if (labels != null) {
      throw new TypeValidationError.unexpectedField(kind, 'labels');
    }
  }
  void _disallowLen(Kind kind) {
    if (len != null) {
      throw new TypeValidationError.unexpectedField(kind, 'len');
    }
  }
  void _disallowElem(Kind kind) {
    if (elem != null) {
      throw new TypeValidationError.unexpectedField(kind, 'elem');
    }
  }
  void _disallowKey(Kind kind) {
    if (key != null) {
      throw new TypeValidationError.unexpectedField(kind, 'key');
    }
  }
  void _disallowFields(Kind kind) {
    if (fields != null) {
      throw new TypeValidationError.unexpectedField(kind, 'fields');
    }
  }
  void _requireName(Kind kind) {
    if (name == null) {
      throw new TypeValidationError.requiredField(kind, 'name');
    }
  }
  void _requireLen(Kind kind) {
    if (len == null) {
      throw new TypeValidationError.requiredField(kind, 'len');
    }
  }
  void _requireLabels(Kind kind) {
    if (labels == null) {
      throw new TypeValidationError.requiredField(kind, 'enum');
    }
  }
  void _requireElem(Kind kind) {
    if (elem == null) {
      throw new TypeValidationError.requiredField(kind, 'elem');
    }
  }
  void _requireKey(Kind kind) {
    if (key == null) {
      throw new TypeValidationError.requiredField(kind, 'key');
    }
  }
  void _requireFields(Kind kind) {
    if (fields == null) {
      throw new TypeValidationError.requiredField(kind, 'fields');
    }
    for (var i = 0; i < fields.length; i++) {
      var field = fields[i];
      if (field.name == null) {
        throw new TypeValidationError.requiredField(kind,
          'fields[$i].name');
      }
      if (field.type == null) {
        throw new TypeValidationError.requiredField(kind,
          'fields[$i].type');
      }
    }
  }

  void _validateShallow() {
    if (kind == null) {
      throw new TypeValidationError.missingKind();
    }

    switch(kind) {
      case Kind.Any:
      case Kind.TypeObject:
        _disallowName(kind);
        _disallowLabels(kind);
        _disallowLen(kind);
        _disallowElem(kind);
        _disallowKey(kind);
        _disallowFields(kind);
      break;
      case Kind.Optional:
        _disallowName(kind);
        _disallowLabels(kind);
        _disallowLen(kind);
        _requireElem(kind);
        _disallowKey(kind);
        _disallowFields(kind);
      break;
      case Kind.Bool:
      case Kind.Byte:
      case Kind.Uint16:
      case Kind.Uint32:
      case Kind.Uint64:
      case Kind.Int16:
      case Kind.Int32:
      case Kind.Int64:
      case Kind.Float32:
      case Kind.Float64:
      case Kind.Complex64:
      case Kind.Complex128:
      case Kind.String:
        _disallowLabels(kind);
        _disallowLen(kind);
        _disallowElem(kind);
        _disallowKey(kind);
        _disallowFields(kind);
      break;
      case Kind.Enum:
        _requireName(kind);
        _requireLabels(kind);
        _disallowLen(kind);
        _disallowElem(kind);
        _disallowKey(kind);
        _disallowFields(kind);
      break;
      case Kind.Array:
        _requireName(kind);
        _disallowLabels(kind);
        _requireLen(kind);
        _requireElem(kind);
        _disallowKey(kind);
        _disallowFields(kind);
      break;
      case Kind.List:
        _disallowLabels(kind);
        _disallowLen(kind);
        _requireElem(kind);
        _disallowKey(kind);
        _disallowFields(kind);
      break;
      case Kind.Set:
        _disallowLabels(kind);
        _disallowLen(kind);
        _disallowElem(kind);
        _requireKey(kind);
        _disallowFields(kind);
      break;
      case Kind.Map:
        _disallowLabels(kind);
        _disallowLen(kind);
        _requireElem(kind);
        _requireKey(kind);
        _disallowFields(kind);
      break;
      case Kind.Struct:
      case Kind.Union:
        _requireName(kind);
        _disallowLabels(kind);
        _disallowLen(kind);
        _disallowElem(kind);
        _disallowKey(kind);
        _requireFields(kind);
      break;
    }
  }

  void validate([Set<PendingType> seen]) {
    if (seen == null) {
      seen = new Set<PendingType>();
    }
    if (!seen.add(this)) {
      return;
    }

    _validateShallow();

    if (elem != null) {
      elem.validate(seen);
    }
    if (key != null) {
      key.validate(seen);
    }
    if (fields != null) {
      for (var field in fields) {
        field.type.validate(seen);
      }
    }
  }
}
