# Supabase on LazyCAT

这是一个为 LazyCAT 平台优化的 Supabase 自托管配置。基于官方 Docker Compose 设置，并适配了 LazyCAT 的部署规范。

## 📦 特性

- ✅ 完整的 Supabase 服务栈
- ✅ PostgreSQL 数据库
- ✅ 用户认证（GoTrue）
- ✅ REST API（PostgREST）
- ✅ 实时订阅（Realtime）
- ✅ 对象存储（Storage）
- ✅ Edge Functions
- ✅ Analytics（Logflare）
- ✅ Studio 管理界面

## 🚀 快速开始

### 1. 查看配置状态

每次进入开发环境时，会自动显示配置状态和关键信息：

```bash
lzc-cli project devshell --contentdir .
```

或手动运行欢迎脚本：

```bash
./welcome.sh
```

### 2. 生成密钥（生产环境必需）

运行密钥生成脚本：

```bash
chmod +x generate-secrets.sh
./generate-secrets.sh
```

脚本会自动生成所有必需的密钥并更新 `lzc-deploy-params.yml` 文件。

或者手动生成：

```bash
# 生成基础密钥
openssl rand -base64 32  # POSTGRES_PASSWORD
openssl rand -base64 64  # JWT_SECRET
openssl rand -base64 32  # LOGFLARE_PUBLIC_ACCESS_TOKEN
openssl rand -base64 48  # LOGFLARE_PRIVATE_ACCESS_TOKEN
openssl rand -base64 64  # SECRET_KEY_BASE
openssl rand -hex 16     # VAULT_ENC_KEY

# JWT tokens 需要使用 JWT_SECRET 签名，参考 generate-secrets.sh
```

### 3. 部署到 LazyCAT

```bash
# 构建 LPK 包
lzc-cli project build

# 开发环境测试
lzc-cli project devshell --contentdir .

# 生产部署
# 在 LazyCAT 平台上传 .lpk 文件并安装
```

### 4. 访问

部署成功后访问：
- **Studio 管理界面**: `https://your-domain/`
- **Analytics 数据**: 在 Studio 界面中查看（Reports 页面）

> 💡 **注意**: 所有 API 请求都通过 Kong 网关统一处理，无需单独访问各个服务

## 📝 配置说明

### 部署参数（lzc-deploy-params.yml）

所有密钥和配置项都在此文件中定义，用户安装时可自定义：

| 参数 | 说明 | 是否必需 |
|------|------|----------|
| `POSTGRES_PASSWORD` | 数据库密码 | ✅ |
| `JWT_SECRET` | JWT 签名密钥 | ✅ |
| `ANON_KEY` | 客户端公开 API 密钥 | ✅ |
| `SERVICE_ROLE_KEY` | 服务端 API 密钥 | ✅ |
| `LOGFLARE_*_TOKEN` | Analytics 访问令牌 | ✅ |
| `SECRET_KEY_BASE` | Realtime/Pooler 基础密钥 | ✅ |
| `VAULT_ENC_KEY` | Vault 加密密钥 | ✅ |

### 数据持久化

以下目录会持久化保存数据：
- `/lzcapp/var/supabase-storage` - 对象存储文件
- `/lzcapp/var/analytics` - Analytics 数据
- `/lzcapp/var/db-config` - 数据库配置
- `/lzcapp/pkg/content/db/data` - PostgreSQL 数据

## 🔒 安全建议

1. **生产环境必须修改所有默认密钥**
2. 定期轮换敏感密钥（`SERVICE_ROLE_KEY`、数据库密码等）
3. `SERVICE_ROLE_KEY` 不应暴露给客户端
4. 建议启用 SSL/TLS 加密
5. 限制 Kong Dashboard 访问（生产环境可移除 `/kong` 路由）

## 📚 参考文档

- [Supabase 官方文档](https://supabase.com/docs)
- [LazyCAT 开发者手册](https://developer.lazycat.cloud)
- [Docker Compose 自托管指南](https://supabase.com/docs/guides/hosting/docker)

## 🛠 故障排查

### JWT 签名错误

如果遇到 `invalid JWT: signature is invalid` 错误：
- 确保所有服务使用相同的 `JWT_SECRET`
- 确保 `ANON_KEY` 和 `SERVICE_ROLE_KEY` 使用正确的 JWT_SECRET 签名

### 数据库连接失败

- 检查 `POSTGRES_PASSWORD` 是否在所有服务中一致
- 确认数据库服务已正常启动

## 📄 License

MIT