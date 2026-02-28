#!/bin/bash
# 清理所有 git_repos 下的 example 目录，防止构建服务器误扫
find git_repos -name "example" -type d -exec rm -rf {} +
echo "所有示例目录已清理喵awa"
