# FileCodeBox server 镜像
#
# 依赖经 go.mod 正式版本解析(core/contracts 从 module proxy 拉取,无需本地 replace 链)。
# 构建上下文要求:filescodebox 工作区根目录(含 server/ frontend/ 两个 checkout)。
#   docker build -f server/Dockerfile -t filecodebox-server .
# GOPROXY 可用 --build-arg GOPROXY=... 覆盖(默认国内加速;CI 海外环境可传空串走默认)。

# Stage 1: Build Frontend
FROM node:20-alpine AS frontend-builder
WORKDIR /frontend
ARG NPM_REGISTRY=https://registry.npmmirror.com
COPY frontend/package.json frontend/package-lock.json* ./
RUN npm ci --registry=${NPM_REGISTRY}
COPY frontend/ ./
RUN npm run build

# Stage 2: Build Go(server;core/contracts 经版本化依赖拉取)
FROM golang:1.26-alpine AS go-builder
ARG GOPROXY=https://goproxy.cn,direct
ENV GOPROXY=${GOPROXY}
WORKDIR /src
RUN apk add --no-cache git
COPY server/ ./server/
WORKDIR /src/server
RUN go mod download
ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_TIME=unknown
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-X 'main.Version=${VERSION}' -X 'main.Commit=${COMMIT}' -X 'main.BuildTime=${BUILD_TIME}' -w -s" \
    -o /out/server ./cmd/server

# Stage 3: Runtime
FROM alpine:latest
WORKDIR /app
RUN apk --no-cache add ca-certificates tzdata wget && \
    addgroup -g 1000 app && \
    adduser -D -s /bin/sh -u 1000 -G app app && \
    mkdir -p /app/data /app/static /app/config && \
    chown -R app:app /app
COPY --from=go-builder /out/server ./server
COPY --from=frontend-builder /frontend/dist ./static/
# OpenAPI 快照供 /openapi.json(core OpenAPISpec)与前端 API 文档页使用
COPY --from=frontend-builder /frontend/openapi.json ./static/openapi.json
COPY server/configs ./config/
USER app
EXPOSE 12345
ENV TZ=Asia/Shanghai
# wget --spider 发 HEAD,/live 未注册 HEAD 会 404 导致健康检查永不通过,须显式 GET
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget -q -O /dev/null http://localhost:12345/live || exit 1
CMD ["./server", "--config", "./config/config.yaml"]
