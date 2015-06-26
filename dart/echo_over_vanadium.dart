// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// To run: mojo/tools/mojo_shell.py --sky \
//             examples/vanadium/sky_echo_over_vanadium.dart --android --enable-multiprocess

import 'dart:async';
import 'dart:sky';
import 'dart:math';

import 'package:sky/base/scheduler.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/flex.dart';
import 'package:sky/rendering/sky_binding.dart';

import 'package:sky/painting/text_style.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/flex.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/rendering/paragraph.dart';
import 'package:sky/rendering/sky_binding.dart';

import './solid_color_box.dart';
import 'package:mojom/mojo/examples/vanadium.mojom.dart';
import 'package:sky/framework/embedder.dart';

final VanadiumClientProxy vclient = new VanadiumClientProxy.unbound();
int photoIndex = 0;
bool loaded = false;
bool drawn = false;
SkyBinding binding;

draw(String txt) {
  var table = new RenderFlex(direction: FlexDirection.vertical);
  RenderParagraph paragraph = new RenderParagraph(new InlineText(txt));
  table.add(new RenderPadding(child: paragraph, padding: new EdgeDims.only(top: 20.0)));

  RenderDecoratedBox root = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: const Color(0xFFFFFFFF)),
    child: new RenderPadding(child: table, padding: new EdgeDims.symmetric(vertical: 50.0))
  );

  if (!drawn) {
    binding = new SkyBinding(root: root);
    view.setEventCallback(handleEvent);
    drawn = true;
  } else {
    binding.root = root;
  }
}

String getName() {
  String name = '';
  var rng = new Random();
  for (var i = 0; i < 5; i++) {
    var num = rng.nextInt(26);
    name += new String.fromCharCode(num + 'a'.codeUnitAt(0));
  }
  return name;
}

hello() async {
  if (!loaded) {
    embedder.connectToService("mojo:vanadium_echo_client", vclient);
    loaded = true;
  }
  print("done with connect call");
  try {
    final VanadiumClientEchoOverVanadiumResponseParams result = await vclient.ptr.echoOverVanadium("Hello " + getName());
    print('Result: ' + result.value);
    draw(result.value);
  } catch(e) {
    print('Error echoing: ' + e.toString());
  }
}

bool handleEvent(Event event) {
  print("Handle event!");
  if (event.type == "pointerdown") {
    hello();
    return true;
  }
  return true;
}

main() async {
  view.setEventCallback(handleEvent);
  //await hello();
}
