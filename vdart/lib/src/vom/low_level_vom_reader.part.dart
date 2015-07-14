part of vom;

// Reads low level VOM primitives from a reader.
class _LowLevelVomReader {
  _Reader _reader;

  _LowLevelVomReader(this._reader);
  int readByte() {
    return _reader.readByte();
  }
  List<int> readBytes() {
    int len = readUint();
    return _reader.read(len);
  }
  int readUint() {
    int first = _reader.readByte();
    if (first <= 0x7f) {
      return first;
    }
    // 0xff corresponds to 1 byte, 0xfe for 2, etc
    int numBytes = 0x100 - first;
    if (numBytes > 8 || numBytes < 1) {
      throw const LowLevelVomDecodeException(
        'corrupt input stream: invalid byte count while reading vom uint');
    }
    // read the actual uint value
    var valBytes = _reader.read(numBytes);
    var fullBuf = new Uint8List(8);
    fullBuf.setAll(fullBuf.length - valBytes.length, valBytes);
    var view = new ByteData.view(fullBuf.buffer);
    return view.getUint64(0);
  }
  int readInt() {
    int uintVal = readUint();
    if (uintVal & 0x01 == 1) {
      // odd value
      return ~(uintVal >> 1);
    } else {
      return uintVal >> 1;
    }
  }
  double readFloat() {
    var floatBytes = new Uint8List(8);
    var bdata = new ByteData.view(floatBytes.buffer);
    bdata.setUint64(0, readUint(), Endianness.LITTLE_ENDIAN);
    return bdata.getFloat64(0);
  }
  String readString() {
    List<int> strBytes = readBytes();
    var dec = new Utf8Decoder();
    return dec.convert(strBytes);
  }
  bool readBool() {
    int byteVal = readByte();
    switch(byteVal) {
      case 0:
        return false;
      case 1:
        return true;
      default:
        throw new LowLevelVomDecodeException(
          'corrupt input stream: byte value does not correspond to bool: ${byteVal}');
    }
  }
}