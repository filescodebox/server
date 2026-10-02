.PHONY: build run test vet clean docker-build release

APP_NAME=filecodebox-server
MAIN_PATH=./cmd/server

# 本地开发需 sibling checkout: ../contracts ../core ../frontend(Docker 构建上下文为上级目录)

build:
	go build -o bin/$(APP_NAME) $(MAIN_PATH)

run:
	go run $(MAIN_PATH) --config ./configs/config.yaml

test:
	go test ./...

vet:
	go vet ./...

clean:
	rm -rf bin/ logs/ data/*.db

docker-build:
	docker build -f server/Dockerfile -t $(APP_NAME):latest ..

release:
	docker build -f server/Dockerfile \
		--build-arg VERSION=$(shell git describe --tags --always 2>/dev/null || echo dev) \
		--build-arg COMMIT=$(shell git rev-parse --short HEAD) \
		--build-arg BUILD_TIME=$(shell date -u +%Y-%m-%dT%H:%M:%SZ) \
		-t $(APP_NAME):$(shell git describe --tags --always 2>/dev/null || echo dev) ..
