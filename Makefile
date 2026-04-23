SHELL := /usr/bin/env bash

RUBY_VERSION := "$(shell ruby -v)"
RUBY_VERSION_REQUIRED := "$(shell cat .ruby-version)"
RUBY_MATCH := $(shell [[ "$(shell ruby -v)" =~ "ruby $(shell cat .ruby-version)" ]] && echo matched)

.PHONY: ruby-version-check scaffold-plugin
ruby-version-check:
ifndef RUBY_MATCH
	$(error ruby $(RUBY_VERSION_REQUIRED) is required. Found $(RUBY_VERSION). $(newline)Run 'mise activate' or prefix you make command with 'mise x --' see README.md for more information)$(newline)
endif

# Installs yarn packages and gems.
install:
	mise install
	git submodule update --init
	corepack enable
	yarn install --immutable
	bundle install
	cd tools/frontmatter-validator && npm ci

validate-frontmatters:
	npm --prefix tools/frontmatter-validator run validate

# Using local dependencies, starts a doc site instance on http://localhost:4000.
run: ruby-version-check validate-frontmatters
	NODE_OPTIONS="--max_old_space_size=8192" yarn netlify dev --offline --skip-wait-port --internal-disable-edge-functions

run-debug: ruby-version-check
	NODE_OPTIONS="--max_old_space_size=8192" JEKYLL_LOG_LEVEL='debug' yarn netlify dev --skip-wait-port --internal-disable-edge-functions

build: ruby-version-check
	exe/build

# Cleans up all temp files in the build.
# Run `make clean` locally whenever you're updating dependencies, or to help
# troubleshoot build issues.
clean:
	-rm -rf dist
	-rm -rf app/.jekyll-cache
	-rm -rf app/.jekyll-metadata
	-rm -rf .jekyll-cache/vite

kill-ports:
	@JEKYLL_PROCESS=$$(lsof -ti:4000) && kill -9 $$JEKYLL_PROCESS || true
	@VITE_PROCESS=$$(lsof -ti:3036) && kill -9 $$VITE_PROCESS || true

vale:
	-git diff --name-only --diff-filter=d origin/main HEAD | grep '\.md$$' | xargs vale

scaffold-plugin:
	@if [ -z "$(PLUGIN)" ]; then \
	  echo "Error: Plugin name is required. Usage: make scaffold-plugin PLUGIN=<plugin-name>"; \
	  exit 1; \
	fi
	cd tools/scaffold-plugin && npm ci
	node tools/scaffold-plugin/index.js $(PLUGIN)
