V23_GOPATH=$(shell echo `v23 run env | grep GOPATH | cut -d\= -f2`)
PWD=$(shell pwd)

ifndef MOJO_DIR
$(error MOJO_DIR is not set: ${MOJO_DIR})
endif

ifdef ANDROID
GO_BIN=$(MOJO_DIR)/src/third_party/go/tool/android_arm/bin/go
GO_FLAGS=-ldflags=-shared
MOJO_BUILD_DIR=$(MOJO_DIR)/src/out/android_Debug
MOJO_FLAGS=--android
MOJO_SHARED_LIB=$(PWD)/build/lib/android/libsystem_thunk.a
else
GO_BIN=$(MOJO_DIR)/src/third_party/go/tool/linux_amd64/bin/go
GO_FLAGS=-ldflags=-shared -buildmode=c-shared
MOJO_FLAGS=
MOJO_BUILD_DIR=$(MOJO_DIR)/src/out/Debug
MOJO_SHARED_LIB=$(PWD)/build/lib/linux_amd64/libsystem_thunk.a
endif

# Compiles a Go program and links against the Mojo C shared library.
# $1 is input filename.
# $2 is output filename.
# See $(MOJO_DIR)/mojo/go/go.py for description of arguments to go.py (aka MOGO_BIN).
#
# MOJO_GOPATH must be exported so it can be picked up by MOGO_BIN.
export MOJO_GOPATH=$(V23_GOPATH):$(PWD)/build/gen/go:$(PWD)/go:$(MOJO_BUILD_DIR)/gen/go
MOGO_BIN=$(MOJO_DIR)/src/mojo/go/go.py
define MOGO_BUILD
	mkdir -p $(dir $2)
	$(MOGO_BIN) $(MOJO_FLAGS) -- \
		$(GO_BIN) \
		$(shell mktemp -d) \
		$(PWD)/$(2) \
		$(MOJO_DIR)/src \
		$(PWD)/build \
		"-I$(MOJO_DIR)/src" \
		"-L$(dir $(MOJO_SHARED_LIB)) -lsystem_thunk" \
		build $(GO_FLAGS) $(PWD)/$1
endef

# Generates go bindings from .mojom file.
# $1 is input filename.
# $2 is output directory.
# $3 is language (go, dart, ...)
MOJOM_BIN=$(MOJO_DIR)/src/mojo/public/tools/bindings/mojom_bindings_generator.py
define MOJOM_GEN
	mkdir -p $2
	$(MOJOM_BIN) $1 -d ./ -o $2 -g $3
endef

all: mojo-app sky-app

mojo-app: build/vanadium_echo_client.mojo build/vanadium_echo_server.mojo

sky-app: mojo-app build/gen/mojom/examples/vanadium.mojom.dart

$(MOJO_SHARED_LIB):
	mkdir -p $(dir $@)
	ar rcs $@ $(MOJO_BUILD_DIR)/obj/mojo/public/platform/native/system.system_thunks.o

build/vanadium_echo_client.mojo: go/src/examples/vanadium/echo_client.go build/gen/go/src/mojom/examples/vanadium/vanadium.mojom.go $(MOJO_SHARED_LIB)
	$(call MOGO_BUILD,$<,$@)

build/vanadium_echo_server.mojo: go/src/examples/vanadium/echo_server.go build/gen/go/src/mojom/examples/vanadium/vanadium.mojom.go $(MOJO_SHARED_LIB)
	$(call MOGO_BUILD,$<,$@)

build/gen/go/src/mojom/examples/vanadium/vanadium.mojom.go: mojom/examples/vanadium.mojom
	$(call MOJOM_GEN,$<,build/gen,go)

build/gen/mojom/examples/vanadium.mojom.dart: mojom/examples/vanadium.mojom
	mkdir -p build/gen/mojom/examples # Remove after mojo is fixed to not require this
	$(call MOJOM_GEN,$<,build/gen,dart)

.PHONY: mojo-update
mojo-update: MOJOB_BIN=$(MOJO_DIR)/src/mojo/tools/mojob.py
mojo-update:
	$(MOJOB_BIN) sync
	$(MOJOB_BIN) gn $(MOJO_FLAGS)
	$(MOJOB_BIN) build $(MOJO_FLAGS)

.PHONY: clean
clean:
	rm -rf build
	rm -rf tmp
