part of vdl;

// vdlTypeOf computes the vdl type for a dart object.
VdlType vdlTypeOf(Object obj) {
  mirrors.ClassMirror mclass = mirrors.reflect(obj).type;
  return vdlTypeFromMirror(mclass);
}

// vdlTypeFromMirror creates a VdlType from a ClassMirror representing a dart class.
VdlType vdlTypeFromMirror(mirrors.ClassMirror mclass) {
  _TypeBase type = _typeFromMirrorRecurse(mclass, new Map<mirrors.TypeMirror, _TypeBase>());
  if (type is VdlType) {
    return type;
  }
  return (type as VdlPendingType).build();
}

// _typeFromMirrorRecurse is the primary type reflection routine.
// It descends into dart types and constructs a VdlPendingType or VdlType.
_TypeBase _typeFromMirrorRecurse(
    mirrors.TypeMirror mtype, Map<mirrors.TypeMirror, _TypeBase> seen) {
  // seen is used to break cycles.
  if (seen.containsKey(mtype)) {
    return seen[mtype];
  }

  VdlType builtIn = _tryVdlTypeFromBuiltIn(mtype);
  if (builtIn != null) {
    return builtIn;
  }

  VdlType fieldType = _tryGetVdlTypeFromField(mtype);
  if (fieldType != null) {
    return fieldType;
  }

  return _buildPendingTypeFromClass(mtype, seen);
}

// StaticFinalVdlTypeError is thrown when TypeOf is called on an object
// with a vdlType field that is not static final.
class StaticFinalVdlTypeError extends Error {
  final Symbol className;
  StaticFinalVdlTypeError(mirrors.ClassMirror mclass) :
    className = mclass.qualifiedName;
  String toString() => 'the vdlType field of class ${className} must be static ' +
  'final and have type VdlType';
}

