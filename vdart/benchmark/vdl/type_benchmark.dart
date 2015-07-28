library vdl;

import 'dart:core';
import 'dart:collection';

import 'package:benchmark_harness/benchmark_harness.dart';

part '../../lib/src/vdl/type.part.dart';

void main() {
  new PendingTypePrimitiveUniqueStrBenchmark().report();
  new PendingTypeRecursiveUniqueStrBenchmark().report();
  new PendingTypePrimitiveValidateBenchmark().report();
  new PendingTypeRecursiveValidateBenchmark().report();
  new TypeToStringBenchmark().report();
  new TypeTraversingBenchmark().report();
}


abstract class PendingTypePrimitiveBenchmarkBase extends BenchmarkBase {
  PendingTypePrimitiveBenchmarkBase(String msg) : super(msg);

  VdlPendingType pt = new VdlPendingType()
    ..kind = VdlKind.Int32
    ..name = 'CustomInt32';
}
// Benchmark creating a unique string for a primitive.
class PendingTypePrimitiveUniqueStrBenchmark extends PendingTypePrimitiveBenchmarkBase {
  PendingTypePrimitiveUniqueStrBenchmark() : super('vdl pending type - unique string - primitive - v1');
  void run() {
    pt.toString();
  }
}
// Benchmark validating a primitive.
class PendingTypePrimitiveValidateBenchmark extends PendingTypePrimitiveBenchmarkBase {
  PendingTypePrimitiveValidateBenchmark() : super('vdl pending type - validate - primitive - v1');
  void run() {
    pt.validate();
  }
}

abstract class PendingTypeRecursiveBenchmarkBase extends BenchmarkBase {
  PendingTypeRecursiveBenchmarkBase(String msg) : super(msg);

  VdlPendingType pt;

  void setup() {
    pt = new VdlPendingType()
      ..kind = VdlKind.Struct
      ..name = 'RecursiveStruct';
    VdlPendingType ptList = new VdlPendingType()
      ..kind = VdlKind.List
      ..elem = pt;
    pt.fields = [
      new VdlPendingField('ListField', pt)
    ];
  }
}
// Benchmark creating a unique string for a recursive type.
class PendingTypeRecursiveUniqueStrBenchmark extends PendingTypeRecursiveBenchmarkBase {
  PendingTypeRecursiveUniqueStrBenchmark() : super('vdl pending type - unique string - recursive - v1');
  void run() {
    pt.toString();
  }
}
// Benchmark validating a recursive type.
class PendingTypeRecursiveValidateBenchmark extends PendingTypeRecursiveBenchmarkBase {
  PendingTypeRecursiveValidateBenchmark() : super('vdl pending type - validate - recursive - v1');
  void run() {
    pt.validate();
  }
}


// Benchmark calling toString() on a built recursive type.
class TypeToStringBenchmark extends PendingTypeRecursiveBenchmarkBase {
  VdlType type;
  void setup() {
    super.setup();

    type = pt.build();
  }
  TypeToStringBenchmark() : super('vdl type - toString - recursive - v1');
  void run() {
    type.toString();
  }
}

// Benchmark traversing a built recursive type.
class TypeTraversingBenchmark extends PendingTypeRecursiveBenchmarkBase {
  VdlType type;
  void setup() {
    super.setup();

    type = pt.build();
  }
  TypeTraversingBenchmark() : super('vdl type - traverse - recursive - v1');
  void run() {
    type.fields[0].type.fields[0].type;
  }
}
