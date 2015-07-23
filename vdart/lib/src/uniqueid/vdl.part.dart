part of uniqueid;

class UniqueId {
  Uint8List val;
  UniqueId(this.val);

  bool operator==(dynamic other) => (other is UniqueId) && val == other.val;

  int get hashCode => this.val.hashCode;
}
