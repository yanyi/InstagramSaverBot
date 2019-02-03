DOCKER_IMAGE_NAME=instagramsaverbot
DOCKER_TAG=

GOOS=
CGO_ENABLED=
GOARCH=
PACKAGE=github.com/yanyi/instagramsaverbot
BINARY_NAME=instagramsaverbot
BUILD_PATH=bin/$(GOOS)/$(GOARCH)/$(BINARY_NAME)

# ---------------------------
# Docker
# ---------------------------

docker.test:
	@echo "Test"
	ls -la
.PHONY: docker.test

# Build the Docker image
docker.build: DOCKER_TAG=$(shell git rev-parse --short HEAD)
docker.build:
	docker build \
		--tag $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) \
		-f ./build/Dockerfile .
.PHONY: docker.build

# ---------------------------
# Go
# ---------------------------

go.dependencies:
	GO111MODULE=on go get -u -v ./...
.PHONY: go.dependencies

go.test:
	go test -v -short -cover ./...
.PHONY: go.test

# Lint non-vendored packages
# Exits if fail, should affect CI/CD pipeline
go.lint:
	@GO111MODULE=on go get -u golang.org/x/lint/golint
	@echo "\nLinting..."
	@golint -set_exit_status $(shell go list ./...)
	@echo "Finished linting"
.PHONY: go.lint

# Generic Go builder
go.build.generic:
	CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) go build -v -o $(BUILD_PATH) ./cmd/instagramsaverbot
.PHONY: go.build.generic

# Build binary for Heroku
go.build.heroku: GOOS=linux
go.build.heroku: CGO_ENABLED=0
go.build.heroku: GOARCH=amd64
go.build.heroku: go.build.generic
.PHONY: go.build.heroku

# Build binary for macOS
go.build.mac: GOOS=darwin
go.build.mac: CGO_ENABLED=1
go.build.mac: GOARCH=amd64
go.build.mac: go.build.generic
.PHONY: go.build.mac

# Build binary for alpine (Docker image)
go.build.alpine: GOOS=linux
go.build.alpine: CGO_ENABLED=1
go.build.alpine: GOARCH=386
go.build.alpine: go.build.generic
.PHONY: go.build.alpine

# ---------------------------
# Heroku
# ---------------------------

push.heroku: go.build.heroku
	git add $(BUILD_PATH)
	git commit -m "Add binary for Heroku"
	git push heroku master
.PHONY: go.build.heroku