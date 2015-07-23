library vtrace;

import 'package:test/test.dart';

import '../../lib/src/vtrace/vtrace.dart';

void main() {
  group('collecting trace', () {
    var createStoreWithSingleTrace = (String pattern, [double sampleRate=0.0]){
      var store = new VtraceStore(sampleRate, 10);
      if (pattern != null) {
        store.collectMatching(pattern);
      }
      var manager = new Manager();
      var trace = manager.createTrace(store);
      var span = manager.createSpan(trace, 'foo');
      span.annotate('bar');
      span.annotate('baz');
      span.finish();
      return store;
    };
    test('trace is not collected if no pattern is set', () {
      var store = createStoreWithSingleTrace(null);
      expect(store.traceRecords, equals([]));
    });

    test('trace is not collected if pattern does not match', () {
      var store = createStoreWithSingleTrace('nonmatchingpattern');
      expect(store.traceRecords, equals([]));
    });

    test('trace is collected if the sample rate is 1.0', () {
      var store = createStoreWithSingleTrace(null, 1.0);
      var records = store.traceRecords;
      expect(records.length, equals(1));
      // There are two spans.  The root span whose name is '' and the
      // explicitly created span with the name 'foo'.
      expect(records[0].spans.length, equals(2));
      // find the 'foo' span
      var span = records[0].spans.firstWhere((s) => s.name == 'foo');
      expect(span.name, equals('foo'));
      expect(span.start, isNotNull);
      expect(span.end, isNotNull);
      expect(span.annotations.length, equals(2));
      expect(span.annotations[0].message, equals('bar'));
      expect(span.annotations[1].message, equals('baz'));
    });

    test('trace is collected if the pattern is matched by name', () {
      var store = createStoreWithSingleTrace('foo');
      var records = store.traceRecords;
      expect(records.length, equals(1));
      expect(records[0].spans.length, equals(1));
      var span = records[0].spans[0];
      expect(span.name, equals('foo'));
      expect(span.start, isNotNull);
      expect(span.end, isNotNull);
      expect(span.annotations.length, equals(2));
      expect(span.annotations[0].message, equals('bar'));
      expect(span.annotations[1].message, equals('baz'));
    });

    test('trace is collected if the pattern is matched by annotation', () {
      var store = createStoreWithSingleTrace('b.*');
      var records = store.traceRecords;
      expect(records.length, equals(1));
      expect(records[0].spans.length, equals(1));
      var span = records[0].spans[0];
      expect(span.name, equals('foo'));
      expect(span.start, isNotNull);
      expect(span.end, isNotNull);
      expect(span.annotations.length, equals(2));
      expect(span.annotations[0].message, equals('bar'));
      expect(span.annotations[1].message, equals('baz'));
    });

    test('trace is partially collected if a later annotation is matched', () {
      var store = createStoreWithSingleTrace('z');
      var records = store.traceRecords;
      expect(records.length, equals(1));
      expect(records[0].spans.length, equals(1));
      var span = records[0].spans[0];
      expect(span.name, equals('foo'));
      expect(span.start, isNotNull);
      expect(span.end, isNotNull);
      expect(span.annotations.length, equals(1));
      expect(span.annotations[0].message, equals('baz'));
    });

    test('[] produces right result', () {
      var store = new VtraceStore(1.0, 10);
      var manager = new Manager();
      var trace = manager.createTrace(store);
      var span = manager.createSpan(trace, 'foo');
      span.annotate('bar');
      span.annotate('baz');
      span.finish();
      var record = store[trace.traceId];
      expect(record.id, equals(span.traceId));
      // There are two spans.  The root span whose name is '' and the
      // explicitly created span with the name 'foo'.
      expect(record.spans.length, equals(2));
      // find the 'foo' span.
      var resSpan = record.spans.firstWhere((s) => s.name == 'foo');
      expect(resSpan.name, equals('foo'));
      expect(resSpan.start, isNotNull);
      expect(resSpan.end, isNotNull);
      expect(resSpan.annotations.length, equals(2));
      expect(resSpan.annotations[0].message, equals('bar'));
      expect(resSpan.annotations[1].message, equals('baz'));
    });
  });

  }
