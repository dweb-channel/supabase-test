#!/bin/bash

###############################################################################
# Supabase 密钥一键生成脚本
# 用途：为 LazyCAT 平台上的 Supabase 部署生成所有必需的密钥
# 作者：Supabase on LazyCAT
# 使用方法：./generate-secrets.sh
###############################################################################

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查依赖
check_dependencies() {
    print_info "检查依赖工具..."
    
    if ! command -v openssl &> /dev/null; then
        print_error "未找到 openssl 命令，请先安装 OpenSSL"
        exit 1
    fi
    
    if ! command -v node &> /dev/null; then
        print_warning "未找到 Node.js，将跳过 JWT token 生成"
        print_warning "请手动在 https://jwt.io 生成 ANON_KEY 和 SERVICE_ROLE_KEY"
        SKIP_JWT=true
    else
        SKIP_JWT=false
    fi
    
    print_success "依赖检查完成"
}

# 生成随机密钥
generate_secrets() {
    print_info "生成随机密钥..."
    
    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')
    JWT_SECRET=$(openssl rand -base64 64 | tr -d '\n')
    LOGFLARE_PUBLIC_ACCESS_TOKEN=$(openssl rand -base64 32 | tr -d '\n')
    LOGFLARE_PRIVATE_ACCESS_TOKEN=$(openssl rand -base64 48 | tr -d '\n')
    SECRET_KEY_BASE=$(openssl rand -base64 64 | tr -d '\n')
    VAULT_ENC_KEY=$(openssl rand -hex 16)
    
    # 生成 Kong Dashboard 凭据
    DASHBOARD_USERNAME="supabase"  # 可以根据需要自定义
    DASHBOARD_PASSWORD=$(openssl rand -base64 24 | tr -d '\n')  # 生成强密码
    
    print_success "基础密钥生成完成"
}

