part of uniqueid;

var uuid = new Uuid();

UniqueId randomUniqueId() {
  var buffer = new Uint8List(16);
  uuid.v4(buffer: buffer);
  return new UniqueId(buffer);
}
