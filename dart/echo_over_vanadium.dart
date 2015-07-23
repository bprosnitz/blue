// Copyright 2015 The Chromium Authors.
// All rights reserved.  Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async' show Future;
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:sky/mojo/embedder.dart' show embedder;
import 'package:sky/widgets/basic.dart' as sky;
import 'package:sky/widgets/raised_button.dart' show RaisedButton;

import 'package:vanadium/mojom/lib/mojo/vanadium.mojom.dart' as v23;

// TODO(nlacasse): Delivering a .mojo resource via http is currently broken
// due to caching.  Once it is fixed, uncomment the following line and get
// rid of the "file://" url lines below it and the 'dart:io' import.
// See https://github.com/domokit/mojo/issues/286

// String echoClientUrl = 'http://localhost:9998/vanadium/gen/mojo/vanadium_echo_client.mojo';
final String mojoDir = Platform.environment['MOJO_DIR'];
final String echoClientUrl = 'file://' + mojoDir + '/src/vanadium/gen/mojo/vanadium_echo_client.mojo';

var rng = new math.Random();

String getName() {
  String name = '';
  for (var i = 0; i < 5; i++) {
    var num = rng.nextInt(26);
    name += new String.fromCharCode(num + 'a'.codeUnitAt(0));
  }
  return name;
}

class VanadiumEchoApp extends sky.App {
  bool connected = false;
  String sentMessage = '';
  String gotMessage = '';

  final v23.VanadiumClientProxy _vclient = new v23.VanadiumClientProxy.unbound();

  void _connect() {
    if (connected) return;
    embedder.connectToService(echoClientUrl, _vclient);

    connected = true;
  }

  Future<bool> doEcho() async {
    print('click!');
    _connect();
    String msg = 'Hello ' + getName();
    setState(() {
      sentMessage = msg;
      print('Sending message $sentMessage');
    });
    try {
      final v23.VanadiumClientEchoOverVanadiumResponseParams result = await _vclient.ptr.echoOverVanadium(msg);
      setState(() {
        gotMessage = result.value;
        print('Got message $gotMessage');
      });
    } catch(e) {
      print('Error echoing: ' + e.toString());
      return false;
    }
    return true;
  }

  Future close({bool immediate: false}) async {
    await _vclient.close(immediate: immediate);
    return;
  }

  sky.Widget build() {
    return new sky.Container(
      decoration: const sky.BoxDecoration(
        backgroundColor: const sky.Color(0xFF00ACC1)
      ),
      child: new sky.Flex([
        new RaisedButton(
          child: new sky.Text('CLICK ME'),
          onPressed: doEcho
        ),
        new sky.Text('Sent message $sentMessage'),
        new sky.Text('Got message $gotMessage')
      ],
      direction: sky.FlexDirection.vertical)
    );
  }
}

void main() {
  sky.runApp(new VanadiumEchoApp());
}
