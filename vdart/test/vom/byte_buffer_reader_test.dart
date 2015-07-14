library vom;

import 'package:test/test.dart';

import 'dart:core';

part '../../lib/src/vom/exceptions.part.dart';
part '../../lib/src/vom/byte_buffer_reader.part.dart';

void main() {
  group('_ByteBufferReader', () {
    test('read byte', () {
      var bbr = new _ByteBufferReader(<int>[3, 4, 5]);
      expect(bbr.getMarker(), equals(0));
      expect(bbr.readByte(), equals(3));
      expect(bbr.getMarker(), equals(1));
      expect(bbr.readByte(), equals(4));
      expect(bbr.getMarker(), equals(2));
    });
    test('empty read', () {
      var bbr = new _ByteBufferReader(<int>[3, 4, 5]);
      expect(bbr.read(0), equals(<int>[]));
      expect(bbr.getMarker(), equals(0));
    });
    test('multiple read', () {
      var bbr = new _ByteBufferReader(<int>[3, 4, 5, 6, 7, 8]);
      expect(bbr.read(2), equals(<int>[3, 4]));
      expect(bbr.getMarker(), equals(2));
      expect(bbr.read(3), equals(<int>[5, 6, 7]));
      expect(bbr.getMarker(), equals(5));
    });
    test('read byte beyond buffered size', () {
      var bbr = new _ByteBufferReader(<int>[3]);
      expect(bbr.readByte(), equals(3));
      expect(() => bbr.readByte(),
        throwsA(new isInstanceOf<LowLevelVomDecodeException>()));
    });
    test('read bytes beyond buffered size', () {
      var bbr = new _ByteBufferReader(<int>[3, 5]);
      expect(bbr.readByte(), equals(3));
      expect(() => bbr.read(2),
        throwsA(new isInstanceOf<LowLevelVomDecodeException>()));
    });
    test('set marker', () {
      var bbr = new _ByteBufferReader(<int>[3, 4, 5, 6]);
      bbr.setMarker(2);
      expect(bbr.read(2), equals(<int>[5, 6]));
    });
    test('set negative marker', () {
      var bbr = new _ByteBufferReader(<int>[3, 5]);
      expect(() => bbr.setMarker(-1),
        throwsA(new isInstanceOf<LowLevelVomDecodeException>()));
    });
    test('set marker beyond buffered size', () {
      var bbr = new _ByteBufferReader(<int>[3, 5]);
      expect(() => bbr.setMarker(3),
        throwsA(new isInstanceOf<LowLevelVomDecodeException>()));
    });
  });
}