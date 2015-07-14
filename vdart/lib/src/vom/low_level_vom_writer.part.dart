part of vom;

// Writes low level VOM primitives to a writer.
class _LowLevelVomWriter {
  _Writer _writer;

  _LowLevelVomWriter(this._writer);

  void writeByte(int value) {
    _writer.writeByte(value);
  }
  void writeBytes(List<int> value) {
    writeUint(value.length);
    _writer.write(value);
  }
  void writeUint(int value) {
    if (value < 0) {
      throw const LowLevelVomEncodeException(
        'low level vom writer given illegal negative uint value to write');
    }
    if (value <= 0x7f) {
      _writer.writeByte(value);
      return;
    };
    // convert bits to bytes needed (e.g. 11 bits -> 2 bytes)
    int byteLength = (value.bitLength + 7) ~/ 8;
    if (byteLength > 8) {
      throw const LowLevelVomEncodeException(
        'low level vom writer cannot encode uint value longer than 8 bytes');
    }
    // write 0xff for 1 byte, 0xfe for 2, etc
    _writer.writeByte(0x100-byteLength);
    // write the actual byte data for the unsigned integer
    var uintBytes = new Uint8List(8);
    var bdata = new ByteData.view(uintBytes.buffer);
    bdata.setUint64(0, value);
    _writer.write(uintBytes.sublist(8 - byteLength, 8));
  }
  void writeInt(int value) {
    if (value < 0) {
      writeUint(~value << 1 | 1);
    } else {
      writeUint(value << 1);
    }
  }
  void writeFloat(double value) {
    var floatBytes = new Uint8List(8);
    var bdata = new ByteData.view(floatBytes.buffer);
    bdata.setFloat64(0, value);
    writeUint(bdata.getUint64(0, Endianness.LITTLE_ENDIAN));
  }
  void writeString(String value) {
    var enc = new Utf8Encoder();
    writeBytes(enc.convert(value));
  }
  void writeBool(bool value) {
    if (value) {
      _writer.writeByte(1);
    } else {
      _writer.writeByte(0);
    }
  }
}