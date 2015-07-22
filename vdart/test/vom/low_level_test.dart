library vom;

import 'package:test/test.dart';

import 'dart:core';
import 'dart:typed_data';
import 'dart:convert';

import '../test_util/test_util.dart' as test_util;

part '../../lib/src/vom/exceptions.part.dart';
part '../../lib/src/vom/byte_buffer_writer.part.dart';
part '../../lib/src/vom/low_level_vom_writer.part.dart';
part '../../lib/src/vom/byte_buffer_reader.part.dart';
part '../../lib/src/vom/low_level_vom_reader.part.dart';

void main() {
 group('Low Level Vom', () {
    for (var testCase in getTestCases()) {
      test('Writing ${testCase}', () {
        _ByteBufferWriter bbw = new _ByteBufferWriter();
        var llw = new _LowLevelVomWriter(bbw);
        for (var item in testCase.items) {
          item.write(llw);
        }
        expect(bbw.bytes,
          equals(test_util.hex2Bin(testCase.expectedHexData)));
      });

      test('Reading ${testCase}', () {
        _ByteBufferReader bbr = new _ByteBufferReader(
          test_util.hex2Bin(testCase.expectedHexData));
        var llr = new _LowLevelVomReader(bbr);
        for (var item in testCase.items) {
          item.readAndCheck(llr);
        }
      });
    }
    test('peekByte', () {
      _ByteBufferReader bbr = new _ByteBufferReader(test_util.hex2Bin('f8f7'));
      var llr = new _LowLevelVomReader(bbr);
      expect(llr.peekByte(), equals(0xf8));
      expect(llr.peekByte(), equals(0xf8));
      expect(llr.readByte(), equals(0xf8));
      expect(llr.peekByte(), equals(0xf7));
      expect(llr.readByte(), equals(0xf7));
      expect(() => llr.readByte(), throws);
    });
    test('tryReadControlByte', () {
      _ByteBufferReader bbr = new _ByteBufferReader(test_util.hex2Bin('95f8'));
      var llr = new _LowLevelVomReader(bbr);
      expect(llr.peekByte(), equals(0x95));
      expect(llr.tryReadControlByte(), equals(0x95));
      expect(llr.peekByte(), equals(0xf8));
      expect(llr.tryReadControlByte(), isNull);
      expect(llr.peekByte(), equals(0xf8));
    });
  });
}

List<_LowLevelVomTest> getTestCases() {
  return <_LowLevelVomTest>[
    new _LowLevelVomTest([new _BoolDataItem(false)], '00'),
    new _LowLevelVomTest([new _BoolDataItem(true)], '01'),

    new _LowLevelVomTest([new _ByteDataItem(0x80)], '80'),
    new _LowLevelVomTest([new _ByteDataItem(0xbf)], 'bf'),
    new _LowLevelVomTest([new _ByteDataItem(0xc0)], 'c0'),
    new _LowLevelVomTest([new _ByteDataItem(0xdf)], 'df'),
    new _LowLevelVomTest([new _ByteDataItem(0xe0)], 'e0'),
    new _LowLevelVomTest([new _ByteDataItem(0xef)], 'ef'),

    new _LowLevelVomTest([new _UintDataItem(0)], '00'),
    new _LowLevelVomTest([new _UintDataItem(1)], '01'),
    new _LowLevelVomTest([new _UintDataItem(2)], '02'),
    new _LowLevelVomTest([new _UintDataItem(127)], '7f'),
    new _LowLevelVomTest([new _UintDataItem(128)], 'ff80'),
    new _LowLevelVomTest([new _UintDataItem(255)], 'ffff'),
    new _LowLevelVomTest([new _UintDataItem(256)], 'fe0100'),
    new _LowLevelVomTest([new _UintDataItem(257)], 'fe0101'),
    new _LowLevelVomTest([new _UintDataItem(0xffff)], 'feffff'),
    new _LowLevelVomTest([new _UintDataItem(0xffffff)], 'fdffffff'),
    new _LowLevelVomTest([new _UintDataItem(0xffffffff)], 'fcffffffff'),
    new _LowLevelVomTest([new _UintDataItem(0xffffffffff)], 'fbffffffffff'),
    new _LowLevelVomTest([new _UintDataItem(0xffffffffffff)], 'faffffffffffff'),
    new _LowLevelVomTest([new _UintDataItem(0xffffffffffffff)], 'f9ffffffffffffff'),
    new _LowLevelVomTest([new _UintDataItem(0xffffffffffffffff)], 'f8ffffffffffffffff'),

    new _LowLevelVomTest([new _IntDataItem(0)], '00'),
    new _LowLevelVomTest([new _IntDataItem(1)], '02'),
    new _LowLevelVomTest([new _IntDataItem(2)], '04'),
    new _LowLevelVomTest([new _IntDataItem(63)], '7e'),
    new _LowLevelVomTest([new _IntDataItem(64)], 'ff80'),
    new _LowLevelVomTest([new _IntDataItem(65)], 'ff82'),
    new _LowLevelVomTest([new _IntDataItem(127)], 'fffe'),
    new _LowLevelVomTest([new _IntDataItem(128)], 'fe0100'),
    new _LowLevelVomTest([new _IntDataItem(129)], 'fe0102'),
    new _LowLevelVomTest([new _IntDataItem(0x7fff)], 'fefffe'),
    new _LowLevelVomTest([new _IntDataItem(0x7fffffff)], 'fcfffffffe'),
    new _LowLevelVomTest([new _IntDataItem(0x7fffffffffffffff)], 'f8fffffffffffffffe'),

    new _LowLevelVomTest([new _IntDataItem(-1)], '01'),
    new _LowLevelVomTest([new _IntDataItem(-2)], '03'),
    new _LowLevelVomTest([new _IntDataItem(-64)], '7f'),
    new _LowLevelVomTest([new _IntDataItem(-65)], 'ff81'),
    new _LowLevelVomTest([new _IntDataItem(-66)], 'ff83'),
    new _LowLevelVomTest([new _IntDataItem(-128)], 'ffff'),
    new _LowLevelVomTest([new _IntDataItem(-129)], 'fe0101'),
    new _LowLevelVomTest([new _IntDataItem(-130)], 'fe0103'),
    new _LowLevelVomTest([new _IntDataItem(-0x8000)], 'feffff'),
    new _LowLevelVomTest([new _IntDataItem(-0x80000000)], 'fcffffffff'),
    new _LowLevelVomTest([new _IntDataItem(-0x8000000000000000)], 'f8ffffffffffffffff'),

    new _LowLevelVomTest([new _FloatDataItem(0.0)], '00'),
    new _LowLevelVomTest([new _FloatDataItem(1.0)], 'fef03f'),
    new _LowLevelVomTest([new _FloatDataItem(17.0)], 'fe3140'),
    new _LowLevelVomTest([new _FloatDataItem(18.0)], 'fe3240'),

    new _LowLevelVomTest([new _StringDataItem('')], '00'),
    new _LowLevelVomTest([new _StringDataItem('abc')], '03616263'),
    new _LowLevelVomTest([new _StringDataItem('defghi')], '06646566676869'),
    new _LowLevelVomTest([new _StringDataItem('12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678')], 'ff803132333435363738393031323334353637383930313233343536373839303132333435363738393031323334353637383930313233343536373839303132333435363738393031323334353637383930313233343536373839303132333435363738393031323334353637383930313233343536373839303132333435363738'),

    new _LowLevelVomTest([new _BytesDataItem([])], '00'),
    new _LowLevelVomTest([new _BytesDataItem([0x23, 0x45])], '022345'),
  ];
}

