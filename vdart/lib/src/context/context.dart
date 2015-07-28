library context;

import 'dart:async';
import 'dart:core';
import 'dart:collection';

// TODO(nlacasse): Make this a verror once we have them.
class CancelledException implements Exception {
  String toString() => 'context cancelled';
}

// TODO(nlacasse): Make this a verror once we have them.
class DeadlineExceededException implements Exception {
  String toString() => 'context deadline exceeded';
}

class ContextKey {}

// Derive a new context from ctx with the given key and value associated.
Context withValue(Context ctx, ContextKey key, dynamic value) {
  return new _ValueContext(ctx, key, value);
}

// Derive a new context from ctx with the ability to be cancelled.
Context withCancel(Context ctx) {
  return new _CancelContext(ctx);
}

// Derive a new context from ctx with the given deadline.
Context withDeadline(Context ctx, DateTime deadline) {
  return new _DeadlineContext(ctx, deadline);
}

// Derive a new context from ctx with the given timeout.
Context withTimeout(Context ctx, Duration timeout) {
  DateTime deadline = (new DateTime.now()).add(timeout);
  return new _DeadlineContext(ctx, deadline);
}

abstract class Context {
  DateTime get deadline;
  // Future that will be completed when the Context finishes or is cancelled.
  // In the event of a cancellation or deadline expiration, this will have a
  // CancelledException or DeadlineExceededException, respectively.
  Future get done;
  // Cancel the context.  Causes all downstream contexts to be cancelled.
  // Causes 'done' to hold a CancellationError.
  void cancel();
  // Finish the context.  No errors will be triggered.
  void finish();
  dynamic operator[](ContextKey key);

}

// TODO(nlacasse): We probably don't want to expose this, but it's useful for
// unit tests.
class RootContext implements Context {
  DateTime get deadline => null;
  // RootContext.done will never complete.
  final Future done = (new Completer()).future;

  // TODO(nlacasse): Consider cancelling the root context when v23 runtime
  // shutdown happens, as the Go API does.
  void cancel(){
    throw new UnsupportedError('cannot cancel root context');
  }
  void finish(){
    throw new UnsupportedError('cannot finish root context');
  }
  dynamic operator[](ContextKey key) => null;
}

class _ChildContext implements Context {
  Context _parent;
  _ChildContext(Context this._parent) : super();

  DateTime get deadline => _parent.deadline;
  Future get done => _parent.done;
  void cancel() => _parent.cancel();
  void finish() => _parent.finish();
  dynamic operator[](ContextKey key) => _parent[key];
}

class _ValueContext extends _ChildContext {
  final ContextKey _key;
  final dynamic _value;
  _ValueContext(Context parent, ContextKey this._key, dynamic this._value) : super(parent);

  dynamic operator[](ContextKey key) {
    if (key == _key) return _value;
    return super[key];
  }
}

_CancelContext _cancelableAncestor(Context c) {
  while (c is _ChildContext) {
    if (c is _CancelContext) return c;
    c = (c as _ChildContext)._parent;
  }
  return null;
}

class _CancelContext extends _ChildContext {
  ContextKey _key;
  HashMap<ContextKey, _ChildContext> _children;
  Completer<bool> _done = new Completer();
  Future get done => _done.future;

  _CancelContext(Context parent) : super(parent) {
    _children = new HashMap<ContextKey, _ChildContext>();
    _key = new ContextKey();
    _CancelContext ca = _cancelableAncestor(parent);
    if (ca != null) ca._children[_key] = this;
  }

  void _cancel(Exception e) {
    if (e == null) {
      _done.complete(true);
    } else {
      _done.completeError(e);
    }

    _children.forEach((_, _ChildContext child) {
      if (child is _CancelContext) child._cancel(e);
    });
  }

  void cancel() {
    _CancelContext ca = _cancelableAncestor(_parent);
    if (ca != null) ca._children.remove(_key);
    _cancel(new CancelledException());
  }

  void finish() {
    _cancel(null);
  }
}

class _DeadlineContext extends _CancelContext {
  DateTime _deadline;
  Timer _timer;

  _DeadlineContext(Context parent, DateTime this._deadline) : super(parent) {
    Duration timeout = _deadline.difference(new DateTime.now());
    _timer = new Timer(timeout, _expire);
  }

  void _cancel(Exception e) {
    _timer.cancel();
    super._cancel(e);
  }

  void _expire() {
    _cancel(new DeadlineExceededException());
  }
}
