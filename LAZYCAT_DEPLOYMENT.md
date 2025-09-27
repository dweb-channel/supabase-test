# Supabase 在懒猫微服平台的部署说明

## 问题总结

在将 Supabase 部署到懒猫微服（LazyCat）平台时，遇到了以下主要问题：

1. **数据库连接失败**：多个服务无法连接到 PostgreSQL 数据库
2. **Kong 配置文件找不到**：Kong 服务无法找到配置文件
3. **挂载路径错误**：配置文件和数据目录挂载路径不正确

## 解决方案

### 1. 服务间通信使用 localhost

**懒猫微服平台的特殊性**：
- 所有容器运行在同一个网络命名空间中
- 服务间通信必须使用 `localhost` 而不是服务名
- 这与标准 Docker Compose 不同

**修改示例**：
```yaml
# 错误的配置（Docker Compose 方式）
DATABASE_URL: postgres://user:pass@db:5432/database

# 正确的配置（懒猫微服方式）
DATABASE_URL: postgres://user:pass@localhost:5432/database
```

### 2. 挂载路径规范

**懒猫微服挂载路径要求**：
- 所有挂载路径必须以 `/lzcapp` 开头
- 通常使用 `/lzcapp/pkg/content` 作为应用内容路径
- 使用 `/lzcapp/var` 作为数据持久化路径

**修改内容**：
```yaml
# Kong 配置文件挂载
binds:
  - /lzcapp/pkg/content/volumes/api:/home/kong/config

# 数据库初始化脚本挂载
binds:
  - /lzcapp/pkg/content/volumes/db/realtime.sql:/docker-entrypoint-initdb.d/migrations/99-realtime.sql
  - /lzcapp/var/supabase-data:/var/lib/postgresql/data

# Vector 日志配置挂载
binds:
  - /lzcapp/pkg/content/volumes/logs:/etc/vector/config
```

### 3. 目录结构

确保以下目录结构存在：
```
supabase-project/
├── volumes/
│   ├── api/
│   │   └── kong.yml        # Kong 配置文件
│   ├── db/
│   │   ├── _supabase.sql
│   │   ├── jwt.sql
│   │   ├── logs.sql
│   │   ├── pooler.sql
│   │   ├── realtime.sql
│   │   ├── roles.sql
│   │   └── webhooks.sql
│   ├── functions/
│   │   └── main/
│   ├── logs/
│   │   └── vector.yml      # Vector 配置文件
│   └── pooler/
│       └── pooler.exs      # Pooler 配置文件
├── lzc-manifest.yml        # 懒猫微服清单文件
└── lzc-build.yml          # 懒猫微服构建文件
```

## 已修复的配置

### 服务连接配置
- ✅ auth 服务：数据库连接改为 `localhost:5432`
- ✅ rest 服务：数据库连接改为 `localhost:5432`
- ✅ realtime 服务：DB_HOST 改为 `localhost`
- ✅ storage 服务：数据库连接和 PostgREST URL 改为 `localhost`
- ✅ meta 服务：PG_META_DB_HOST 改为 `localhost`
- ✅ functions 服务：SUPABASE_DB_URL 改为 `localhost`
- ✅ analytics 服务：DB_HOSTNAME 改为 `localhost`
- ✅ supavisor 服务：DATABASE_URL 改为 `localhost`

### 挂载路径配置
- ✅ Kong: `/lzcapp/pkg/content/volumes/api` → `/home/kong/config`
- ✅ Vector: `/lzcapp/pkg/content/volumes/logs` → `/etc/vector/config`
- ✅ Functions: `/lzcapp/pkg/content/volumes/functions` → `/home/deno/functions`
- ✅ Pooler: `/lzcapp/pkg/content/volumes/pooler` → `/etc/pooler/config`
- ✅ DB SQL 文件: `/lzcapp/pkg/content/volumes/db/*.sql` → 对应的容器路径

## 部署步骤

1. **确认文件结构**：确保所有配置文件和 SQL 脚本都在正确的位置

2. **构建 LPK 包**：
   ```bash
   lzc build
   ```

3. **部署到懒猫微服**：
   - 通过懒猫微服管理面板上传并安装 LPK 包
   - 或使用 CLI 工具部署

4. **验证部署**：
   - 检查所有服务是否正常启动
   - 访问 Supabase Studio 界面
   - 测试数据库连接

## 注意事项

1. **网络模式**：懒猫微服使用特殊的网络架构，所有容器共享同一网络命名空间
2. **文件挂载**：不支持单个文件挂载，必须挂载目录
3. **SELinux 标签**：macOS 系统不支持 SELinux 标签（:z, :Z），需要移除
4. **环境变量**：确保所有必要的环境变量都已正确配置

## 故障排查

如果遇到问题，请检查：
1. 服务日志中的连接错误是否使用了正确的 `localhost`
2. 配置文件是否在正确的挂载路径下
3. 数据库服务是否已启动并健康
4. 服务启动顺序是否正确（通过 `depends_on` 配置）

## 参考资源

- [懒猫微服开发者手册](https://developer.lazycat.cloud/)
- [lzc-manifest.yml 规范文档](https://developer.lazycat.cloud/spec/manifest.html)
- [网络机制与 VPN](https://developer.lazycat.cloud/network.html)
