part of test_util;

// Convert a hex string to binary.
List<int> hex2Bin(String hexStr) {
  if (hexStr.length % 2 != 0) {
    throw new Exception('invalid odd length hex string passed to hex2bin');
  }
  var bin = new Uint8List(hexStr.length ~/ 2);
  for (var i = 0; i < hexStr.length ~/ 2; i ++) {
    var doubleIndex = 2*i;
    bin[i] = int.parse(hexStr.substring(doubleIndex, doubleIndex+2), radix: 16);
  }
  return bin;
}

// Convert binary data to a hex string.
String bin2Hex(List<int> bin) {
  var strBuf = new StringBuffer();
  for (int byte in bin) {
    strBuf.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return strBuf.toString();
}