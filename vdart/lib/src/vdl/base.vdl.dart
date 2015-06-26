// This is what base.vdl.dart could look like.
// Essentially, it needs to create a lot of types.
// Luckily, we can just put them all in the same file.

// TODO(alexfandrianto): We still need a representation for vdl.Value and
// vdl.Type.
// We also need errors, service interfaces, constants, and imports.

import 'dart:collection';

class NamedBool {
  bool value = false;
  NamedBool.withValue(this.value);
}

class NamedByte {
  int value = 0;

  NamedByte.withValue(int value) {
    assert(value >= 0 && value < 256); // We need assertions on every int.
    this.value = value;
  }
}

class NamedString {
  String value = '';
  NamedString.withValue(this.value);
}

enum NamedEnum { A, B, C }

class NamedArray extends ListBase<bool> {
  final List<bool> l = new List<bool>(2); // Different!
  NamedArray();
  NamedArray.withValue(List<bool> val) {
    for (var i = 0; i < val.length && i < l.length; i++) {
      // Different!
      l[i] = val[i];
    }
  }

  void set length(int newLength) {
    l.length = newLength;
  }
  int get length => l.length;
  bool operator [](int index) => l[index];
  void operator []=(int index, bool value) {
    l[index] = value;
  }

  List<bool> get value => l;
}

// The example is with uint32, so it needs some type-checking during
// construction and set.
class NamedList extends ListBase<int> {
  final List<int> l = new List<int>();

  NamedList();
  NamedList.withValue(List<int> val) {
    for (var i = 0; i < val.length; i++) {
      l[i] = val[i];
    }
  }

  void set length(int newLength) {
    l.length = newLength;
  }
  int get length => l.length;
  int operator [](int index) => l[index];
  void operator []=(int index, int value) {
    l[index] = value;
  }

  List<int> get value => l;
}

class NamedSet extends SetBase<String> {
  final Set<String> s = new Set<String>();

  NamedSet();
  NamedSet.withValue(Set<String> val) {
    val.forEach((e) => s.add(e));
  }

  // All required thingies
  bool add(String e) => s.add(e);
  get length => s.length;
  Set<String> toSet() => s.toSet();
  List<String> toList({bool growable: true}) => s.toList(growable: growable);
  bool remove(Object element) => s.remove(element);
  bool contains(Object element) => s.contains(element);
  String lookup(String element) => s.lookup(element);
  Iterator<String> get iterator => s.iterator;

  Set<String> get value => s;
}

// float32 is double
class NamedMap extends MapBase<String, double> {
  final Map<String, double> m = new Map<String, double>();

  NamedMap();
  NamedMap.withValue(Map<String, double> val) {
    val.forEach((k, v) => m[k] = v);
  }

  double operator [](String key) => m[key];
  void operator []=(String key, double value) {
    m[key] = value;
  }

  void clear() => m.clear();
  double remove(Object element) => m.remove(element);

  Iterable<String> get keys => m.keys;

  Map<String, double> get value => m;
}

// Really easy; I don't think we need to do anything else.
class NamedStruct {
  bool a;
  String b;
  int c;

  NamedStruct() {
    a = false;
    b = '';
    c = 0;
  }
  NamedStruct.withValue({this.a: false, this.b: '', this.c: 0});
}

// A union base class extended by several subclasses should be usable enough.
// It'll be up to users to determine the exact subclass, if they need it.
// They can use union.value to get the data or union.name, otherwise.
abstract class NamedUnion {
  dynamic _data;
  void set value(dynamic val); // abstract, override with the correct type
  dynamic get value; // abstract, override with the correct type
  int get index; // abstract
  String get name; // abstract
}

class NamedUnionA extends NamedUnion {
  NamedUnionA() {
    _data = false;
  }
  NamedUnionA.withValue(bool value) {
    _data = value;
  }

  void set value(bool val) {
    _data = val;
  }
  bool get value => _data;
  int get index => 0;
  String get name => 'A';
}

class NamedUnionB extends NamedUnion {
  NamedUnionB() {
    _data = '';
  }
  NamedUnionB.withValue(String value) {
    _data = value;
  }

  void set value(String val) {
    _data = val;
  }
  String get value => _data;
  int get index => 1;
  String get name => 'B';
}

class NamedUnionC extends NamedUnion {
  NamedUnionC() {
    _data = 0;
  }
  NamedUnionC.withValue(int value) {
    _data = value;
  }

  void set value(int val) {
    _data = val;
  }
  int get value => _data;
  int get index => 2;
  String get name => 'C';
}


class NamedUnionAlt {
  dynamic _data;
  int _index;

  dynamic get value => _data; // abstract, override with the correct type
  int get index => _index;
  String get name {
    switch(_index) {
      case 0:
        return 'A';
      case 1:
        return 'B';
      case 2:
        return 'C';
      default:
        return 'error';
    }
  }

  bool get valueA => _index == 0 ? _data : null;
  String get valueB => _index == 1 ? _data : null;
  int get valueC => _index == 2 ? _data : null;

  // maybe not a useful constructor
  NamedUnionAlt() {
    _data = false;
    _index = 0;
  }

  NamedUnionAlt.a(bool value) {
    _data = value;
    _index = 0;
  }
  NamedUnionAlt.b(String value) {
    _data = value;
    _index = 1;
  }
  NamedUnionAlt.c(int value) {
    _data = value;
    _index = 2;
  }
}