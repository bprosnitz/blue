// Copyright 2015 The Chromium Authors. All rights reserved.  Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.


import 'dart:sky' as sky;
import 'dart:math' as math;

import 'package:sky/mojo/embedder.dart' show embedder;
import 'package:sky/rendering/box.dart' show BoxDecoration, EdgeDims, RenderDecoratedBox, RenderPadding;
import 'package:sky/rendering/flex.dart' show FlexDirection, RenderFlex;
import 'package:sky/rendering/object.dart' show Color;
import 'package:sky/rendering/paragraph.dart' show InlineText, RenderParagraph;
import 'package:sky/rendering/sky_binding.dart' show SkyBinding;

import 'package:vanadium/mojom/lib/mojo/vanadium.mojom.dart' as v23;

final v23.VanadiumClientProxy vclient = new v23.VanadiumClientProxy.unbound();
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
    sky.view.setEventCallback(handleEvent);
    drawn = true;
  } else {
    binding.root = root;
  }
}

String getName() {
  String name = '';
  var rng = new math.Random();
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
    final v23.VanadiumClientEchoOverVanadiumResponseParams result = await vclient.ptr.echoOverVanadium("Hello " + getName());
    print('Result: ' + result.value);
    draw(result.value);
  } catch(e) {
    print('Error echoing: ' + e.toString());
  }
}

bool handleEvent(sky.Event event) {
  if (event.type == "pointerdown") {
    hello();
    return true;
  }
  return true;
}

main() async {
  sky.view.setEventCallback(handleEvent);
}
