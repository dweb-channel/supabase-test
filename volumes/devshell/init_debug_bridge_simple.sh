#!/bin/sh
# 简化版调试桥接脚本

echo "Supabase Debug Bridge - Simple Version"
echo "Current time: $(date)"
echo "Working directory: $(pwd)"

# 基本信息输出
echo "Supabase services should be accessible at:"
echo "- Main UI: http://localhost:8000"
echo "- Kong Admin: http://localhost:8443/kong/"
echo "- Analytics: http://localhost:4000/analytics/"

echo "Debug bridge initialization completed successfully"
exit 0
