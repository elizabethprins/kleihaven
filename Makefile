default: all

.PHONY: assets watch minify

ELM_FILES = $(shell find src -name '*.elm')

SHELL := /bin/bash
NPM_PATH := ./node_modules/.bin
ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DIST_DIR := ./dist
SCSS_FILES = $(shell find scss -name '*.scss')
URLS = /kleihaven /
DIST_URLS = $(foreach url, $(URLS), $(DIST_DIR)$(url)/index.html)
BASE_URL ?= http://localhost:3000

export PATH := $(NPM_PATH):$(PATH)

all: elm styles assets generate_html

assets:
	@mkdir -p ${DIST_DIR}/assets/ && cp -R ./assets ${DIST_DIR}
	@cp metatags.json ${DIST_DIR}
	@cp metatags-updater.js ${DIST_DIR}

build: deps elmoptimized styles minify assets generate_html

production:
	@$(MAKE) build BASE_URL=https://kleihaven.netlify.app

clean:
	@rm -Rf dist/*

deps:
	@npm install

distclean: clean
	@rm -Rf elm-stuff
	@rm -Rf node_modules

elm:
	@elm make --debug src/Main.elm --output dist/main.js

elmoptimized:
	@elm make --optimize src/Main.elm --output dist/main.js

elmreview:
	@npx elm-review

format:
	@elm-format --yes src

format-validate:
	@elm-format --validate src

help:
	@echo "Run: make <target> where <target> is one of the following:"
	@echo "  all                    Compile all Elm files"
	@echo "  assets                 Copy assets to dist folder"
	@echo "  build                  Install deps and compile for production"
	@echo "  clean                  Remove 'dist' folder"
	@echo "  deps                   Install build dependencies"
	@echo "  distclean              Remove build dependencies"
	@echo "  elm                    Compile Elm files"
	@echo "  elmoptimized           Compile and optimize Elm files"
	@echo "  elmreview              Review Elm files"
	@echo "  format                 Run Elm format"
	@echo "  format-validate        Check if Elm files are formatted"
	@echo "  help                   Magic"
	@echo "  minify                 Minify js files with uglify-js"
	@echo "  styles                 Compile Scss files"
	@echo "  watch                  Run 'make all' on Elm file change"

minify:
	@npx uglify-js ${DIST_DIR}/main.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | npx uglify-js --mangle --output ${DIST_DIR}/main.js\

styles: $(SCSS_FILES)
	@sass scss/style.scss dist/style.css

watch:
	browser-sync start --single --server ${DIST_DIR} --files ["${DIST_DIR}/*.css", "${DIST_DIR}/*.js"] & \
	find scss -name '*.scss' | entr make styles & \
	find src -name '*.elm' | entr make all

generate_html: ensure_script_permissions
	@for url in $(URLS); do \
		mkdir -p $(DIST_DIR)$$url && \
		BASE_URL=$(BASE_URL) ./generate_html.sh index.template.html $(DIST_DIR)$$url/index.html $$url; \
		echo "Generated: $(DIST_DIR)$$url/index.html"; \
	done

ensure_script_permissions:
	@chmod +x generate_html.sh