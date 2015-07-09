// Copyright 2015 The Chromium Authors.
// All rights reserved.  Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../echo_over_vanadium.dart' show VanadiumEchoApp;

// TODO(nlacasse): These tests currently only run in mojo_shell, which prints
// all successes and errors, but mojo_shell does not exit when the tests are
// done.  We should make mojo_shell exit with non-zero status if any of the
// tests did not pass.

main() async {
  VanadiumEchoApp app = new VanadiumEchoApp();

  test('app should not be connected at first', () {
    expect(app.connected, equals(false));
  });

  test('doEcho should return true', () {
    expect(app.doEcho(), completion(equals(true)));
  });

  test('after echo, app should be connected', () {
    expect(app.connected, equals(true));
  });

  test('after echo, sentMessage should equal gotMessage', () async {
    expect(app.sentMessage, equals(app.gotMessage));
  });
}
