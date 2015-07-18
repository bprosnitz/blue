import 'dart:async';

import 'package:test/test.dart';
import 'package:test/src/backend/invoker.dart' show Invoker;

import '../../lib/src/context/context.dart';

Matcher throwsCancelledException = throwsA(
    new isInstanceOf<CancelledException>());

Matcher throwsDeadlineExceededException = throwsA(
    new isInstanceOf<DeadlineExceededException>());

// Assert that a future is not resolved.
// This matcher creates a new future from the given one with a 1ms timeout, and
// verifies that that future does indeed time out as expected.
//
// TODO(nlacasse): I would like to write this matcher without depending on the
// test invoker package, but I can't figure out how to do it.  Why doesn't
// "isNot(completes)" do what I want?
Matcher isNotCompleted = predicate((f) {
  if (f is! Future) return false;

  Invoker.current.addOutstandingCallback();

  Duration d = new Duration(milliseconds: 1);
  Future ff = f.timeout(d);

  ff.then((val) {
    fail('future resolved to ' + val.toString());
  }, onError: (err) {
    if (err is! TimeoutException) fail('future did not time out as expected.');
  }).whenComplete(() {
    Invoker.current.removeOutstandingCallback();
  });

  return true;
});

void main() {
  test('context key', () {
    ContextKey ck1 = new ContextKey();
    ContextKey ck2 = new ContextKey();
    expect(ck1, isNot(equals(ck2)));
  });

  test('root context', () {
    Context rootCtx = new RootContext();
    expect(rootCtx.deadline, isNull);
    expect(rootCtx.done, isNotCompleted);
  });

  test('ValueContext with own value', () {
    Context rootCtx = new RootContext();
    ContextKey key1 = new ContextKey();
    ContextKey key2 = new ContextKey();
    String val1 = 'foo';
    String val2 = 'bar';

    Context vctx1 = withValue(rootCtx, key1, val1);
    Context vctx2 = withValue(vctx1, key2, val2);

    expect(vctx1[key1], equals(val1));
    expect(vctx2[key2], equals(val2));
  });

  test('ValueContext with parent value', () {
    Context rootCtx = new RootContext();
    ContextKey key1 = new ContextKey();
    ContextKey key2 = new ContextKey();
    String val1 = 'foo';
    String val2 = 'bar';

    Context vctx1 = withValue(rootCtx, key1, val1);
    Context vctx2 = withValue(vctx1, key2, val2);

    expect(vctx1[key2], isNull);
    expect(vctx2[key1], equals(val1));
  });

  test('CancelContext with parent value', () {
    Context rootCtx = new RootContext();
    ContextKey key = new ContextKey();
    String val = 'foo';

    Context ctx1 = withValue(rootCtx, key, val);
    Context ctx2 = withCancel(ctx1);

    expect(ctx1[key], equals(val));
    expect(ctx2[key], equals(val));
  });

  test('CancelContext.cancel', () {
    Context rootCtx = new RootContext();
    Context cctx = withCancel(rootCtx);

    cctx.cancel();

    expect(cctx.done, throwsCancelledException);
  });

  test('CancelContext.finish', () {
    Context rootCtx = new RootContext();
    Context cctx = withCancel(rootCtx);

    cctx.finish();

    expect(cctx.done, completion(equals(true)));
  });

  test('CancelContext parent cancellation', () {
    Context rootCtx = new RootContext();
    Context cctx1 = withCancel(rootCtx);
    Context cctx2 = withCancel(cctx1);

    cctx1.cancel();

    expect(cctx1.done, throwsCancelledException);
    expect(cctx2.done, throwsCancelledException);
  });

  test('CancelContext ancestor cancellation', () {
    Context rootCtx = new RootContext();
    Context cctx1 = withCancel(rootCtx);
    Context vctx = withValue(cctx1, new ContextKey(), 'value');
    Context cctx2 = withCancel(vctx);

    cctx1.cancel();

    expect(cctx1.done, throwsCancelledException);
    expect(cctx2.done, throwsCancelledException);
  });

  test('CancelContext descendant cancellation', () {
    Context rootCtx = new RootContext();
    Context cctx1 = withCancel(rootCtx);
    Context vctx = withValue(cctx1, new ContextKey(), 'value');
    Context cctx2 = withCancel(vctx);

    cctx2.cancel();

    expect(cctx1.done, isNotCompleted);
    expect(cctx2.done, throwsCancelledException);
  });

  test('DeadlineContext', () async {
    DateTime deadline = (new DateTime.now()).add(
        new Duration(milliseconds: 100));
    Context rootCtx = new RootContext();
    Context dctx = withDeadline(rootCtx, deadline);

    expect(dctx.done, throwsDeadlineExceededException);
  });

  test('TimeoutContext', () async {
    Duration timeout = new Duration(milliseconds: 100);
    Context rootCtx = new RootContext();
    Context tctx = withTimeout(rootCtx, timeout);

    expect(tctx.done, throwsDeadlineExceededException);
  });
}
