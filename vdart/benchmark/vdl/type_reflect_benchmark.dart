library vdl;

import 'dart:core';
import 'dart:collection';
import 'dart:mirrors' as mirrors;
import 'dart:typed_data' as typed_data;

import '../../lib/src/collection/collection.dart' as collection;

import 'package:benchmark_harness/benchmark_harness.dart';

part '../../lib/src/vdl/casing.part.dart';
part '../../lib/src/vdl/type.part.dart';
part '../../lib/src/vdl/reflect.part.dart';

void main() {
  new PrimitiveTypeReflectionBenchmark().report();
  new AnnotatedTypeReflectionBenchmark().report();
  new MapTypeReflectionBenchmark().report();
  new StructTypeReflectionBenchmark().report();
  new Uint8ListTypeReflectionBenchmark().report();
}

class PrimitiveTypeReflectionBenchmark extends BenchmarkBase {
  PrimitiveTypeReflectionBenchmark() : super("type reflection - primitive - v1");

  void run() {
    vdlTypeOf('String');
  }
}

class AnnotatedType {
  static final VdlType vdlType = VdlTypes.Int32;
}

class AnnotatedTypeReflectionBenchmark extends BenchmarkBase {
  AnnotatedTypeReflectionBenchmark() : super("type reflection - annotated - v1");

  AnnotatedType annotatedValue = new AnnotatedType();

  void run() {
    vdlTypeOf(annotatedValue);
  }
}

class MapTypeReflectionBenchmark extends BenchmarkBase {
  MapTypeReflectionBenchmark() : super("type reflection - map - v1");

  Map<String, AnnotatedType> mapValue = new Map<String, AnnotatedType>();

  void run() {
    vdlTypeOf(mapValue);
  }
}

class CustomStruct {
  String a;
  int get b => 5;
  AnnotatedType c;
}

class StructTypeReflectionBenchmark extends BenchmarkBase {
  StructTypeReflectionBenchmark() : super("type reflection - struct - v1");

  CustomStruct structValue = new CustomStruct();

  void run() {
    vdlTypeOf(structValue);
  }
}

class Uint8ListTypeReflectionBenchmark extends BenchmarkBase {
  Uint8ListTypeReflectionBenchmark() : super("type reflection - uint8list - v1");

  typed_data.Uint8List list = new typed_data.Uint8List(0);

  void run() {
    vdlTypeOf(list);
  }
}