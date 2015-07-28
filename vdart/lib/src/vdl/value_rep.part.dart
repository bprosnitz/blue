part of vdl;

/// RepUnion represents the VdlValue form of a union.
/// It contains the index of the union that is set and its corresponding
/// VdlValue value.
class RepUnion {
  final int index;
  final VdlValue value;
  final VdlType _t; // Its parent VdlType.
  RepUnion._(this._t, this.index, this.value);

  String toString() {
    return '{${_t.fields[index].name}: '
      '${VdlValue._stringRep(value.type, value._rep)}}';
  }
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! RepUnion) {
      return false;
    }
    RepUnion ru = other as RepUnion;
    return _t == ru._t && index == ru.index && value == ru.value;
  }
  int get hashCode => quiver_core.hash3(_t, index, value);
}

/// RepSequence represents a sequence of VdlValue.
/// It acts like List<VdlValue> but also performs lazy initialization.
class RepSequence extends ListBase<VdlValue> {
  final List<VdlValue> _data;
  final VdlType _t; // Its parent VdlType.

  RepSequence._(VdlType t) : _t = t, _data = _makeList(t);
  RepSequence._fromList(VdlType t, List<VdlValue> d) :
    _t = t, _data = _makeCopy(t, d);

  static List<VdlValue> _makeList(VdlType t) {
    if (t.kind == VdlKind.Array) {
      return new List<VdlValue>(t.len);
    } else if (t.kind == VdlKind.Struct) {
      return new List<VdlValue>(t.fields.length);
    }
    return new List<VdlValue>();
  }
  static List<VdlValue> _makeCopy(VdlType t, List<VdlValue> d) {
    List<VdlValue> cpy = _makeList(t);

    // If this is a list type, then it needs to amend its length before
    // copying the values over.
    if (t.kind == VdlKind.List) {
      cpy.length = d.length;
    }

    for (int i = 0; i < d.length; i++) {
      cpy[i] = new VdlValue.copy(d[i]);
    }
    return cpy;
  }

  void set length(int newLength) {
    _data.length = newLength;
  }
  int get length => _data.length;
  VdlValue operator [](int index) {
    // Lazy initialization: If necessary, initialize the value.
    if (_data[index] == null) {
      if (_t.kind == VdlKind.Struct) {
        _data[index] = new VdlValue.zero(_t.fields[index].type);
      } else {
        _data[index] = new VdlValue.zero(_t.elem);
      }
    }
    return _data[index];
  }
  void operator []=(int index, VdlValue value) {
    _data[index] = value;
  }

  // TODO(alexfandrianto): StringBuffer
  String toString() {
    String seqString = '';
    for (int i = 0; i < _data.length; i++) {
      if (i > 0) {
        seqString += ', ';
      }
      if (_t.kind == VdlKind.Struct) {
        seqString += '${_t.fields[i].name}: ${VdlValue._stringRep(this[i].type, this[i]._rep)}';
      } else {
        seqString += '${VdlValue._stringRep(this[i].type, this[i]._rep)}';
      }
    }
    return '{${seqString}}';
  }

  // Due to the lazy initialization, one has to be careful when doing == and
  // hashCode. We have to make sure the data is zero'd.
  void _zeroData() {
    for (VdlValue _ in this) {}
  }

  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! RepSequence) {
      return false;
    }
    RepSequence rs = other as RepSequence;
    this._zeroData();
    rs._zeroData();
    return this._t == rs._t && quiver_collection.listsEqual(this._data, rs._data);
  }
  // Hash both the parent VdlType and the underlying data list.
  // A reason to include the type is to differentiate between array and list.
  int get hashCode {
    this._zeroData();
    return quiver_core.hash2(_t, quiver_core.hashObjects(this._data));
  }
}

/// RepSet represents a Set of VdlValue to VdlValue.
/// It acts like Set<VdlValue> but prints differently.
class RepSet extends SetBase<VdlValue> {
  final Set<VdlValue> _data;

  RepSet._() : _data = new Set<VdlValue>();
  RepSet._from(RepSet other) : _data = _makeCopy(other);

  static Set<VdlValue> _makeCopy(RepSet d) {
    Set<VdlValue> cpy = new Set<VdlValue>();
    for (VdlValue k in d) {
      cpy.add(new VdlValue.copy(k));
    }
    return cpy;
  }

  int get length => _data.length;
  Iterator<VdlValue> get iterator => _data.iterator;
  VdlValue lookup(VdlValue element) => _data.lookup(element);
  bool contains(Object element) => _data.contains(element);
  bool add(VdlValue element) => _data.add(element);
  bool remove(Object element) => _data.remove(element);
  Set<VdlValue> toSet() => _data.toSet();

  // TODO(alexfandrianto): StringBuffer
  String toString() {
    String sString = '';
    int i = 0;
    for (VdlValue key in _data) {
      if (i > 0) {
        sString += ', ';
      }
      sString += '${VdlValue._stringRep(key.type, key._rep)}';
      i++;
    }
    return '{${sString}}';
  }

  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! RepSet) {
      return false;
    }
    RepSet rs = other as RepSet;
    return quiver_collection.setsEqual(this._data, rs._data);
  }
  int get hashCode => quiver_core.hashObjects(_data);
}

/// RepMap represents a Map of VdlValue to VdlValue.
/// It acts like Map<VdlValue, VdlValue> but prints differently.
class RepMap extends MapBase<VdlValue, VdlValue> {
  final Map<VdlValue, VdlValue> _data;

  RepMap._() : _data = new Map<VdlValue, VdlValue>();
  RepMap._from(RepMap other) : _data = _makeCopy(other);

  static Map<VdlValue, VdlValue> _makeCopy(RepMap d) {
    Map<VdlValue, VdlValue> cpy = new Map<VdlValue, VdlValue>();
    d.forEach((VdlValue k, VdlValue v) {
      cpy[new VdlValue.copy(k)] = new VdlValue.copy(v);
    });
    return cpy;
  }

  Iterable<VdlValue> get keys => _data.keys;
  int get length => _data.length;
  VdlValue operator [](VdlValue key) => _data[key];
  void operator []=(VdlValue key, VdlValue value) {
    _data[key] = value;
  }
  void clear() {
    _data.clear();
  }
  VdlValue remove(Object key) {
    return _data.remove(key);
  }

  // TODO(alexfandrianto): StringBuffer
  String toString() {
    String mString = '';
    int i = 0;
    _data.forEach((VdlValue key, VdlValue value) {
      if (i > 0) {
        mString += ', ';
      }
      mString += '${VdlValue._stringRep(key.type, key._rep)}: '
        '${VdlValue._stringRep(value.type, value._rep)}';
      i++;
    });
    return '{${mString}}';
  }

  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! RepMap) {
      return false;
    }
    RepMap rm = other as RepMap;
    return quiver_collection.mapsEqual(this._data, rm._data);
  }
  int get hashCode => quiver_core.hash2(
    quiver_core.hashObjects(_data.keys),
    quiver_core.hashObjects(_data.values)
  );
}