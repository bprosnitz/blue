library vom;

import 'dart:core';
import 'dart:typed_data';
import 'dart:convert';

import 'package:benchmark_harness/benchmark_harness.dart';

part 'exceptions.part.dart';
part 'byte_buffer_writer.part.dart';
part 'low_level_vom_writer.part.dart';
part 'byte_buffer_reader.part.dart';
part 'low_level_vom_reader.part.dart';

void main() {
  // Test low level int and bytes encoding/decoding.
  new LowLevelVomDecodeIntBenchmark().report();
  new LowLevelVomEncodeIntBenchmark().report();
  new LowLevelVomDecodeBytesBenchmark().report();
  new LowLevelVomEncodeBytesBenchmark().report();
}

List<int> encodeInts() {
    var bw = new _ByteBufferWriter();
    var writer = new _LowLevelVomWriter(bw);
    for (int i = -100000; i < 100000; i += 456) {
      writer.writeInt(i);
    }
    return bw.bytes;
}

// Benchmark decoding encoded integers from buffered vom data.
class LowLevelVomDecodeIntBenchmark extends BenchmarkBase {
  LowLevelVomDecodeIntBenchmark() : super("low level vom - decode int - from buffer - v1");
  final List<int> data = encodeInts();
  void run() {
    var br = new _ByteBufferReader(data);
    var reader = new _LowLevelVomReader(br);
    for (int i = -100000; i < 100000; i += 456) {
      reader.readInt();
    }
  }
}

// Benchmark encoding integers to a buffer.
class LowLevelVomEncodeIntBenchmark extends BenchmarkBase {
  const LowLevelVomEncodeIntBenchmark() : super("low level vom - encode int - to buffer - v1");
  void run() {
    encodeInts();
  }
}

// Pregenerate example byte arrays.
List<Uint8List> createByteExamples() {
  List<Uint8List> dat = new List<Uint8List>();
  int sizeInterval = 1000;
  for (var i = 0; i < 100; i++) {
    dat.add(createUint8List(sizeInterval * i));
  }
  return dat;
}
Uint8List createUint8List(int size) {
  var lst = new Uint8List(size);
  lst.fillRange(0, size, 0x07);
  return lst;
}

List<int> encodeBytes(List<Uint8List> examples) {
    var bw = new _ByteBufferWriter();
    var writer = new _LowLevelVomWriter(bw);
    for (var example in examples) {
      writer.writeBytes(example);
    }
    return bw.bytes;
}

// Benchmark decoding bytes from buffered vom data.
class LowLevelVomDecodeBytesBenchmark extends BenchmarkBase {
  LowLevelVomDecodeBytesBenchmark() : super("low level vom - decode bytes - from buffer - v1");
  final List<int> data = encodeBytes(createByteExamples());
  void run() {
    var br = new _ByteBufferReader(data);
    var reader = new _LowLevelVomReader(br);
    for (var i = 0; i < 100; i++) {
      reader.readBytes();
    }
  }
}

// Benchmark encoding bytes to a buffer.
class LowLevelVomEncodeBytesBenchmark extends BenchmarkBase {
  LowLevelVomEncodeBytesBenchmark() : super("low level vom - encode bytes - to buffer - v1");
  final List<Uint8List> examples = createByteExamples();
  void run() {
    encodeBytes(examples);
  }
}