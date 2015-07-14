library vom;

import 'package:test/test.dart';

import 'dart:core';
import 'dart:typed_data';
import 'dart:math';

part '../../lib/src/vom/exceptions.part.dart';
part '../../lib/src/vom/byte_buffer_writer.part.dart';

void main() {
  group('_ByteBufferWriter', () {
    test('simple write', () {
      List<int> data = <int>[255, 8, 4, 7, 4, 0, 12];
      _ByteBufferWriter bbw = new _ByteBufferWriter();
      bbw.write(<int>[255, 8, 4, 7]);
      bbw.write(<int>[4, 0, 12]);
      expect(bbw.getMarker(), equals(7), reason: 'correct marker');
      expect(bbw.allocatedSize,
        equals(max(8, _ByteBufferWriter._INITIAL_SIZE)),
        reason: 'correct buffer size');
      expect(bbw.bytes, equals(data), reason: 'correct data');
    });
    test('buffer grows with write', () {
      _ByteBufferWriter bbw = new _ByteBufferWriter();
      expect(bbw.getMarker(), equals(0), reason: 'marker initially zero');
      expect(_ByteBufferWriter._INITIAL_SIZE & 0x01 == 0 &&
        _ByteBufferWriter._INITIAL_SIZE > 0, isTrue,
        reason: 'initial size expected to be a power of 2');
      expect(bbw.allocatedSize, equals(_ByteBufferWriter._INITIAL_SIZE),
        reason: 'initially have initial size');
      expect(bbw.bytes, equals(new Uint8List(0)),
        reason: 'bytes are initially empty and non-null');

      Uint8List initialSizeData = new Uint8List(_ByteBufferWriter._INITIAL_SIZE);
      initialSizeData[2] = 6;
      bbw.write(initialSizeData);
      expect(bbw.getMarker(), equals(initialSizeData.length),
        reason: 'marker at end of written data');
      expect(bbw.allocatedSize, equals(_ByteBufferWriter._INITIAL_SIZE),
        reason: 'should not have grown');
      expect(bbw.bytes, equals(initialSizeData),
        reason: 'should have written data');

      bbw.write(<int>[5, 4]);
      expect(bbw.getMarker(), equals(initialSizeData.length + 2),
        reason:'marker should have increased by 2');
      expect(bbw.allocatedSize, equals(_ByteBufferWriter._INITIAL_SIZE* 2),
        reason: 'data size should have doubled');
      Uint8List expected = new Uint8List(initialSizeData.length + 2);
      expected[expected.length - 2] = 5;
      expected[expected.length - 1] = 4;
      expected[2] = 6;
      expect(bbw.bytes, equals(expected),
        reason: 'should have correct data after growing');
    });
    test('handles growth by multiple powers of 2', () {
      _ByteBufferWriter bbw = new _ByteBufferWriter();
      Uint8List data = new Uint8List(8 * _ByteBufferWriter._INITIAL_SIZE - 1);
      data[1] = 6;
      bbw.write(data);
      expect(bbw.getMarker(), equals(data.length),
        reason: 'marker at end of written data');
      expect(bbw.allocatedSize, equals(data.length + 1),
        reason: 'buffer should have grown to this size');
      expect(bbw.bytes, equals(data), reason: 'should have correct data');
    });
    test('modifying written list doesn\'t change buffered data', () {
      _ByteBufferWriter bbw = new _ByteBufferWriter();
      Uint8List data = new Uint8List(10);
      data[1] = 6;
      Uint8List copy = new Uint8List.fromList(data);
      bbw.write(data);
      data[2] = 7;
      expect(bbw.bytes, equals(copy));
    });
    test('writeByte', () {
      _ByteBufferWriter bbw = new _ByteBufferWriter();
      bbw.writeByte(4);
      bbw.writeByte(6);
      expect(bbw.getMarker(), equals(2), reason: 'correct marker');
      expect(bbw.allocatedSize,
        equals(max(2, _ByteBufferWriter._INITIAL_SIZE)),
        reason: 'correct buffer size');
      expect(bbw.bytes, equals(<int>[4, 6]), reason: 'correct data');
    });
    test('grows from writeByte', () {
      _ByteBufferWriter bbw = new _ByteBufferWriter();
      for (int i = 0; i < _ByteBufferWriter._INITIAL_SIZE * 4 - 1; i++) {
        bbw.writeByte(7);
      }
      expect(bbw.getMarker(), equals(_ByteBufferWriter._INITIAL_SIZE * 4 - 1),
        reason: 'correct marker');
      expect(bbw.allocatedSize, equals(_ByteBufferWriter._INITIAL_SIZE * 4),
        reason: 'correct buffer size');
      var expected = new Uint8List(_ByteBufferWriter._INITIAL_SIZE * 4 - 1);
      expected.fillRange(0, expected.length, 7);
      expect(bbw.bytes, equals(expected), reason: 'correct data');
    });
    test('decreasing marker then fetching bytes', () {
      _ByteBufferWriter bbw = new _ByteBufferWriter();
      bbw.write(<int>[255, 8, 4, 7]);
      bbw.setMarker(3);
      expect(bbw.getMarker(), equals(3), reason: 'marker has set value');
      expect(bbw.bytes, equals(<int>[255, 8, 4]),
        reason: 'should get bytes up to marker');
    });
    test('decreasing marker then writing', () {
      _ByteBufferWriter bbw = new _ByteBufferWriter();
      bbw.write(<int>[255, 8, 4, 7]);
      bbw.setMarker(3);
      bbw.write([77, 81]);
      expect(bbw.getMarker(), equals(5), reason: 'expected marker point');
      expect(bbw.bytes, equals(<int>[255, 8, 4, 77, 81]),
        reason: 'bytes should have been modified');
    });
    test('increasing marker then fetching bytes', () {
      _ByteBufferWriter bbw = new _ByteBufferWriter();
      bbw.write(<int>[255, 8, 4]);
      // increase the marker to a point where it should grow.
      bbw.setMarker(_ByteBufferWriter._INITIAL_SIZE * 4 - 1);
      expect(bbw.getMarker(), equals(_ByteBufferWriter._INITIAL_SIZE * 4 - 1),
        reason: 'expected marker point');
      var expected = new Uint8List(_ByteBufferWriter._INITIAL_SIZE * 4 - 1);
      expected[0] = 255;
      expected[1] = 8;
      expected[2] = 4;
      expect(bbw.bytes, equals(expected),
        reason: 'expected bytes after growth');
    });
    test('increasing marker then writing', () {
      _ByteBufferWriter bbw = new _ByteBufferWriter();
      bbw.write(<int>[255, 8, 4]);
      bbw.setMarker(bbw.getMarker() + 1);
      bbw.writeByte(8);
      expect(bbw.bytes, equals(<int>[255, 8, 4, 0, 8]),
        reason:'expected bytes');
    });
  });
}