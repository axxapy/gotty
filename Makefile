OUTPUT_DIR = ./builds
GIT_COMMIT = `git rev-parse HEAD | cut -c1-7`
VERSION = 1.1.0
BUILD_OPTIONS = -ldflags "-X main.Version=$(VERSION) -X main.CommitID=$(GIT_COMMIT)"

gotty:
	go build ${BUILD_OPTIONS} cmd/gotty/*.go

.PHONY: assets
assets:
	cd js && yarn install
	cd js && `yarn bin`/webpack
	mkdir -p bindata/static/{js,css}
	cp js/dist/gotty-bundle.js bindata/static/js/gotty-bundle.js
	cp js/node_modules/xterm/css/xterm.css bindata/static/css/xterm.css
	cp resources/index.html bindata/static/index.html
	cp resources/favicon.png bindata/static/favicon.png
	cp resources/index.css bindata/static/css/index.css
	cp resources/xterm_customize.css bindata/static/css/xterm_customize.css
	go-bindata -prefix bindata -pkg server -ignore=\\.gitkeep -o internal/server/asset.go bindata/...
	gofmt -w internal/server/asset.go

.PHONY: all
all: assets gotty

.PHONY: tools
tools:
	go get github.com/mitchellh/gox
	go get github.com/tcnksm/ghr
	go get github.com/jteeuwen/go-bindata/...

cross_compile:
	GOARM=5 gox -os="darwin linux freebsd netbsd openbsd" -arch="386 amd64 arm" -osarch="!darwin/arm" -output "${OUTPUT_DIR}/pkg/{{.OS}}_{{.Arch}}/{{.Dir}}"

targz:
	mkdir -p ${OUTPUT_DIR}/dist
	cd ${OUTPUT_DIR}/pkg/; for osarch in *; do (cd $$osarch; tar zcvf ../../dist/gotty_${VERSION}_$$osarch.tar.gz ./*); done;

shasums:
	cd ${OUTPUT_DIR}/dist; sha256sum * > ./SHA256SUMS

release:
	ghr -c ${GIT_COMMIT} --delete --prerelease -u yudai -r gotty pre-release ${OUTPUT_DIR}/dist

fmt:
	if [ `go fmt ./... | wc -l` -gt 0 ]; then echo "go fmt error"; exit 1; fi

test:
	go test ./...

.PHONY: clean
clean:
	rm -rf \
			js/node_modules \
			bindata
