# configs/ - 配置文件目录

server 的配置模板目录。本目录**只有 YAML 模板，不含 Go 代码**——配置结构定义与
加载逻辑在 core 仓 [`conf/`](https://github.com/pigeonbox/core/tree/main/conf)。

## 文件说明

| 文件 | 用途 |
|------|------|
| `config.yaml` | 默认/开发配置 |
| `config.example.yaml` | 带完整注释的示例模板 |
| `config.prod.yaml` | 生产配置模板 |

## 关键默认值

- 端口：`server.port: 12345`（env `FCB_SERVER_PORT` 可覆盖）
- 数据库：默认 SQLite（`./data/fileCodeBox.db`），可切 mysql/postgresql
- Redis：可选；多副本（public/admin 模式）与配置广播场景必配
- 存储后端：`storage.type` 支持 local/s3 等共 14 种

## 配置加载与覆盖优先级

```
--config 启动参数 / CONFIG_PATH env 指定文件 → yaml 默认值 → FCB_* 环境变量覆盖（优先级最高）
```

敏感项（JWT secret/数据库/Redis/管理员密码等）一律用环境变量注入，
完整清单见 hub 仓 [`docs/ENVIRONMENT_VARIABLES.md`](https://github.com/pigeonbox/pigeonbox/blob/main/docs/ENVIRONMENT_VARIABLES.md)。

## 部署模式（多副本）

三个模板均含 `deployment` 注释段：`deployment.mode`（env `FCB_DEPLOY_MODE`）支持
`standalone`（默认，单进程全功能）/ `public`（公开面副本，可多实例）/ `admin`（管理面单实例）。
public/admin 硬约束：mysql/postgresql + Redis 必配。

设计详见 hub 仓 `docs/specs/2026-10-06-multi-replica-deployment-modes.md`；
Kubernetes 拓扑用 charts 仓 `pigeonbox` chart 2.0+（`replicaCount>1` 自动拆分双 Deployment）。

## 注意

- 不要将真实密码提交到版本控制；模板中的默认值仅为占位
- 管理后台在线改的站点配置持久化在 DB `system_configs` 表，不回写本目录 yaml
