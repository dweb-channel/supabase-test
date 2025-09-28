#!/bin/sh

# 执行 setupscript 脚本
SETUPSCRIPT=/lzcapp/pkg/content/devshell/setupscript
if [ -f $SETUPSCRIPT ];then
    . $SETUPSCRIPT
fi

set -e

# 切换目录
mkdir -p /lzcapp/cache/devshell
cd /lzcapp/cache/devshell
exec /bin/sh
