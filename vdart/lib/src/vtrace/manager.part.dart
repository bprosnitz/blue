part of vtrace;

// TODO(bjornick): After the manager Context is checked in, use Contexts here.
class Manager {
  Span createTrace(VtraceStore store) {
    var traceId = randomUniqueId();
    return _createSpan(traceId, '', traceId, store);
  }

  Span _createSpan(UniqueId parent, String name, UniqueId trace, VtraceStore store) {
    var spanId = randomUniqueId();
    return new Span._constructor(name, spanId, parent, trace, store);
  }

  Span createSpan(Span parent, String name) {
    return _createSpan(parent.id, name, parent.traceId, parent._store);
  }
}
