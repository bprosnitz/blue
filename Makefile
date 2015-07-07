PWD=$(shell pwd)
DART_FILES := $(shell find dart -name *.dart ! -name *.part.dart)
V23_GOPATH=$(shell echo `v23 run env | grep GOPATH | cut -d\= -f2`)

ifndef MOJO_DIR
	$(error MOJO_DIR is not set: ${MOJO_DIR})
endif

ifdef ANDROID
	GO_BIN=$(MOJO_DIR)/src/third_party/go/tool/android_arm/bin/go
	GO_FLAGS=-ldflags=-shared
	MOJO_BUILD_DIR=$(MOJO_DIR)/src/out/android_Debug
	MOJO_FLAGS=--android
	MOJO_SHARED_LIB=$(PWD)/gen/lib/android/libsystem_thunk.a
else
	GO_BIN=$(MOJO_DIR)/src/third_party/go/tool/linux_amd64/bin/go
	GO_FLAGS=-ldflags=-shared -buildmode=c-shared
	MOJO_FLAGS=
	MOJO_BUILD_DIR=$(MOJO_DIR)/src/out/Debug
	MOJO_SHARED_LIB=$(PWD)/gen/lib/linux_amd64/libsystem_thunk.a
endif

# Compiles a Go program and links against the Mojo C shared library.
# $1 is input filename.
# $2 is output filename.
# See $(MOJO_DIR)/mojo/go/go.py for description of arguments to go.py (aka MOGO_BIN).
#
# MOJO_GOPATH must be exported so it can be picked up by MOGO_BIN.
export MOJO_GOPATH=$(V23_GOPATH):$(PWD)/gen/go:$(PWD)/go:$(MOJO_BUILD_DIR)/gen/go
MOGO_BIN=$(MOJO_DIR)/src/mojo/go/go.py
define MOGO_BUILD
	mkdir -p $(dir $2)
	$(MOGO_BIN) $(MOJO_FLAGS) -- \
		$(GO_BIN) \
		$(shell mktemp -d) \
		$(PWD)/$(2) \
		$(MOJO_DIR)/src \
		$(PWD)/gen \
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
	$(MOJOM_BIN) $1 -d . -o $2 -g $3
endef

all: mojo-app sky-app

mojo-app: gen/mojo/vanadium_echo_client.mojo gen/mojo/vanadium_echo_server.mojo

sky-app: mojo-app gen/mojom/vanadium.mojom.dart

.PHONY: run-mojo-app
run-mojo-app: mojo-app mojo-symlinks check-fmt
	$(MOJO_DIR)/src/mojo/tools/mojo_shell.py -v --enable-multiprocess $(MOJO_FLAGS) $(PWD)/gen/mojo/vanadium_echo_client.mojo

.PHONY: run-sky-app
run-sky-app: sky-app mojo-symlinks check-fmt
ifdef ANDROID
	$(error ANDROID is currently not supported for vanadium sky apps.  See https://github.com/domokit/mojo/issues/255)
endif
	$(MOJO_DIR)/src/mojo/tools/mojo_shell.py -v --enable-multiprocess $(MOJO_FLAGS) --sky vanadium/dart/echo_over_vanadium.dart

$(MOJO_SHARED_LIB):
	mkdir -p $(dir $@)
	ar rcs $@ $(MOJO_BUILD_DIR)/obj/mojo/public/platform/native/system.system_thunks.o

gen/mojo/vanadium_echo_client.mojo: go/src/vanadium/echo_client.go gen/go/src/mojom/vanadium/vanadium.mojom.go $(MOJO_SHARED_LIB)
	$(call MOGO_BUILD,$<,$@)

gen/mojo/vanadium_echo_server.mojo: go/src/vanadium/echo_server.go gen/go/src/mojom/vanadium/vanadium.mojom.go $(MOJO_SHARED_LIB)
	$(call MOGO_BUILD,$<,$@)

gen/go/src/mojom/vanadium/vanadium.mojom.go: mojom/vanadium.mojom
	$(call MOJOM_GEN,$<,gen,go)

gen/mojom/vanadium.mojom.dart: mojom/vanadium.mojom
	mkdir -p gen/mojom
	$(call MOJOM_GEN,$<,gen,dart)

# Check that the dart-style is being met. Note: Comments are ignored when
# checking whitespace.
.PHONY: check-fmt
check-fmt:
	dartfmt -n $(DART_FILES)

# Lint src and test files with dartanalyzer. This step takes a few seconds, so
# it may be better to rely on the dart-sublime plugin.
.PHONY: lint
lint:
	dartanalyzer $(DART_FILES)

# Create symlinks from the MOJO_DIR to the blue repo.  This allows mojo_shell
# to find resources in the blue repo.
.PHONY: mojo-symlinks
mojo-symlinks:
# Link dart app and resources.
	rm -rf $(MOJO_DIR)/src/vanadium
	ln -sf $(PWD) $(MOJO_DIR)/src/vanadium
# Link generated dart mojom files.
	rm -rf $(MOJO_BUILD_DIR)/gen/dart-pkg/packages/vanadium
	ln -sf $(PWD)/gen/dart-pkg $(MOJO_BUILD_DIR)/gen/dart-pkg/packages/vanadium

.PHONY: mojo-update
mojo-update: MOJOB_BIN=$(MOJO_DIR)/src/mojo/tools/mojob.py
mojo-update:
	cd $(MOJO_DIR)/src && git pull
	$(MOJOB_BIN) sync
	$(MOJOB_BIN) gn $(MOJO_FLAGS)
	$(MOJOB_BIN) build $(MOJO_FLAGS)

.PHONY: clean
clean:
	rm -rf gen
	rm -rf tmp
