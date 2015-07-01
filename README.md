# blue

An experimental repo for vanadium/sky/mojo integration work.

## Setup:

https://docs.google.com/document/d/1h9LJEFE4PGnDrCJgcYGuLT9nZ-pR1uCPIbZEX0nGqOs/edit#

The rest of this document assumes that `MOJO_DIR` is set.

## Building Mojo Dependencies:

This will cd to $MOJO_DIR, fetch and sync any new changes, and rebuild the mojo
world.

Warning: This can time a long time.  Plan to get a cup of coffee.

Build mojo dependencies for linux:

    make mojo_update

Build mojo dependencies for android:

    ANDROID=1 make mojo_upate

## Vanadium Mojo Echo App:

This app consists of a client and server, which communicate over Vanadium RPC.

The main app loads the client, which will request the server by its mojo url
(`mojo:vanadium_echo_server`), which will cause mojo to start the server. *You
do not need to run the server yourself.*

Build the .mojo files.

    make mojo-app

    # For android:
    # ANDROID=1 make mojo-app

On android, ignore any warnings about "Cortex-A8 erratum".

Run the app the easy way.  This will also build mojo-app if it is not
already built.

    make run-mojo-app

    # For android:
    # ANDROID=1 make run-mojo-app

Or, run the client the hard way by calling `mojo_shell.py` directly.

    ${MOJO_DIR}/src/mojo/tools/mojo_shell.py --enable-multiprocess mojo:vanadium_echo_client # --android

NOTE: `--enable-multiprocess is crucial` -- without this flag the behavior will
appear racy and complete early at different points.

When running on linux, you should see a bunch of messages on the console, and
hopefully no errors.  Look for `ves: ok true connection closed true` to make
sure everything is working.

On android, you will see some messages in the console, but not the ones from
the vanadium client and server.  To see those, run `adb logcat`.

## Vanadium Sky App:

The sky app is a simple sky app (written in Dart) that loads the
vanadium_echo_client by its mojo: url, which then loads the server.  The echo
client and server are exactly the same as in the mojo app.

Build everything:

    make sky-app

    # For android:
    # ANDROID=1 make sky-app

Run the sky app the easy way.  This will also build the app if it is not
already built.

    make run-mojo-app

    # Android is currently unsupported.
    # See https://github.com/domokit/mojo/issues/255

Or, run the sky app the hard way by calling `mojo_shell.py` directly.

    ${MOJO_DIR}/src/mojo/tools/mojo_shell.py --enable-multiprocess --sky vanadium/echo_over_vanadium.dart

### Debugging

Running the sky app (either with `make run-sky-app` or with `mojo_shell.py`)
will start an [Observatory](https://www.dartlang.org/tools/observatory/) server
on http://localhost:8181.  This can be used to profile and debug the Dart code.

There is also a "Sky Debugger" at http://localhost:7777, but it's currently
limited to loading and reloading sky apps.
