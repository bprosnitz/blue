part of vom;

class VomException implements Exception {
  final String _msg;
  const VomException(this._msg);
  String toString() => _msg;
}

// An exception that occurs during VOM decode.
class VomDecodeException extends VomException {
  const VomDecodeException(String msg) : super(msg);
}

// An exception that occurs during VOM encode.
class VomEncodeException extends VomException {
  const VomEncodeException(String msg) : super(msg);
}

// An exception occurs while performing low-level vom decoding (read uint etc).
class LowLevelVomDecodeException extends VomDecodeException {
  const LowLevelVomDecodeException(String msg) : super(msg);
}

// An exception occurs while performing low-level vom encoding (write uint etc).
class LowLevelVomEncodeException extends VomEncodeException {
  const LowLevelVomEncodeException(String msg) : super(msg);
}