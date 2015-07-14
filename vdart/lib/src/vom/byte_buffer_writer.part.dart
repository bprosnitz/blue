part of vom;

abstract class _Writer {
  void write(List<int> bytes);
  void writeByte(int byte);
}

// Writer that writes to a byte buffer.
class _ByteBufferWriter implements _Writer {
  static const _INITIAL_SIZE = 256;

  Uint8List _buf;
  int _nextIndex;

  _ByteBufferWriter() :
    _buf = new Uint8List(_INITIAL_SIZE),
    _nextIndex = 0;

  void write(List<int> bytes) {
    _makeRoom(bytes.length);
    _buf.setAll(_nextIndex, bytes);
    _nextIndex += bytes.length;
  }
  void writeByte(int byte) {
    _makeRoom(1);
    _buf[_nextIndex] = byte;
    _nextIndex++;
  }

  void _makeRoom(int roomNeeded) {
    if (roomNeeded <= 0) {
      return;
    }

    var totalNeeded = _nextIndex + roomNeeded;
    var targetLength = _buf.length;
    while (targetLength < totalNeeded) {
      targetLength *= 2;
    }

    if (targetLength > _buf.length) {
      var newBuf = new Uint8List(targetLength);
      newBuf.setRange(0, _nextIndex, _buf);
      _buf = newBuf;
    }
  }

  // Note: data is not copied (should it be?)
  List<int> get bytes => _buf.sublist(0, _nextIndex);

  int getMarker() => _nextIndex;
  setMarker(int pos) {
    if (pos < 0) {
      throw const LowLevelVomEncodeException(
        'Invalid negative marker position specified');
    }

    _makeRoom(pos - _nextIndex);
    _nextIndex = pos;
  }

  int get allocatedSize => _buf.length;
}