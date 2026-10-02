# server

FileCodeBox 独立部署应用:薄壳入口(main.go)+ 前端静态资源 + 配置模板 + Dockerfile。**不含业务代码**——业务全部来自 [`filescodebox/core`](https://github.com/filescodebox/core) 库。

```
├── cmd/server/main.go   # 信号处理 + bootstrap.Bootstrap() 拉起 core
├── static/              # 前端构建产物(源在 filescodebox/frontend)
├── configs/             # config.yaml / config.example.yaml / config.prod.yaml
├── Dockerfile           # 三阶段构建:frontend → go(server+core+contracts) → runtime
└── Makefile
```

## 本地开发

依赖 sibling 目录(checkout 到同一父目录,`replace` 链互指):

```
filescodebox/            # 工作区根
├── contracts/           # github.com/filescodebox/contracts
├── core/                # github.com/filescodebox/core
├── server/              # 本仓库
└── frontend/            # github.com/filescodebox/frontend
```

```bash
make run                 # 起服务(默认 :12345,sqlite)
make test
```

## Docker 构建

构建上下文是**工作区根**(需要四个仓库同时 checkout):

```bash
docker build -f server/Dockerfile -t filecodebox-server ..   # 在 server/ 内执行
# 或 make docker-build
```

镜像内前端由 frontend 仓库源码现场构建;Go 侧经 replace 链联编 contracts+core+server。

## 与 filecodebox-fnos 的关系

两者是 core 的并列消费方:server 面向通用自托管(本仓库,含完整前端);fnos 面向飞牛 NAS 应用化(独立仓库,单容器库式调用)。
