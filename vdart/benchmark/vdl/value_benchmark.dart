import 'dart:core';

import 'package:benchmark_harness/benchmark_harness.dart';
import '../../lib/src/vdl/vdl.dart' as vdl;
import '../../test/vdl/value_test_types.dart' as value_test_types;

void main() {
  // These benchmarks run off abcStructType in value_types.dart
  new VdlValueZeroBenchmark().report();
  new VdlValueCopyBenchmark().report();
  new VdlValueGetterBenchmark().report();
  new VdlValueSetterBenchmark().report();
  new VdlValueAssignBenchmark().report();
  new VdlValueEqualFirstBenchmark().report(); // first call to ==
  new VdlValueEqualBenchmark().report();
  new VdlValueHashFirstBenchmark().report(); // first call to hashCode
  new VdlValueHashBenchmark().report();
  new VdlValueStringFirstBenchmark().report(); // first call to toString
  new VdlValueStringBenchmark().report();

  // These benchmarks run off bool3ArrayType in value_types.dart
  new VdlValueArrayZeroBenchmark().report();
  new VdlValueArrayIterateBenchmark().report();
}

class VdlValueZeroBenchmark extends BenchmarkBase {
  VdlValueZeroBenchmark() : super("VdlValue - zero constructor - v1");

  void run() {
    new vdl.VdlValue.zero(value_test_types.abcStructType);
  }
}

class VdlValueCopyBenchmark extends BenchmarkBase {
  vdl.VdlValue z;
  VdlValueCopyBenchmark() : super("VdlValue - copy constructor - v1");

  void setup() {
    z = new vdl.VdlValue.zero(value_test_types.abcStructType);
  }

  void run() {
    new vdl.VdlValue.copy(z);
  }
}

class VdlValueGetterBenchmark extends BenchmarkBase {
  vdl.VdlValue a;
  VdlValueGetterBenchmark() : super("VdlValue - get string - v1");

  void setup() {
    a = new vdl.VdlValue.zero(value_test_types.abcStructType).
      structFieldByName('A');
  }

  void run() {
    a.asString; // get the string
  }
}

class VdlValueSetterBenchmark extends BenchmarkBase {
  vdl.VdlValue a;
  VdlValueSetterBenchmark() : super("VdlValue - set string - v1");

  void setup() {
    a = new vdl.VdlValue.zero(value_test_types.abcStructType).
      structFieldByName('A');
  }

  void run() {
    a.asString = 'hello'; // set the string
  }
}

class VdlValueAssignBenchmark extends BenchmarkBase {
  vdl.VdlValue a, b;
  VdlValueAssignBenchmark() : super("VdlValue - assign - v1");

  void setup() {
    a = new vdl.VdlValue.zero(value_test_types.abcStructType).
      structFieldByName('A');
    b = vdl.stringValue('hello');
  }

  void run() {
    a.assign(b); // assign a VdlValue
  }
}

class VdlValueEqualFirstBenchmark extends BenchmarkBase {
  vdl.VdlValue a, b;
  VdlValueEqualFirstBenchmark() : super("VdlValue - a == b (first time) - v1");

  void setup() {
    a = new vdl.VdlValue.zero(value_test_types.abcStructType);
    b = new vdl.VdlValue.zero(value_test_types.abcStructType);
  }

  void run() {
    a == b;
  }
}

class VdlValueEqualBenchmark extends BenchmarkBase {
  vdl.VdlValue a, b;
  VdlValueEqualBenchmark() : super("VdlValue - a == b - v1");

  void setup() {
    a = new vdl.VdlValue.zero(value_test_types.abcStructType);
    b = new vdl.VdlValue.zero(value_test_types.abcStructType);
    a == b; // Potentially initialize values in a and b
  }

  void run() {
    a == b;
  }
}

class VdlValueHashFirstBenchmark extends BenchmarkBase {
  vdl.VdlValue a;
  VdlValueHashFirstBenchmark() : super("VdlValue - hashCode (first time) - v1");

  void setup() {
    a = new vdl.VdlValue.zero(value_test_types.abcStructType);
  }

  void run() {
    a.hashCode;
  }
}

class VdlValueHashBenchmark extends BenchmarkBase {
  vdl.VdlValue a;
  VdlValueHashBenchmark() : super("VdlValue - hashCode - v1");

  void setup() {
    a = new vdl.VdlValue.zero(value_test_types.abcStructType);
    a.hashCode;  // Potentially initialize the internal values early.
  }

  void run() {
    a.hashCode;
  }
}

class VdlValueStringFirstBenchmark extends BenchmarkBase {
  vdl.VdlValue a;
  VdlValueStringFirstBenchmark() : super("VdlValue - toString (first time) - v1");

  void setup() {
    a = new vdl.VdlValue.zero(value_test_types.abcStructType);
  }

  void run() {
    a.toString();
  }
}

class VdlValueStringBenchmark extends BenchmarkBase {
  vdl.VdlValue a;
  VdlValueStringBenchmark() : super("VdlValue - toString - v1");

  void setup() {
    a = new vdl.VdlValue.zero(value_test_types.abcStructType);
    a.toString(); // Potentially initialize the internal values early.
  }

  void run() {
    a.toString();
  }
}

class VdlValueArrayZeroBenchmark extends BenchmarkBase {
  VdlValueArrayZeroBenchmark() : super("VdlValue - array zero - v1");

  void run() {
    // This creates the VdlValue and might not initialize the internal values.
    new vdl.VdlValue.zero(value_test_types.boolArray3Type);
  }
}

class VdlValueArrayIterateBenchmark extends BenchmarkBase {
  vdl.VdlValue a;
  VdlValueArrayIterateBenchmark() : super("VdlValue - array iterate - v1");

  void setup() {
    a = new vdl.VdlValue.zero(value_test_types.boolArray3Type);
  }

  void run() {
    // Guarantees the initialization of all values in the VdlValue's array.
    a.asList.forEach((v) => v);
  }
}