# 生成 JWT tokens
generate_jwt_tokens() {
    if [ "$SKIP_JWT" = true ]; then
        print_warning "跳过 JWT token 生成"
        ANON_KEY="请在 https://jwt.io 手动生成"
        SERVICE_ROLE_KEY="请在 https://jwt.io 手动生成"
        return
    fi
    
    print_info "生成 JWT tokens..."
    
    # 检查是否已安装 jsonwebtoken
    if ! node -e "require('jsonwebtoken')" 2>/dev/null; then
        print_warning "正在安装 jsonwebtoken 包..."
        npm install jsonwebtoken --no-save --silent
    fi
    
    # 计算时间戳（当前时间和 5 年后）
    IAT=$(date +%s)
    EXP=$((IAT + 60 * 60 * 24 * 365 * 5))  # 5 年后过期
    
    # 生成 ANON_KEY
    ANON_KEY=$(node -e "
        const jwt = require('jsonwebtoken');
        const token = jwt.sign({
            role: 'anon',
            iss: 'supabase',
            iat: ${IAT},
            exp: ${EXP}
        }, '${JWT_SECRET}');
        console.log(token);
    ")
    
    # 生成 SERVICE_ROLE_KEY
    SERVICE_ROLE_KEY=$(node -e "
        const jwt = require('jsonwebtoken');
        const token = jwt.sign({
            role: 'service_role',
            iss: 'supabase',
            iat: ${IAT},
            exp: ${EXP}
        }, '${JWT_SECRET}');
        console.log(token);
    ")
    
    print_success "JWT tokens 生成完成"
}

# 显示生成的密钥
display_secrets() {
    echo ""
    print_info "=========================================="
    print_info "生成的密钥如下："
    print_info "=========================================="
    echo ""
    echo "POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}"
    echo "JWT_SECRET: ${JWT_SECRET}"
    echo "ANON_KEY: ${ANON_KEY}"
    echo "SERVICE_ROLE_KEY: ${SERVICE_ROLE_KEY}"
    echo "LOGFLARE_PUBLIC_ACCESS_TOKEN: ${LOGFLARE_PUBLIC_ACCESS_TOKEN}"
    echo "LOGFLARE_PRIVATE_ACCESS_TOKEN: ${LOGFLARE_PRIVATE_ACCESS_TOKEN}"
    echo "SECRET_KEY_BASE: ${SECRET_KEY_BASE}"
    echo "VAULT_ENC_KEY: ${VAULT_ENC_KEY}"
    echo "DASHBOARD_USERNAME: ${DASHBOARD_USERNAME}"
    echo "DASHBOARD_PASSWORD: ${DASHBOARD_PASSWORD}"
    echo ""
}

# 更新 lzc-deploy-params.yml 文件
update_deploy_params() {
    print_info "准备更新 lzc-deploy-params.yml..."
    
    if [ ! -f "lzc-deploy-params.yml" ]; then
        print_error "未找到 lzc-deploy-params.yml 文件"
        exit 1
    fi
    
    # 备份原文件
    cp lzc-deploy-params.yml lzc-deploy-params.yml.backup
    print_success "已备份原文件到 lzc-deploy-params.yml.backup"
    
    # 使用 sed 更新各个密钥
    sed -i.tmp "s|default_value: \".*\" # POSTGRES_PASSWORD|default_value: \"${POSTGRES_PASSWORD}\" # POSTGRES_PASSWORD|g" lzc-deploy-params.yml || \
        sed -i.tmp "/id: POSTGRES_PASSWORD/,/default_value:/ s|default_value: \".*\"|default_value: \"${POSTGRES_PASSWORD}\"|" lzc-deploy-params.yml
    
    sed -i.tmp "/id: JWT_SECRET/,/default_value:/ s|default_value: \".*\"|default_value: \"${JWT_SECRET}\"|" lzc-deploy-params.yml
    sed -i.tmp "/id: ANON_KEY/,/default_value:/ s|default_value: \".*\"|default_value: \"${ANON_KEY}\"|" lzc-deploy-params.yml
    sed -i.tmp "/id: SERVICE_ROLE_KEY/,/default_value:/ s|default_value: \".*\"|default_value: \"${SERVICE_ROLE_KEY}\"|" lzc-deploy-params.yml
    sed -i.tmp "/id: LOGFLARE_PUBLIC_ACCESS_TOKEN/,/default_value:/ s|default_value: \".*\"|default_value: \"${LOGFLARE_PUBLIC_ACCESS_TOKEN}\"|" lzc-deploy-params.yml
    sed -i.tmp "/id: LOGFLARE_PRIVATE_ACCESS_TOKEN/,/default_value:/ s|default_value: \".*\"|default_value: \"${LOGFLARE_PRIVATE_ACCESS_TOKEN}\"|" lzc-deploy-params.yml
    sed -i.tmp "/id: SECRET_KEY_BASE/,/default_value:/ s|default_value: \".*\"|default_value: \"${SECRET_KEY_BASE}\"|" lzc-deploy-params.yml
    sed -i.tmp "/id: VAULT_ENC_KEY/,/default_value:/ s|default_value: \".*\"|default_value: \"${VAULT_ENC_KEY}\"|" lzc-deploy-params.yml
    sed -i.tmp "/id: DASHBOARD_USERNAME/,/default_value:/ s|default_value: \".*\"|default_value: \"${DASHBOARD_USERNAME}\"|" lzc-deploy-params.yml
    sed -i.tmp "/id: DASHBOARD_PASSWORD/,/default_value:/ s|default_value: \".*\"|default_value: \"${DASHBOARD_PASSWORD}\"|" lzc-deploy-params.yml
    
    # 删除临时文件
    rm -f lzc-deploy-params.yml.tmp
    
    print_success "lzc-deploy-params.yml 更新完成"
}

# 保存到文件
save_to_file() {
    OUTPUT_FILE="supabase-secrets.txt"
    
    cat > "$OUTPUT_FILE" << EOF
# Supabase 密钥配置
# 生成时间: $(date)
# 注意：请妥善保管此文件，不要提交到版本控制系统

POSTGRES_PASSWORD="${POSTGRES_PASSWORD}"
JWT_SECRET="${JWT_SECRET}"
ANON_KEY="${ANON_KEY}"
SERVICE_ROLE_KEY="${SERVICE_ROLE_KEY}"
LOGFLARE_PUBLIC_ACCESS_TOKEN="${LOGFLARE_PUBLIC_ACCESS_TOKEN}"
LOGFLARE_PRIVATE_ACCESS_TOKEN="${LOGFLARE_PRIVATE_ACCESS_TOKEN}"
SECRET_KEY_BASE="${SECRET_KEY_BASE}"
VAULT_ENC_KEY="${VAULT_ENC_KEY}"
DASHBOARD_USERNAME="${DASHBOARD_USERNAME}"
DASHBOARD_PASSWORD="${DASHBOARD_PASSWORD}"

# 使用说明：
# 1. 这些密钥已自动更新到 lzc-deploy-params.yml
# 2. 部署时可以直接使用，或在 LazyCAT 安装界面自定义
# 3. 生产环境请确保使用强密钥并定期轮换
# 4. Kong Dashboard 访问地址：https://your-domain/ （使用上述 DASHBOARD_USERNAME 和 DASHBOARD_PASSWORD 登录）
EOF
    
    print_success "密钥已保存到 ${OUTPUT_FILE}"
}

# 主函数
main() {
    echo ""
    print_info "=========================================="
    print_info "  Supabase 密钥生成工具 for LazyCAT"
    print_info "=========================================="
    echo ""
    
    check_dependencies
    generate_secrets
    generate_jwt_tokens
    display_secrets
    
    # 检查是否为自动模式（通过环境变量 AUTO_UPDATE 控制）
    if [ "$AUTO_UPDATE" = "true" ]; then
        print_info "自动更新模式，直接更新配置文件"
        update_deploy_params
        save_to_file
    else
        # 询问是否更新文件
        read -p "是否自动更新 lzc-deploy-params.yml 文件？ (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            update_deploy_params
            save_to_file
        else
            print_info "已跳过文件更新，请手动复制上述密钥"
            save_to_file
        fi
    fi
    
    echo ""
    print_success "=========================================="
    print_success "  密钥生成完成！"
    print_success "=========================================="
    echo ""
    
    if [ "$SKIP_JWT" = true ]; then
        print_warning "请访问 https://jwt.io 手动生成 JWT tokens："
        echo ""
        echo "1. Payload 设置为："
        echo "   {"
        echo "     \"role\": \"anon\",  // 或 \"service_role\""
        echo "     \"iss\": \"supabase\","
        echo "     \"iat\": $(date +%s),"
        echo "     \"exp\": $(($(date +%s) + 60 * 60 * 24 * 365 * 5))"
        echo "   }"
        echo ""
        echo "2. 在 VERIFY SIGNATURE 部分粘贴上面生成的 JWT_SECRET"
        echo "3. 复制生成的 token 更新到 lzc-deploy-params.yml"
        echo ""
    fi
    
    print_info "下一步："
    echo "  1. 检查 lzc-deploy-params.yml 中的密钥"
    echo "  2. 运行: lzc-cli project build"
    echo "  3. 部署到 LazyCAT 平台"
    echo ""
}

# 执行主函数
main
