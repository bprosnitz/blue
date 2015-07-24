part of vtrace;

context.ContextKey _spanKey = new context.ContextKey();

context.ContextKey _storeKey = new context.ContextKey();

VtraceStore _getVtraceStore(context.Context ctx) {
  return ctx[_storeKey] as VtraceStore;
}

Span getVtraceSpan(context.Context ctx) {
  return ctx[_spanKey] as Span;
}

context.Context withVtraceStore(context.Context ctx, VtraceStore store) {
  return context.withValue(ctx, _storeKey, store);
}

context.Context withVtraceSpan(context.Context ctx, Span span) {
  return context.withValue(ctx, _spanKey, span);
}
