SHELL:=/usr/bin/env bash
MAKEFLAGS += --no-builtin-rules --no-builtin-variables
TF_CMD:=apply -auto-approve
VARIANT=builder
SYSTEM?=aarch64-linux
TESTING_X86_URL=https://github.com/loic-roux-404/k3s-paas/releases/download/nixos-testing/nixos.qcow2

#### Nix

BUILDER_EXEC:=
NIXOS_CONFIG:=qcow

ifeq ($(shell uname -s),Darwin)
   BUILDER_EXEC:=NIX_CONF_DIR=$(PWD)/bootstrap nix develop .\#builder --command
endif

bootstrap-aarch64-linux:
	@$(BUILDER_EXEC) echo "Started default build environment"

bootstrap-x86_64-linux:
	@VARIANT=builder-x86 $(BUILDER_EXEC) echo "Started x86 environment"
	@echo "Waiting builder to start..."
	@sleep 15

bootstrap: bootstrap-$(SYSTEM)

nixos-local: bootstrap build

build:
	@nix build .#nixosConfigurations.initial.config.formats.qcow --system $(SYSTEM)

pull-testing-x86:
	@rm -rf result && mkdir result
	@wget -q --show-progress -O result/nixos.qcow2 $(TESTING_X86_URL)

TERRAGRUNT_FILES:=$(shell find terragrunt -type d -name '.*' -prune -o -name 'terragrunt.hcl' -exec dirname {} \;)

$(TERRAGRUNT_FILES):
	@cd $@ && terragrunt $(TF_CMD)

.PHONY: fmt bootstrap nixos-local trust-ca $(TERRAGRUNT_FILES)
