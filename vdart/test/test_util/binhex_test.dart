library test_util;

import 'package:test/test.dart';

import 'dart:core';
import 'dart:typed_data';

part 'binhex.part.dart';

void main() {
  for (var testCase in getTestCases()) {
    if (testCase.expectHex2BinException) {
      group('hex2Bin invalid', () {
        test('converting from ${testCase.hex}', () {
          expect(() => hex2Bin(testCase.hex), throws);
        });
      });
    } else if (testCase.expectBin2HexException){
      group('bin2Hex invalid', () {
        test('converting from ${testCase.hex}', () {
          expect(() => hex2Bin(testCase.hex), throws);
        });
      });
    } else {
      group('hex2Bin valid', () {
        test('converting from ${testCase.hex}', () {
          expect(hex2Bin(testCase.hex), equals(testCase.binary));
        });
      });
      group('bin2Hex valid', () {
        test('converting from ${testCase.hex}', () {
          expect(bin2Hex(testCase.binary), equals(testCase.hex));
        });
      });
    }
  }
}

List<BinHexTestCase> getTestCases() {
  return [
    new BinHexTestCase('', [], false, false),
    new BinHexTestCase('00', [0x00], false, false),
    new BinHexTestCase('01', [0x01], false, false),
    new BinHexTestCase('10', [0x10], false, false),
    new BinHexTestCase('0c', [0x0c], false, false),
    new BinHexTestCase('c0', [0xc0], false, false),
    new BinHexTestCase('0000', [0x00, 0x00], false, false),
    new BinHexTestCase('1234567890abcdef',
      [0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xef], false, false),
    new BinHexTestCase('q0', null, false, true),
    new BinHexTestCase('0r', null, false, true),
    new BinHexTestCase('000', null, false, true),
    new BinHexTestCase(null, [-1], true, false),
  ];
}

class BinHexTestCase {
  final String hex;
  final List<int> binary;
  final bool expectBin2HexException;
  final bool expectHex2BinException;

  BinHexTestCase(this.hex, this.binary,
    this.expectBin2HexException, this.expectHex2BinException);
}