abstract class _DataItem {
  dynamic get item;
  void write(_LowLevelVomWriter v);
  void readAndCheck(_LowLevelVomReader v);
  String toString() => item.toString();
}
class _UintDataItem extends _DataItem {
  int item;
  _UintDataItem(this.item);
  void write(_LowLevelVomWriter v) {
    v.writeUint(item);
  }
  void readAndCheck(_LowLevelVomReader v) {
    expect(v.readUint(), equals(item));
  }
}
class _IntDataItem extends _DataItem {
  int item;
  _IntDataItem(this.item);
  void write(_LowLevelVomWriter v) {
    v.writeInt(item);
  }
  void readAndCheck(_LowLevelVomReader v) {
    expect(v.readInt(), equals(item));
  }
}
class _FloatDataItem extends _DataItem {
  double item;
  _FloatDataItem(this.item);
  void write(_LowLevelVomWriter v) {
    v.writeFloat(item);
  }
  void readAndCheck(_LowLevelVomReader v) {
    expect(v.readFloat(), equals(item));
  }
}
class _StringDataItem extends _DataItem {
  String item;
  _StringDataItem(this.item);
  void write(_LowLevelVomWriter v) {
    v.writeString(item);
  }
  void readAndCheck(_LowLevelVomReader v) {
    expect(v.readString(), equals(item));
  }
}
class _BoolDataItem extends _DataItem {
  bool item;
  _BoolDataItem(this.item);
  void write(_LowLevelVomWriter v) {
    v.writeBool(item);
  }
  void readAndCheck(_LowLevelVomReader v) {
    expect(v.readBool(), equals(item));
  }
}
class _ByteDataItem extends _DataItem {
  int item;
  _ByteDataItem(this.item);
  void write(_LowLevelVomWriter v) {
    v.writeByte(item);
  }
  void readAndCheck(_LowLevelVomReader v) {
    expect(v.readByte(), equals(item));
  }
}
class _BytesDataItem extends _DataItem {
  List<int> item;
  _BytesDataItem(this.item);
  void write(_LowLevelVomWriter v) {
    v.writeBytes(item);
  }
  void readAndCheck(_LowLevelVomReader v) {
    expect(v.readBytes(), equals(item));
  }
}

class _LowLevelVomTest{
  List<_DataItem> items;
  String expectedHexData;
  Type expectedException;

  _LowLevelVomTest(this.items, this.expectedHexData, [this.expectedException]);

  String toString() {
    return 'items: ${items}';
  }
}