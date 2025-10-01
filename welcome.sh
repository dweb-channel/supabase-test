#!/bin/sh

###############################################################################
# Supabase 欢迎脚本
# 自动检查配置状态，显示关键信息和快速命令
###############################################################################

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo "=========================================="
echo "  🚀 Supabase on LazyCAT"
echo "=========================================="
echo ""

# 检查密钥配置
check_secrets() {
    if [ ! -f "lzc-deploy-params.yml" ]; then
        echo "${RED}❌ 未找到 lzc-deploy-params.yml${NC}"
        return 1
    fi
    
    # 检查是否使用默认密钥
    if grep -q "WfIWPT3OZAz" lzc-deploy-params.yml 2>/dev/null; then
        echo "${YELLOW}⚠️  检测到使用默认密钥（不安全）${NC}"
        return 2
    fi
    
    echo "${GREEN}✅ 密钥配置已自定义${NC}"
    return 0
}

# 显示访问信息
show_access_info() {
    echo ""
    echo "${BLUE}📍 访问地址:${NC}"
    echo "   ${GREEN}Studio 管理界面:${NC}"
    echo "      https://supabase.waterbang.heiyu.space/"
    echo ""
    echo "   ${YELLOW}💡 提示:${NC} Analytics 数据可在 Studio 界面中查看"
    echo ""
}

# 显示 API 端点
show_api_endpoints() {
    echo "${BLUE}🔑 API 端点 (通过 Kong 网关):${NC}"
    echo "   - Auth:     https://supabase.waterbang.heiyu.space/auth/v1/"
    echo "   - REST:     https://supabase.waterbang.heiyu.space/rest/v1/"
    echo "   - Storage:  https://supabase.waterbang.heiyu.space/storage/v1/"
    echo "   - Realtime: wss://supabase.waterbang.heiyu.space/realtime/v1/"
    echo "   - GraphQL:  https://supabase.waterbang.heiyu.space/graphql/v1/"
    echo ""
}

# 显示密钥信息
show_keys() {
    if [ -f "lzc-deploy-params.yml" ]; then
        echo "${BLUE}🔐 API 密钥:${NC}"
        
        # 提取 ANON_KEY
        ANON_KEY=$(grep -A 3 "id: ANON_KEY" lzc-deploy-params.yml | grep "default_value:" | sed 's/.*default_value: "\(.*\)"/\1/')
        if [ -n "$ANON_KEY" ]; then
            echo "   ${GREEN}ANON_KEY${NC} (客户端公开使用):"
            echo "      ${ANON_KEY}"
            echo ""
        fi
        
        # 提取 SERVICE_ROLE_KEY
        SERVICE_KEY=$(grep -A 3 "id: SERVICE_ROLE_KEY" lzc-deploy-params.yml | grep "default_value:" | sed 's/.*default_value: "\(.*\)"/\1/')
        if [ -n "$SERVICE_KEY" ]; then
            echo "   ${RED}SERVICE_ROLE_KEY${NC} (服务端使用，请保密):"
            echo "      ${SERVICE_KEY:0:60}..."
            echo ""
        fi
        
        # 提取数据库密码
        DB_PASSWORD=$(grep -A 3 "id: POSTGRES_PASSWORD" lzc-deploy-params.yml | grep "default_value:" | sed 's/.*default_value: "\(.*\)"/\1/')
        if [ -n "$DB_PASSWORD" ]; then
            echo "   ${RED}数据库密码:${NC} ${DB_PASSWORD:0:20}... (已隐藏)"
            echo ""
        fi
    fi
}

# 显示快速命令
show_quick_commands() {
    echo "${BLUE}📚 快速命令:${NC}"
    echo "   ${GREEN}密钥管理:${NC}"
    echo "      ./generate-secrets.sh          # 生成新的安全密钥"
    echo "      cat lzc-deploy-params.yml      # 查看当前配置"
    echo ""
    echo "   ${GREEN}部署管理:${NC}"
    echo "      lzc-cli project build          # 构建 LPK 包"
    echo "      lzc-cli project devshell       # 进入开发环境"
    echo "      lzc-cli app logs               # 查看应用日志"
    echo "      lzc-cli app status             # 查看应用状态"
    echo ""
    echo "   ${GREEN}数据库管理:${NC}"
    echo "      psql -h localhost -p 5432 -U postgres -d postgres"
    echo ""
}

# 显示安全提示
show_security_tips() {
    SECRET_CHECK=$(check_secrets)
    if [ $? -eq 2 ]; then
        echo "${YELLOW}🔒 安全提示:${NC}"
        echo "   ${RED}检测到您正在使用默认密钥！${NC}"
        echo "   ${YELLOW}生产环境部署前请务必运行:${NC}"
        echo "      ${GREEN}./generate-secrets.sh${NC}"
        echo ""
    fi
}

# 主函数
main() {
    check_secrets
    SECRET_STATUS=$?
    
    if [ $SECRET_STATUS -eq 1 ]; then
        echo "${RED}❌ 配置文件缺失${NC}"
        echo ""
        echo "${YELLOW}请先完成以下步骤:${NC}"
        echo "   1. 确保 lzc-deploy-params.yml 存在"
        echo "   2. 运行 ./generate-secrets.sh 生成密钥"
        echo "   3. 运行 lzc-cli project build 构建项目"
        echo ""
    else
        show_access_info
        show_api_endpoints
        show_keys
        show_security_tips
        show_quick_commands
    fi
    
    echo "=========================================="
    echo ""
    echo "${GREEN}💡 提示:${NC} 文档位于 README.md 和 SECRETS-GUIDE.md"
    echo ""
}

# 执行主函数
main
