library vdl;

import 'dart:core';
import 'dart:collection';
import 'dart:mirrors' as mirrors;
import 'dart:typed_data' as typed_data;

import '../collection/collection.dart' as collection;

import 'package:benchmark_harness/benchmark_harness.dart';

part 'casing.part.dart';
part 'type.part.dart';
part 'reflect.part.dart';

void main() {
  new PrimitiveTypeReflectionBenchmark().report();
  new AnnotatedTypeReflectionBenchmark().report();
  new MapTypeReflectionBenchmark().report();
  new StructTypeReflectionBenchmark().report();
  new Uint8ListTypeReflectionBenchmark().report();
}

class PrimitiveTypeReflectionBenchmark extends BenchmarkBase {
  PrimitiveTypeReflectionBenchmark() : super("type reflection - 1000x primitive - v1");

  void run() {
    for (var i = 0; i < 1000; i++) {
      vdlTypeOf('String');
    }
  }
}

class AnnotatedType {
  static final VdlType vdlType = VdlTypes.Int32;
}

class AnnotatedTypeReflectionBenchmark extends BenchmarkBase {
  AnnotatedTypeReflectionBenchmark() : super("type reflection - 1000x annotated - v1");

  void run() {
    var annotatedValue = new AnnotatedType();
    for (var i = 0; i < 1000; i++) {
      vdlTypeOf(annotatedValue);
    }
  }
}

class MapTypeReflectionBenchmark extends BenchmarkBase {
  MapTypeReflectionBenchmark() : super("type reflection - 1000x map - v1");

  void run() {
    var mapValue = new Map<String, AnnotatedType>();
    for (var i = 0; i < 1000; i++) {
      vdlTypeOf(mapValue);
    }
  }
}

class CustomStruct {
  String a;
  int get b => 5;
  AnnotatedType c;
}

class StructTypeReflectionBenchmark extends BenchmarkBase {
  StructTypeReflectionBenchmark() : super("type reflection - 1000x struct - v1");

  void run() {
    var structValue = new CustomStruct();
    for (var i = 0; i < 1000; i++) {
      vdlTypeOf(structValue);
    }
  }
}

class Uint8ListTypeReflectionBenchmark extends BenchmarkBase {
  Uint8ListTypeReflectionBenchmark() : super("type reflection - 1000x uint8list - v1");

  void run() {
    var list = new typed_data.Uint8List(0);
    for (var i = 0; i < 1000; i++) {
      vdlTypeOf(list);
    }
  }
}