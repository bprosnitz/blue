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

Build the .mojo files.

    make mojo-app

    # For android:
    # ANDROID=1 make mojo-app

On android, ignore any warnings about "Cortex-A8 erratum".

Copy .mojo files to the Mojo directory.

_TODO(nlacasse): We shouldn't need this step.  Figure out how to run Mojo apps
from different directory than Mojo itself._

    cp build/* ${MOJO_DIR}/src/out/Debug

    # For android:
    # cp build/* ${MOJO_DIR}/src/out/android_Debug

Run the client.  Use '--android' flag for android.

    ${MOJO_DIR}/src/mojo/tools/mojo_shell.py --enable-multiprocess mojo:vanadium_echo_client # --android

NOTE: `--enable-multiprocess is crucial` -- without this flag the behavior will
appear racy and complete early at different points.

When the client starts, it will request the server by its mojo url
(`mojo:vanadium_echo_server`), which will cause mojo to start the server. *You
do not need to run the server yourself.*

When running on linux, you should see a bunch of messages on the console, and
hopefully no errors.  Look for `ves: ok true connection closed true` to make
sure everything is working.

On android, you will see some messages in the console, but not the ones from
the vanadium client and server.  To see those, run `adb logcat`.

## Vanadium Sky App:

Build the .dart files.

    make sky-app

Copy dart app and assets to mojo dir.

    mkdir -p ${MOJO_DIR}/src/examples/vanadium
    cp dart/* ${MOJO_DIR}/src/examples/vanadium

Copy built mojo and mojom files to mojo dir.

    cp build/* ${MOJO_DIR}/src/out/Debug
    cp build/gen/dart-gen/mojom/lib/mojo/examples/vanadium.mojom.dart ${MOJO_DIR}/src/out/Debug/gen/dart-pkg/packages/mojom/mojo/examples

    # For android:
    # cp build/* ${MOJO_DIR}/src/out/android_Debug
    # cp build/gen/dart-gen/mojom/lib/mojo/examples/vanadium.mojom.dart ${MOJO_DIR}/src/out/android_Debug/gen/dart-pkg/packages/mojom/mojo/examples

Run the app.  Use `--android` flag for android.

    ${MOJO_DIR}/src/mojo/tools/mojo_shell.py --enable-multiprocess --sky examples/vanadium/echo_over_vanadium.dart # --android

NOTE: `--enable-multiprocess` is crucial -- without this flag the behavior will
appear racy and complete early at different points.