// If the specified class has a static final vdlType field, return its value (the type).
VdlType _tryGetVdlTypeFromField(mirrors.ClassMirror mclass) {
  // If the class has a static final field vdlType of type VdlType, return its value.
  mirrors.DeclarationMirror field = mclass.declarations[#vdlType];
  if (field == null) {
    return null;
  }

  if (field is mirrors.VariableMirror) {
    mirrors.VariableMirror fieldVar = field;
    if (fieldVar.type == _mclassVdlType &&
      fieldVar.isFinal && fieldVar.isStatic) {
      return mclass.getField(#vdlType).reflectee;
    }
  }
  throw new StaticFinalVdlTypeError(mclass);
}

// Try to create a VdlType from a built in or return null if not a built in.
VdlType _tryVdlTypeFromBuiltIn(mirrors.TypeMirror mtype) {
  if (mtype.qualifiedName == const Symbol("dynamic") ||
    mtype.isSubtypeOf(_mclassVdlValue)) {
    return VdlTypes.Any;
  } if (mtype.isSubtypeOf(_mclassBool)) {
    return VdlTypes.Bool;
  } else if (mtype.isSubtypeOf(_mclassInt)) {
    return VdlTypes.Int64;
  } else if (mtype.isSubtypeOf(_mclassDouble)) {
    return VdlTypes.Float64;
  } else if (mtype.isSubtypeOf(_mclassString)) {
    return VdlTypes.String;
  } else if (mtype.isSubtypeOf(_mclassTypedData)) {
    // NOTE: Most of these types are lists, but they will be interpreted as
    // different VDL types than we want by simply looking at them as lists
    // during reflection. For instance Uint16List implements List<int> so
    // it will be interpreted as []uint64 in VDL.
    return _typedDataVdlTypes.firstWhere(
      (elem) => mtype.isSubtypeOf(elem.key),
      orElse: () => new collection.Pair(null, null)
    ).value;
  }
  return null;
}

// Create a pending type from a class that does not represent a built in.
VdlPendingType _buildPendingTypeFromClass(
    mirrors.ClassMirror mclass,
    Map<mirrors.TypeMirror, _TypeBase> seen) {
  VdlPendingType pt = new VdlPendingType();
  seen[mclass] = pt;

  if (mclass.isSubclassOf(_mclassVdlOptional)) {
    pt.kind = VdlKind.Optional;
    List<mirrors.TypeMirror> generics = _genericsOnInterface(mclass, _mclassVdlOptional);
    assert(generics.length == 1);
    pt.elem = _typeFromMirrorRecurse(generics[0], seen);
  } else if (mclass.isSubtypeOf(_mclassList)) {
    // TODO(bprosnitz) can we support fixed length lists? There currently isn't
    // a way to identify a list as fixed length (other than comparing an internal string).
    pt.kind = VdlKind.List;
    List<mirrors.TypeMirror> generics = _genericsOnInterface(mclass, _mclassList);
    assert(generics.length == 1);
    pt.elem = _typeFromMirrorRecurse(generics[0], seen);
  } else if (mclass.isSubtypeOf(_mclassMap)) {
    pt.kind = VdlKind.Map;
    List<mirrors.TypeMirror> generics = _genericsOnInterface(mclass, _mclassMap);
    assert(generics.length == 2);
    pt.key = _typeFromMirrorRecurse(generics[0], seen);
    pt.elem = _typeFromMirrorRecurse(generics[1], seen);
  } else if (mclass.isSubtypeOf(_mclassSet)) {
    pt.kind = VdlKind.Set;
    List<mirrors.TypeMirror> generics = _genericsOnInterface(mclass, _mclassSet);
    assert(generics.length == 1);
    pt.key = _typeFromMirrorRecurse(generics[0], seen);
  } else {
    Symbol qualifiedName = mclass.qualifiedName;
    String vdlName = _vdlName(qualifiedName);

    if (mclass.isEnum) {
      pt.kind = VdlKind.Enum;
      pt.name = vdlName;
      pt.labels = [];
      // Compute the label names.
      mclass.getField(#values).reflectee.forEach((v) {
        pt.labels.add(v.toString().split('.')[1]);
      });
      return pt;
    } else {
      pt.kind = VdlKind.Struct;
      pt.name = vdlName;

      pt.fields = [];
      mclass.instanceMembers.forEach((symbol, method) {
        // Vdl struct fields correspond to getters that are not defined in the Object class.
        // TODO(bprosnitz) Should we allow ignoring getters / fields with @Ignore annotation?
        if (method.isGetter && !_mclassObject.instanceMembers.containsKey(symbol)) {
          var fieldName = mirrors.MirrorSystem.getName(symbol);
          if (fieldName.startsWith('_')) {
            return; // skip private fields / getters
          }
          var getterType = _typeFromMirrorRecurse(method.returnType, seen);
          var upperCaseName = _toUpperCamelCase(fieldName);
          pt.fields.add(new VdlPendingField(upperCaseName, getterType));
        }
      });
    }
  }
  return pt;
}

// Convert a dart declaration name to a vdl name.
String _vdlName(Symbol dartName) {
  var parts = mirrors.MirrorSystem.getName(dartName).split('.');
  var last = parts.removeLast();
  return '${parts.join('/')}.${last}';
}

// Get a list of the types in the generic parameters for a given class on a given target interface.
// For instance if klass is MyMap extends Map<int, String>and target is Map, this will return a
// list of two items corresponding to the mirrors of int and String.
List<mirrors.TypeMirror> _genericsOnInterface(mirrors.ClassMirror klass, mirrors.ClassMirror interfaceTarget) {
  Queue<mirrors.ClassMirror> processQueue = new Queue<mirrors.ClassMirror>();
  Set<mirrors.ClassMirror> seenClasses = new Set<mirrors.ClassMirror>();
  processQueue.addLast(klass);
  while(processQueue.isNotEmpty) {
    mirrors.ClassMirror next = processQueue.removeFirst();
    if (next == null || seenClasses.contains(next)) {
      continue;
    }
    seenClasses.add(next);

    // Is it the class we are looking for?
    if (classEquals(next, interfaceTarget)) {
      // Return the generic argument list.
      return next.typeArguments;
    }

    // Add super* to process queue.
    for (mirrors.ClassMirror iface in next.superinterfaces) {
      processQueue.addLast(iface);
    }
    processQueue.addLast(next.superclass);
    processQueue.addLast(next.mixin);
  }
  throw new StateError('${interfaceTarget.qualifiedName} unexpectedly not superclass or interface of ${klass.qualifiedName}');
}

// Returns true iff both classes are equal, ignoring whether their references are equal.
bool classEquals(mirrors.ClassMirror first, mirrors.ClassMirror second) {
  return first.isSubclassOf(second) && second.isSubclassOf(first);
}

// Class definitions used in type reflection above.
mirrors.ClassMirror _mclassBool = mirrors.reflectClass(bool);
mirrors.ClassMirror _mclassInt = mirrors.reflectClass(int);
mirrors.ClassMirror _mclassDouble = mirrors.reflectClass(double);
mirrors.ClassMirror _mclassString = mirrors.reflectClass(String);
mirrors.ClassMirror _mclassList = mirrors.reflectType(List);
mirrors.ClassMirror _mclassMap = mirrors.reflectType(Map);
mirrors.ClassMirror _mclassSet = mirrors.reflectType(Set);
mirrors.ClassMirror _mclassVdlType = mirrors.reflectType(VdlType);
mirrors.ClassMirror _mclassVdlValue = mirrors.reflectClass(VdlValue);
mirrors.ClassMirror _mclassVdlOptional = mirrors.reflectClass(VdlOptional);
mirrors.ClassMirror _mclassObject = mirrors.reflectClass(Object);
mirrors.ClassMirror _mclassTypedData = mirrors.reflectClass(typed_data.TypedData);
mirrors.ClassMirror _mclassByteData = mirrors.reflectClass(typed_data.ByteData);
mirrors.ClassMirror _mclassUint8List = mirrors.reflectClass(typed_data.Uint8List);
mirrors.ClassMirror _mclassUint8ClampedList = mirrors.reflectClass(typed_data.Uint8ClampedList);
mirrors.ClassMirror _mclassUint16List = mirrors.reflectClass(typed_data.Uint16List);
mirrors.ClassMirror _mclassUint32List = mirrors.reflectClass(typed_data.Uint32List);
mirrors.ClassMirror _mclassUint64List = mirrors.reflectClass(typed_data.Uint64List);
mirrors.ClassMirror _mclassInt8List = mirrors.reflectClass(typed_data.Int8List);
mirrors.ClassMirror _mclassInt16List = mirrors.reflectClass(typed_data.Int16List);
mirrors.ClassMirror _mclassInt32List = mirrors.reflectClass(typed_data.Int32List);
mirrors.ClassMirror _mclassInt32x4 = mirrors.reflectClass(typed_data.Int32x4);
mirrors.ClassMirror _mclassInt32x4List = mirrors.reflectClass(typed_data.Int32x4List);
mirrors.ClassMirror _mclassInt64List = mirrors.reflectClass(typed_data.Int64List);
mirrors.ClassMirror _mclassFloat32List = mirrors.reflectClass(typed_data.Float32List);
mirrors.ClassMirror _mclassFloat32x4 = mirrors.reflectClass(typed_data.Float32x4);
mirrors.ClassMirror _mclassFloat32x4List = mirrors.reflectClass(typed_data.Float32x4List);
mirrors.ClassMirror _mclassFloat64List = mirrors.reflectClass(typed_data.Float64List);
mirrors.ClassMirror _mclassFloat64x2 = mirrors.reflectClass(typed_data.Float64x2);
mirrors.ClassMirror _mclassFloat64x2List = mirrors.reflectClass(typed_data.Float64x2List);

// Mapping from classes in typed_data to the element vdl type.
List<collection.Pair<mirrors.ClassMirror, VdlType>> _typedDataVdlTypes = [
  new collection.Pair<mirrors.ClassMirror, VdlType>(_mclassByteData, _makeListForElem(VdlTypes.Byte)),
  new collection.Pair<mirrors.ClassMirror, VdlType>(_mclassUint8List, _makeListForElem(VdlTypes.Byte)),
  new collection.Pair<mirrors.ClassMirror, VdlType>(_mclassUint8ClampedList, _makeListForElem(VdlTypes.Byte)),
  new collection.Pair<mirrors.ClassMirror, VdlType>(_mclassUint16List, _makeListForElem(VdlTypes.Uint16)),
  new collection.Pair<mirrors.ClassMirror, VdlType>(_mclassUint32List, _makeListForElem(VdlTypes.Uint32)),
  new collection.Pair<mirrors.ClassMirror, VdlType>(_mclassUint64List, _makeListForElem(VdlTypes.Uint64)),
  new collection.Pair<mirrors.ClassMirror, VdlType>(_mclassInt8List, _makeListForElem(VdlTypes.Byte)),
  new collection.Pair<mirrors.ClassMirror, VdlType>(_mclassInt16List, _makeListForElem(VdlTypes.Int16)),
  new collection.Pair<mirrors.ClassMirror, VdlType>(_mclassInt32List, _makeListForElem(VdlTypes.Int32)),
  new collection.Pair<mirrors.ClassMirror, VdlType>(_mclassInt32x4List, _makeListForElem(_makeVdlInt32x4Type())),
  new collection.Pair<mirrors.ClassMirror, VdlType>(_mclassInt64List, _makeListForElem(VdlTypes.Int64)),
  new collection.Pair<mirrors.ClassMirror, VdlType>(_mclassFloat32List, _makeListForElem(VdlTypes.Float32)),
  new collection.Pair<mirrors.ClassMirror, VdlType>(_mclassFloat32x4List, _makeListForElem(_makeVdlFloat32x4Type())),
  new collection.Pair<mirrors.ClassMirror, VdlType>(_mclassFloat64List, _makeListForElem(VdlTypes.Float64)),
  new collection.Pair<mirrors.ClassMirror, VdlType>(_mclassFloat64x2List, _makeListForElem(_makeVdlFloat64x2Type())),
];
VdlType _makeVdlInt32x4Type() {
  VdlPendingType _vdlInt32x4pendingType = new VdlPendingType()
  ..name = 'Int32x4'
  ..kind = VdlKind.Array
  ..len = 4
  ..elem = VdlTypes.Uint32;
  return _vdlInt32x4pendingType.build();
}
VdlType _makeVdlFloat32x4Type() {
  VdlPendingType _vdlFloat32x4pendingType = new VdlPendingType()
  ..name = 'Float32x4'
  ..kind = VdlKind.Array
  ..len = 4
  ..elem = VdlTypes.Float32;
  return _vdlFloat32x4pendingType.build();
}
VdlType _makeVdlFloat64x2Type() {
  VdlPendingType _vdlFloat64x2pendingType = new VdlPendingType()
  ..name  = 'Float64x2'
  ..kind = VdlKind.Array
  ..len = 2
  ..elem = VdlTypes.Float64;
  return _vdlFloat64x2pendingType.build();
}
VdlType _makeListForElem(VdlType elemType) {
  VdlPendingType pt = new VdlPendingType()
  ..kind = VdlKind.List
  ..elem = elemType;
  return pt.build();
}
