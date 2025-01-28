default: all

.PHONY: assets watch minify

ELM_FILES = $(shell find src -name '*.elm')

SHELL := /bin/bash
NPM_PATH := ./node_modules/.bin
ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DIST_DIR := ./dist
SCSS_FILES = $(shell find scss -name '*.scss')
URLS = /kleihaven/ /cursussen/ /over-ons/ /air/ /
DIST_URLS = $(foreach url, $(URLS), $(DIST_DIR)$(url)/index.html)
BASE_URL ?= http://localhost:3000
API_BASE_URL ?= http://localhost:8888
ASSETS_DIR = assets
OUTPUT_WEBP_DIR = assets/webp
OUTPUT_AVIF_DIR = assets/avif
WEBP_QUALITY = 80
AVIF_QUALITY = 30
JPG_FILES = $(shell find $(ASSETS_DIR) -type f -iname "*.jpg")

export PATH := $(NPM_PATH):$(PATH)

all: elm styles assets generate_html

assets:
	@mkdir -p ${DIST_DIR}/assets/ && cp -R ./assets ${DIST_DIR}
	@cp metatags.json ${DIST_DIR}
	@cp metatags-updater.js ${DIST_DIR}
	@cp -R netlify ${DIST_DIR}
	@echo "/*    /index.html   200" > ${DIST_DIR}/_redirects

build: deps elmoptimized styles minify assets generate_html

production:
	@$(MAKE) build BASE_URL=https://kleihaven.netlify.app API_BASE_URL=""

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
	@echo "  clean-images           Remove generated avif and webp images"
	@echo "  convert-images         Convert all jpg files in the assets dir to avif and webp. Requires ffmpeg."
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
	@sass --style=compressed scss/style.scss dist/style.css

watch:
	browser-sync start --single --server ${DIST_DIR} --files ["${DIST_DIR}/*.css", "${DIST_DIR}/*.js"]  --ignore ".netlify/**/*" & \
	find scss -name '*.scss' | entr make styles & \
	find src -name '*.elm' | entr make all

serve:
	@concurrently "make watch" "netlify functions:serve --port 8888"

generate_html: ensure_script_permissions
	@for url in $(URLS); do \
		mkdir -p $(DIST_DIR)$$url && \
		BASE_URL=$(BASE_URL) API_BASE_URL=$(API_BASE_URL) ./generate_html.sh index.template.html $(DIST_DIR)$$url/index.html $$url; \
		echo "Generated: $(DIST_DIR)$$url/index.html"; \
	done

ensure_script_permissions:
	@chmod +x generate_html.sh

convert-webp:
	@echo "Converting JPG to WebP..."
	@for file in $(JPG_FILES); do \
		dir=$$(dirname $$file); \
		rel_dir=$$(echo $$dir | sed 's|^$(ASSETS_DIR)/||; s|^$(ASSETS_DIR)$$||'); \
		file_name=$$(basename $$file .jpg); \
		if [ -z "$$rel_dir" ]; then \
			output_dir=$(OUTPUT_WEBP_DIR); \
		else \
			output_dir=$(OUTPUT_WEBP_DIR)/$$rel_dir; \
		fi; \
		mkdir -p $$output_dir; \
		if [ ! -f $$output_dir/$$file_name.webp ]; then \
			ffmpeg -i $$file -c:v libwebp -q:v $(WEBP_QUALITY) -preset default -pix_fmt yuv420p $$output_dir/$$file_name.webp; \
		else \
			echo "Skipping $$file_name.webp, already exists."; \
		fi; \
	done
	@echo "Conversion to WebP completed."

convert-avif:
	@echo "Converting JPG to AVIF..."
	@for file in $(JPG_FILES); do \
		dir=$$(dirname $$file); \
		rel_dir=$$(echo $$dir | sed 's|^$(ASSETS_DIR)/||; s|^$(ASSETS_DIR)$$||'); \
		file_name=$$(basename $$file .jpg); \
		if [ -z "$$rel_dir" ]; then \
			output_dir=$(OUTPUT_AVIF_DIR); \
		else \
			output_dir=$(OUTPUT_AVIF_DIR)/$$rel_dir; \
		fi; \
		mkdir -p $$output_dir; \
		if [ ! -f $$output_dir/$$file_name.avif ]; then \
			ffmpeg -i $$file -c:v libaom-av1 -crf $(AVIF_QUALITY) -b:v 0 -pix_fmt yuv420p $$output_dir/$$file_name.avif; \
		else \
			echo "Skipping $$file_name.avif, already exists."; \
		fi; \
	done
	@echo "Conversion to AVIF completed."

convert-images:
	@mkdir -p $(OUTPUT_WEBP_DIR) $(OUTPUT_AVIF_DIR)
	@$(MAKE) convert-webp convert-avif

clean-images:
	@echo "Cleaning up generated images..."
	rm -rf $(OUTPUT_WEBP_DIR) $(OUTPUT_AVIF_DIR)
	@echo "Clean up completed."