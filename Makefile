.DEFAULT_GOAL=help

BUILD_DIR     = out
GIT_COMMIT    = `git rev-parse --short HEAD`
VERSION       = 1.1.0
BUILD_OPTIONS = -ldflags "-X main.Version=$(VERSION) -X main.CommitID=$(GIT_COMMIT)"
BINARY        = gotty

# Release targets. Each entry is GOOS/GOARCH. Unix-only: the localcommand
# backend uses Unix syscalls (TIOCSWINSZ etc.) so Windows is not supported.
TARGETS = darwin/amd64 darwin/arm64 linux/amd64 linux/arm64

.PHONY: help
help:  ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[\/a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: assets
assets: ## Build static assets
	cd js && bun install --frozen-lockfile
	cd js && bun run build
	mkdir -p assets/static/js assets/static/css
	cp js/node_modules/@xterm/xterm/css/xterm.css assets/static/css/xterm.css

.PHONY: build
build: ## Build a local binary at $(BUILD_DIR)/$(BINARY)
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=0 go build $(BUILD_OPTIONS) -o $(BUILD_DIR)/$(BINARY) ./cmd/gotty

.PHONY: binaries
binaries: ## Builds binaries for $(TARGETS) (assets must be built separately)
	@mkdir -p $(BUILD_DIR)
	@for target in $(TARGETS); do \
		os=$${target%/*}; arch=$${target#*/}; \
		echo "==> $$os/$$arch"; \
		CGO_ENABLED=0 GOOS=$$os GOARCH=$$arch \
			go build $(BUILD_OPTIONS) -o $(BUILD_DIR)/$(BINARY) ./cmd/gotty || exit 1; \
		tar czf $(BUILD_DIR)/$(BINARY)-$$os-$$arch.tgz .gotty -C $(BUILD_DIR) $(BINARY); \
		rm $(BUILD_DIR)/$(BINARY); \
	done
	cd $(BUILD_DIR) && sha256sum * > SHA256SUMS

.PHONY: fmt
fmt: ## Run go fmt
	if [ `go fmt ./... | wc -l` -gt 0 ]; then echo "go fmt error"; exit 1; fi

.PHONY: test
test: ## Run go tests
	go test ./...

.PHONY: clean
clean: ## Clean projects from build artifacts
	rm -rf js/node_modules $(BUILD_DIR)
