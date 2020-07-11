.DEFAULT_GOAL=help

BUILD_DIR = build
GIT_COMMIT = `git rev-parse --short HEAD`
VERSION = 1.1.0
BUILD_OPTIONS = -ldflags "-X main.Version=$(VERSION) -X main.CommitID=$(GIT_COMMIT)"
BINARY = gotty
#GOARM=5

PLATFORMS=darwin linux freebsd netbsd openbsd
ARCHITECTURES=386 amd64 arm

.PHONY: help
help:  ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[\/a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: tools
tools:
	GO111MODULE=off go get github.com/jteeuwen/go-bindata/...

.PHONY: assets
assets: tools ## Build static assets
	cd js && yarn install
	cd js && `yarn bin`/webpack
	mkdir -p bindata/static/js
	mkdir -p bindata/static/css
	cp js/dist/gotty-bundle.js bindata/static/js/gotty-bundle.js
	cp js/node_modules/xterm/css/xterm.css bindata/static/css/xterm.css
	cp resources/index.html bindata/static/index.html
	cp resources/favicon.png bindata/static/favicon.png
	cp resources/index.css bindata/static/css/index.css
	cp resources/xterm_customize.css bindata/static/css/xterm_customize.css
	go-bindata -prefix bindata -pkg server -ignore=\\.gitkeep -o internal/server/asset.go bindata/...
	gofmt -w internal/server/asset.go

.PHONY: build
build: ## Build binary (assets must be built separately)
	mkdir -p $(BUILD_DIR)
	$(foreach GOOS, $(PLATFORMS),\
	$(foreach GOARCH, $(ARCHITECTURES), $(shell export GOOS=$(GOOS); export GOARCH=$(GOARCH); go build $(BUILD_OPTIONS) -o $(BUILD_DIR)/$(BINARY) cmd/gotty/*.go && gzip $(BUILD_DIR)/$(BINARY) && mv $(BUILD_DIR)/$(BINARY).gz $(BUILD_DIR)/$(BINARY)-$(GOOS)-$(GOARCH).gz)))
	cd ${OUTPUT_DIR}/dist; sha256sum * > ./SHA256SUMS

fmt: ## Run go fmt
	if [ `go fmt ./... | wc -l` -gt 0 ]; then echo "go fmt error"; exit 1; fi

test: ## Run go tests
	go test ./...

.PHONY: clean
clean: ## Clean projects from build artifacts
	rm -rf \
			js/node_modules \
			bindata \
			build
