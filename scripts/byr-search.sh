#!/bin/bash
# BYR PT 搜索脚本
# 用法: ./byr-search.sh <keyword>

KEYWORD="$1"

# 从环境变量读取配置
BYR_COOKIE="${BYR_COOKIE:-}"

if [ -z "$BYR_COOKIE" ]; then
  echo '{"items": [], "error": "缺少环境变量: BYR_COOKIE"}'
  exit 1
fi

# 从 Cookie 中提取 session_id（如果格式是 "session_id=xxx; auth_token=yyy"）
if [[ "$BYR_COOKIE" =~ session_id=([^;]+) ]]; then
  BYR_SESSION_ID="${BASH_REMATCH[1]}"
else
  # 如果 Cookie 格式不对，尝试使用整串作为 session_id
  BYR_SESSION_ID="$BYR_COOKIE"
fi

# URL 编码关键词
ENCODED_KEYWORD=$(echo -n "$KEYWORD" | jq -sRr @uri)

# 构建搜索 URL（搜索所有分类）
SEARCH_URL="https://byr.pt/torrents.php?incldead=0&spstate=0&inclbookmarked=0&search=${ENCODED_KEYWORD}&search_area=0&search_mode=0"

# 发送请求
HTML=$(curl -s -k \
  -H "Cookie: ${BYR_COOKIE}" \
  "$SEARCH_URL")

# 解析 HTML
# 使用 BeautifulSoup 解析 HTML
echo "$HTML" | python3 -c "
import sys
import re
from html import unescape
from bs4 import BeautifulSoup

html = sys.stdin.read()

soup = BeautifulSoup(html, 'html.parser')

results = []

# 查找所有有 title 属性的 details.php 链接
# 这些链接的 title 属性包含了完整的资源标题
details_links = soup.find_all('a', href=re.compile(r'details\.php\?id=\d+'), title=True)

for link in details_links:
    try:
        # 提取标题
        title = unescape(link.get('title', ''))
        if not title or title == '':
            continue

        # 提取 ID
        id_match = re.search(r'id=(\d+)', link.get('href', ''))
        if not id_match:
            continue
        torrent_id = id_match.group(1)

        # 暂时设为未知，后续可以优化
        size = 'Unknown'
        uploader = 'Unknown'
        finish = '0'

        results.append({
            'title': title,
            'id': torrent_id,
            'size': size,
            'uploader': uploader,
            'finish': finish
        })
    except Exception as e:
        continue

# 输出 JSON
import json
print(json.dumps({'items': results}, ensure_ascii=False, indent=2))
"
