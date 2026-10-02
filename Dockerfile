# FileCodeBox server 镜像(多模块版)
#
# 构建上下文要求:filescodebox 工作区根目录(含 contracts/ core/ server/ frontend/ 四个 checkout)。
#   docker build -f server/Dockerfile -t filecodebox-server .
# CI:把四个 repo checkout 到同一目录后执行上述命令。

# Stage 1: Build Frontend
FROM node:20-alpine AS frontend-builder
WORKDIR /frontend
COPY frontend/package.json frontend/package-lock.json* ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# Stage 2: Build Go (server + core + contracts via replace 链)
FROM golang:1.25-alpine AS go-builder
WORKDIR /src
RUN apk add --no-cache git
COPY contracts/ ./contracts/
COPY core/ ./core/
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
COPY server/configs ./config/
USER app
EXPOSE 12345
ENV TZ=Asia/Shanghai
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:12345/live || exit 1
CMD ["./server", "--config", "./config/config.yaml"]
