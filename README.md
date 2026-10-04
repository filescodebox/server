# server · 独立部署应用

[![CI](https://github.com/filescodebox/server/actions/workflows/ci.yml/badge.svg)](https://github.com/filescodebox/server/actions/workflows/ci.yml)
[![Tag](https://img.shields.io/github/v/tag/filescodebox/server)](https://github.com/filescodebox/server/tags)
[![License](https://img.shields.io/github/license/filescodebox/server)](LICENSE)

FilesCodeBox 独立部署应用:**纯后端**薄壳入口(main.go)+ 配置模板 + Dockerfile。**不含业务代码**——业务全部来自 [`filescodebox/core`](https://github.com/filescodebox/core) 库。

> 0.9.0 起"内嵌前端"模式已剔除:前端由同版本的 [`filescodebox/frontend`](https://github.com/filescodebox/frontend) nginx 镜像分离提供;core 对缺失的 `./static` 优雅降级(探针/API 全正常,SPA 路径 404),单跑也安全。

> 🗂️ [FilesCodeBox 生态](https://github.com/orgs/filescodebox)成员仓 · 总览与部署见 [装配仓 filescodebox](https://github.com/filescodebox/filescodebox) · [架构图集](https://github.com/filescodebox/filescodebox/blob/main/docs/architecture.md)

## 发布镜像

打 `v*` tag 后 CI 自动构建多架构镜像推 ghcr,**前后端镜像同版本发布**:

| 镜像 | 说明 |
|------|------|
| `ghcr.io/filescodebox/server` | 纯后端 API(监听 :12345,仅业务) |
| `ghcr.io/filescodebox/frontend` | nginx-unprivileged 静态资源 + API 反代(**对外统一入口**) |

自托管推荐形态:compose 或 Helm 起前后端双容器,frontend 承接全部对外流量(见 [charts](https://github.com/filescodebox/charts) 与 hub 仓 [docs/DEPLOY-COMPOSE.md](https://github.com/filescodebox/filescodebox/blob/main/docs/DEPLOY-COMPOSE.md))。

## 目录结构

```
├── cmd/server/main.go   # 信号处理 + bootstrap.Bootstrap() 拉起 core
├── cmd/fcb/             # 官方 CLI 客户端(文本/文件分享、本地导入、我的分享管理;API Key 认证)
├── static/              # 历史残留(分离部署不使用,core 优雅降级)
├── configs/             # config.yaml / config.example.yaml / config.prod.yaml
├── Dockerfile           # 两阶段:go-builder → runtime(Go 依赖经 module proxy 拉正式版本)
└── Makefile
```

## 本地开发

依赖 sibling 目录(checkout 到同一父目录,`replace` 链互指;或直接用 hub 仓的 go.work):

```
filescodebox/            # 工作区根
├── contracts/           # github.com/filescodebox/contracts
├── core/                # github.com/filescodebox/core
└── server/              # 本仓库
```

```bash
make run                 # 起服务(默认 :12345,sqlite)
make test
```

## Docker 构建

构建上下文是**工作区根**(仅消费 `server/` 子目录;core/contracts 经 go.mod 正式版本从 module proxy 解析,无需本地 replace 链):

```bash
docker build -f server/Dockerfile -t filecodebox-server ..   # 在 server/ 内执行
# 或 make docker-build
```

## 与 fnos 的关系

两者是 core 的并列消费方:server 面向通用自托管(纯后端 + 分离前端);fnos 面向飞牛 NAS 应用化(独立仓库,单容器库式调用)。

## License

[Apache-2.0](LICENSE)
