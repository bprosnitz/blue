part of vtrace;

context.Context withNewTrace(context.Context ctx) {
  var store = _getVtraceStore(ctx);
  var traceId = randomUniqueId();
  return withVtraceSpan(ctx, _createSpan(traceId, '', traceId, store));
}

Span _createSpan(UniqueId parent, String name, UniqueId trace, VtraceStore store) {
  var spanId = randomUniqueId();
  return new Span._constructor(name, spanId, parent, trace, store);
}

context.Context withNewSpan(context.Context ctx, String name) {
  var parent = getVtraceSpan(ctx);
  return withVtraceSpan(ctx, _createSpan(parent.id, name, parent.traceId,
        parent._store));
}
