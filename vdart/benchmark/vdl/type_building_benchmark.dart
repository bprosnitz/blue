library vdl;

import 'dart:core';
import 'dart:collection';

import 'package:benchmark_harness/benchmark_harness.dart';

part '../../lib/src/vdl/type.part.dart';

void main() {
  new TypeBuildingBenchmark().report();
}

// Benchmark building VdlTypes from VdlPendingTypes
class TypeBuildingBenchmark extends BenchmarkBase {
  TypeBuildingBenchmark() : super("building types - v1");

  static int runNum = 0;
  void run() {
    runNum++;
    // Change name every run so that objects don't hash cons to same thing.
    String name = runNum.toString();

    var ptStruct = new VdlPendingType();
    ptStruct.name = name;
    ptStruct.kind = VdlKind.Struct;
    var ptList = new VdlPendingType();
    var ptEnum = new VdlPendingType();
    ptStruct.fields = [
      new VdlPendingField('list', ptList),
      new VdlPendingField('enum', ptEnum),
    ];
    ptEnum.name = name + 'enum';
    ptEnum.kind = VdlKind.Enum;
    ptEnum.labels = ['q', 'r', 's'];
    ptList.kind = VdlKind.List;
    ptList.elem = ptStruct;

    ptStruct.build();
    ptStruct.build();
  }
}