library vtrace;

import 'dart:typed_data';
import 'package:test/test.dart';

import '../../lib/src/uniqueid/uniqueid.dart';
import '../../lib/src/vtrace/vtrace.dart';

int nextId = 1;

UniqueId id() {
  // Hopefully we don't need to create more than 250 spans.
  var id = new Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, nextId]);
  nextId++;
  return new UniqueId(id);
}

void main() {
  group('format', () {
    test('normal format', () {
      var traceId = id();
      var traceStart = new DateTime(2014, 11, 6, 13, 1, 22, 400);
      List<UniqueId> ids = new List<UniqueId>.from([id(), id(), id(), id()]);
      var annotations = new List<Annotation>.from([
          new Annotation('First Annotation', traceStart.add(new Duration(seconds: 4))),
          new Annotation('Second Annotation', traceStart.add(new Duration(seconds: 6))),
      ]);
      var spans = new List<SpanRecord>.from([
          new SpanRecord(ids[0], traceId, '', traceStart, null, null),
          new SpanRecord(ids[1], ids[0], 'Child1', traceStart.add(new Duration(seconds:1)),
            traceStart.add(new Duration(seconds: 10))),
          new SpanRecord(ids[2], ids[0], 'Child2', traceStart.add(new Duration(seconds:20)),
            traceStart.add(new Duration(seconds: 30))),
          new SpanRecord(ids[3], ids[1], 'GrandChild1', traceStart.add(new Duration(seconds:3)),
            traceStart.add(new Duration(seconds: 8)), annotations)
      ]);
      var trace = new TraceRecord(traceId, spans);
      var n = new Node(trace);
      var res = new StringBuffer();
      n.format(res, '', traceStart);
      var expected = '''
Trace - 0x00000000000000000000000000000001 (2014-11-06 13:01:22.400, ??)
    Span - Child1 [id: 00000003 parent 00000002] (1s, 10s)
        Span - GrandChild1 [id: 00000005 parent 00000003] (3s, 8s)
            @4s First Annotation
            @6s Second Annotation
    Span - Child2 [id: 00000004 parent 00000002] (20s, 30s)
''';
      expect(res.toString(), equals(expected));
    });

    test('missing data', () {
      var traceId = id();
      var traceStart = new DateTime(2014, 11, 6, 13, 1, 22, 400);
      List<UniqueId> ids = new List<UniqueId>.from([id(), id(), id(), id(), id(), id()]);
      var annotations = new List<Annotation>.from([
          new Annotation('First Annotation', traceStart.add(new Duration(seconds: 4))),
          new Annotation('Second Annotation', traceStart.add(new Duration(seconds: 6))),
      ]);
      var spans = new List<SpanRecord>.from([
          new SpanRecord(ids[0], traceId, '', traceStart, null, null),
          new SpanRecord(ids[1], ids[0], 'Child1', traceStart.add(new Duration(seconds:1)),
            traceStart.add(new Duration(seconds: 10))),
          new SpanRecord(ids[3], ids[2], 'Decendant2', traceStart.add(new Duration(seconds:15)),
            traceStart.add(new Duration(seconds: 24))),
          new SpanRecord(ids[4], ids[2], 'Decendant1', traceStart.add(new Duration(seconds:12)),
            traceStart.add(new Duration(seconds: 18))),
          new SpanRecord(ids[5], ids[1], 'GrandChild1', traceStart.add(new Duration(seconds:3)),
            traceStart.add(new Duration(seconds: 8)), annotations)
      ]);

      var trace = new TraceRecord(traceId, spans);
      var n = new Node(trace);
      var res = new StringBuffer();
      n.format(res, '', traceStart);
      var expected = '''
Trace - 0x00000000000000000000000000000006 (2014-11-06 13:01:22.400, ??)
    Span - Child1 [id: 00000008 parent 00000007] (1s, 10s)
        Span - GrandChild1 [id: 0000000c parent 00000008] (3s, 8s)
            @4s First Annotation
            @6s Second Annotation
    Span - Missing Data [id: 00000000 parent 00000000] (??, ??)
        Span - Decendant1 [id: 0000000b parent 00000009] (12s, 18s)
        Span - Decendant2 [id: 0000000a parent 00000009] (15s, 24s)
''';
      expect(res.toString(), equals(expected));
    });
  });
}
