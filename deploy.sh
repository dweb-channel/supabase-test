#!/bin/bash

# Supabase 部署到懒猫微服平台的脚本
# 用于自动化部署流程

echo "🚀 开始部署 Supabase 到懒猫微服平台..."

# 1. 检查必要文件是否存在
echo "📋 检查必要文件..."

files_to_check=(
    "lzc-manifest.yml"
    "lzc-build.yml"
    "volumes/api/kong.yml"
    "volumes/logs/vector.toml"
    "volumes/functions/main/index.ts"
    "volumes/pooler/pooler.exs"
)

for file in "${files_to_check[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ 缺少文件: $file"
        exit 1
    fi
done

echo "✅ 所有必要文件都存在"

# 2. 确保 vector 配置文件名正确
if [ -f "volumes/logs/vector.yml" ] && [ ! -f "volumes/logs/vector.toml" ]; then
    echo "📝 复制 vector 配置文件..."
    cp volumes/logs/vector.yml volumes/logs/vector.toml
fi

# 3. 构建 LPK 包
echo "🏗️ 构建 LPK 包..."
lzc build

if [ $? -ne 0 ]; then
    echo "❌ 构建失败"
    exit 1
fi

echo "✅ 构建成功"

# 4. 部署应用
echo "📦 部署应用到懒猫微服..."
echo "提示：你可以使用以下命令进行部署："
echo ""
echo "  lzc-cli project devshell  # 进入开发环境"
echo ""
echo "或者通过懒猫微服管理面板上传 .lpk 文件"

# 5. 显示访问信息
echo ""
echo "🎉 部署准备完成！"
echo ""
echo "📌 部署后访问信息："
echo "  - Supabase Studio: https://supabase.<your-domain>.heiyu.space"
echo "  - API Endpoint: https://supabase.<your-domain>.heiyu.space/rest/v1/"
echo "  - Realtime: wss://supabase.<your-domain>.heiyu.space/realtime/v1/"
echo ""
echo "⚠️ 注意事项："
echo "  1. 首次部署可能需要等待数据库初始化完成（约1-2分钟）"
echo "  2. 如果遇到连接错误，请检查服务日志"
echo "  3. 确保所有环境变量已正确配置"
