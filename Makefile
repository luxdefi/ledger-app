#*******************************************************************************
#*   (c) 2019 Zondax GmbH
#*
#*  Licensed under the Apache License, Version 2.0 (the "License");
#*  you may not use this file except in compliance with the License.
#*  You may obtain a copy of the License at
#*
#*      http://www.apache.org/licenses/LICENSE-2.0
#*
#*  Unless required by applicable law or agreed to in writing, software
#*  distributed under the License is distributed on an "AS IS" BASIS,
#*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#*  See the License for the specific language governing permissions and
#*  limitations under the License.
#********************************************************************************

# We use BOLOS_SDK to determine the development environment that is being used
# BOLOS_SDK IS  DEFINED	 	We use the plain Makefile for Ledger
# BOLOS_SDK NOT DEFINED		We use a containerized build approach

TESTS_JS_PACKAGE = "@zondax/ledger-lux-app"
TESTS_JS_DIR = $(CURDIR)/js

ifeq ($(BOLOS_SDK),)
	include $(CURDIR)/deps/dockerized_build.mk

.PHONY: init
init:
	cd deps; sh get_sdk.sh
	$(MAKE) deps
	$(MAKE) zemu_install

build:
	$(MAKE)
.PHONY: build

lint:
	cargo fmt
.PHONY: lint

clippy:
	cargo clippy --all-targets
.PHONY: clippy

.PHONY: zemu_debug
zemu_debug:
	cd $(TESTS_ZEMU_DIR) && yarn run debug

.PHONY: rust_test
rust_test:
	cargo test --features "full","derive-debug"

test_all:
	make rust_test
	make zemu_install
	make clean_build
	make build
	make zemu_test

.PHONY: fuzz clean_fuzz restore_fuzz
FUZZ_CMD = cd hfuzz && cargo hfuzz run apdu

fuzz:
	@echo "Adding \"rslib\" to crate-type"
	@sed -i.bak '/crate-type = \["staticlib"\]/ s/\]/, "rlib"\]/' app/Cargo.toml
	@trap "make -C $(CURDIR) restore_fuzz" INT; \
		$(FUZZ_CMD)
	$(MAKE) restore_fuzz

clean_fuzz:
	cd hfuzz && cargo hfuzz clean

restore_fuzz:
	@echo "Reverting crate-type to original"
	@mv app/Cargo.toml.bak app/Cargo.toml

else

default:
	$(MAKE) -C app

%:
	$(info "Calling app Makefile for target $@")
	COIN=$(COIN) $(MAKE) -C app $@

endif
