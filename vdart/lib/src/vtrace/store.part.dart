part of vtrace;

// Contains all the span information for one trace.
class TraceStore extends LinkedListEntry<TraceStore> {
  final UniqueId id;
  final Map<UniqueId, SpanRecord> spans;

  TraceStore(this.id) : spans = new Map<UniqueId, SpanRecord>();

  TraceRecord toTraceRecord() {
    return new TraceRecord(id, spans.values.toList());
  }

  void annotate(Span span, String message) {
    SpanRecord rec = track(span);
    if (rec.end != null) {
      throw new AnnotateAfterFinishError();
    }
    rec.annotations.add(new Annotation(message, new DateTime.now()));
  }

  // Returns the SpanRecord associated with this span.  If no SpanRecord
  // exists, a new one is created.
  SpanRecord track(Span span) {
    SpanRecord ret = spans[span.id];
    if (ret == null) {
      ret = new SpanRecord(span.id, span.parentId, span.name, span.start,null,
                           new List<Annotation>());
      spans[span.id] = ret;
    }
    return ret;
  }

  // Records the start of a span.
  void start(Span span) {
    track(span);
  }

  // Records the end of a span.
  void finish(Span span) {
    track(span).end = new DateTime.now();
  }

  // Moves this store to the front of the lru linked list
  // that it is a part of.
  void moveToFront() {
    LinkedList list = this.list;
    unlink();
    list.addFirst(this);
  }
}

class VtraceStore {
  // A map of trace ids to trace stores.  Only traces that
  // are being collected will appear in this map.
  final Map<UniqueId, TraceStore> _traceStores;


  // The regular expression pattern used to determine whether or
  // not a trace should be collected.  If null, then only trace ids
  // that are passed to forceCollect will be collected.
  RegExp _matcher;

  // A linked list of trace stores stored in order of recency.  Once
  // this list is greater than kMaxStoredTraces, the least recently used
  // trace is garbaged collected.
  final LinkedList _lru;

  double sampleRate;
  int maxStoredTraces;
  final Random _rand;

  VtraceStore(this.sampleRate, this.maxStoredTraces)
    : _traceStores = new Map<UniqueId, TraceStore>(),
      _lru = new LinkedList(),
      _rand = new Random();

  List<TraceRecord> get traceRecords =>
    (_traceStores.values.map((v) => v.toTraceRecord())).toList();

  TraceRecord operator[](UniqueId traceId) {
    TraceStore traceStore = this._traceStores[traceId];
    if (traceStore == null) {
      return null;
    }
    return traceStore.toTraceRecord();
  }

  TraceStore _forceCollect(UniqueId traceId) {
    if (!_traceStores.containsKey(traceId)) {
      TraceStore s = new TraceStore(traceId);
      _lru.addFirst(s);
      _traceStores[traceId] = s;
      if (_lru.length > maxStoredTraces) {
  TraceStore removed = _lru.last;
  removed.unlink();
  _traceStores.remove(removed.id);
      }
    }
    return _traceStores[traceId];
  }
  void forceCollect(UniqueId traceId) {
    _forceCollect(traceId);
  }

  void collectMatching(String pattern) {
    _matcher = new RegExp(pattern);
  }

  // Returns the pretty printed traces of all the traces stored.
  String get formattedRecords {
    StringBuffer buf = new StringBuffer();
    traceRecords.forEach((TraceRecord r) {
      Node n = new Node(r);
      n.format(buf, '', n.span.start);
    });
    return buf.toString();
  }

  // Returns the pretty printed trace for the given traceId.  If
  // the trace is not in the store the empty string is the result.
  String formatedRecordsFor(UniqueId traceId) {
    TraceRecord r = this[traceId];
    if (r == null) {
      return '';
    }
    StringBuffer buf = new StringBuffer();
    Node n = new Node(r);
    n.format(buf, '', n.span.start);
    return buf.toString();
  }

  // Add this annotation if the trace that this span is part of is being
  // collected.  If the message matches the collection regexp, then this
  // trace will be forced to be collected.
  void _annotate(Span span, String message) {
    TraceStore traceStore = _traceStores[span.traceId];
    if (traceStore == null && _matcher != null &&
  _matcher.hasMatch(message)) {
      traceStore = _forceCollect(span.traceId);
    }

    if (traceStore == null) {
      return;
    }
    traceStore.annotate(span, message);
    traceStore.moveToFront();
  }

  // Records the start of the span.  If the trace that this span is associated
  // with is being collected then, we tell the trace store about the sample.
  // If we decide to start collecting the trace, either because the span name
  // matches the collection pattern or because this the root span of a trace
  // and we decide to sample it, then we force collection on the trace and
  // record the start of the span.
  void _start(Span span) {
    TraceStore traceStore = _traceStores[span.traceId];
    if (traceStore == null) {
      if (span.parentId == span.traceId && sampleRate > 0.0 &&
          (sampleRate >= 1.0 || _rand.nextDouble() < sampleRate)) {
        traceStore = _forceCollect(span.traceId);
      } else if(_matcher != null && _matcher.hasMatch(span.name)) {
        traceStore = _forceCollect(span.traceId);
      }
    }

    if (traceStore == null) {
      return;
    }

    traceStore.start(span);
    traceStore.moveToFront();
  }

  // If the trace that is associated with this span is being collected, we record the finish of
  // the span.
  void _finish(Span span) {
    TraceStore traceStore = _traceStores[span.traceId];
    if (traceStore == null) {
      return null;
    }
    traceStore.finish(span);
  }
}
class AnnotateAfterFinishError extends Error {
  String toString() {
    return "Can't call annotate after the span has been finished";
  }
}
