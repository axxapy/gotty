.DEFAULT_GOAL=help

BUILD_DIR = out
GIT_COMMIT = `git rev-parse --short HEAD`
VERSION = 1.1.0
BUILD_OPTIONS = -ldflags "-X main.Version=$(VERSION) -X main.CommitID=$(GIT_COMMIT)"
BINARY = gotty
GOENV = GOARM=5 CGO_ENABLED=0

PLATFORMS=darwin linux freebsd netbsd openbsd
ARCHITECTURES=386 amd64 arm arm64

.PHONY: help
help:  ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[\/a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: assets
assets: ## Build static assets
	cd js && yarn install
	cd js && `yarn bin`/webpack
	mkdir -p assets/static/js
	mkdir -p assets/static/css
	cp js/node_modules/xterm/css/xterm.css assets/static/css/xterm.css

.PHONY: binaries
binaries: ## Builds binaries (assets must be built separately)
	mkdir -p $(BUILD_DIR)
	$(foreach GOOS, $(PLATFORMS),\
	$(foreach GOARCH, $(ARCHITECTURES), $(shell export GOOS=$(GOOS); export GOARCH=$(GOARCH); $(GOENV) go build $(BUILD_OPTIONS) -o $(BUILD_DIR)/$(BINARY) cmd/gotty/*.go && tar czf $(BUILD_DIR)/$(BINARY)-$(GOOS)-$(GOARCH).tgz .gotty --directory=$(BUILD_DIR) $(BINARY) && rm $(BUILD_DIR)/$(BINARY))))
	cd ${BUILD_DIR} && sha256sum * > ./SHA256SUMS

fmt: ## Run go fmt
	if [ `go fmt ./... | wc -l` -gt 0 ]; then echo "go fmt error"; exit 1; fi

test: ## Run go tests
	go test ./...

.PHONY: clean
clean: ## Clean projects from build artifacts
	rm -rf \
			js/node_modules \
			js/dist \
			build
