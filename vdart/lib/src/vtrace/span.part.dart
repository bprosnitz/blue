part of vtrace;


class Span {
  final String name;
  final UniqueId id;
  final UniqueId parentId;
  final UniqueId traceId;
  VtraceStore _store;

  DateTime start;
  Span._constructor(this.name, this.id, this.parentId, this.traceId,
                    this._store) : start = new DateTime.now() {
    _store._start(this);
  }
  void annotate(String s) {
    _store._annotate(this, s);
  }

  void finish() {
    _store._finish(this);
  }
}
