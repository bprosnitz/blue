part of vom;


class VomMessage {
  final vdl.VdlType type;
  final List<int> bytes;

  VomMessage._(this.type, this.bytes);
}

class VomValueMessage extends VomMessage {
  VomValueMessage(vdl.VdlType type, List<int> bytes) : super._(type, bytes);

  String toString() => 'vom value message of type ${type} and length ${bytes.length}';
}
class VomTypeMessage extends VomMessage {
  VomTypeMessage(vdl.VdlType type, List<int> bytes) : super._(type, bytes);

  String toString() => 'vom type message of type ${type} and length ${bytes.length}';
}