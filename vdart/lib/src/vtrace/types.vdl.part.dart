part of vtrace;

// TODO(bjornick): Remove this when vdl compiler generates this
// method.
class Annotation {
  String message;

  DateTime when;

  Annotation(this.message, this.when);
}

class SpanRecord {
  UniqueId id;
  UniqueId parent;
  String name;
  DateTime start;
  DateTime end;
  List<Annotation> annotations;

  SpanRecord(this.id, this.parent, this.name, this.start, this.end, [this.annotations = null]);
}

class TraceRecord {
  UniqueId id;
  List<SpanRecord> spans;

  TraceRecord(this.id, this.spans);
}

