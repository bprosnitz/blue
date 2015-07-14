part of vom;

abstract class _Reader {
  List<int> read(int len);
  int readByte();
}

// TODO(bprosnitz) Is a streaming version of this with the same interface needed?
// Reader that reads from a byte buffer.
class _ByteBufferReader implements _Reader {
  List<int> _data;
  int _pos;

  _ByteBufferReader(List<int> data) :
    _data = data,
    _pos = 0;

  List<int> read(int size) {
    if (size < 0) {
      throw const LowLevelVomDecodeException('Invalid negative read size');
    }
    int begin = getMarker();
    int end = begin + size;
    setMarker(end);
    return _data.sublist(begin, end);
  }
  int readByte() {
    var mark = getMarker();
    setMarker(mark + 1);
    return _data[mark];
  }

  int getMarker() => _pos;
  void setMarker(int pos) {
    if (pos < 0) {
      throw const LowLevelVomDecodeException(
        'invalid negative position set for marker');
    }
    if (pos > _data.length) {
      throw new LowLevelVomDecodeException(
        'marker out of bounds of buffered data ' +
        '(new marker: ${pos}, current marker: ${_pos}, length: ${_data.length})');
    }
    _pos = pos;
  }
}