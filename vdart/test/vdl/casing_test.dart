library vdl;

import 'package:test/test.dart';

import 'dart:core';

part '../../lib/src/vdl/casing.part.dart';

void main() {
  test('conversion to upper camel case', () {
    expect(() => _toUpperCamelCase(null), throws);
    expect(_toUpperCamelCase(''), equals(''));
    expect(_toUpperCamelCase('abraCadabra'), equals('AbraCadabra'));
    expect(_toUpperCamelCase('a'), equals('A'));
    expect(_toUpperCamelCase('AbraCadabra'), equals('AbraCadabra'));
    expect(_toUpperCamelCase('78'), equals('78'));
    // The runes below are multi-byte.
    expect(_toUpperCamelCase('日本語'), equals('日本語'));
    expect(_toUpperCamelCase('a日本語'), equals('A日本語'));
  });
}