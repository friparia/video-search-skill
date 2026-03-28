#!/usr/bin/env python3
"""
BYR PT 搜索脚本
用法: ./byr_search.py <keyword>
"""
import sys
import os
import re
import json
import urllib.parse
from html import unescape

try:
    import requests
    from bs4 import BeautifulSoup
except ImportError:
    print(json.dumps({
        "items": [],
        "error": "missing_dependencies",
        "message": "需要安装 requests 和 beautifulsoup4: pip install requests beautifulsoup4"
    }, ensure_ascii=False, indent=2))
    sys.exit(1)


def load_env():
    """从 .env 文件加载环境变量"""
    env_file = "/home/misaka/bot/.env"
    env_vars = {}

    if os.path.exists(env_file):
        with open(env_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    # 移除引号
                    value = value.strip().strip('"').strip("'")
                    env_vars[key] = value

    return env_vars


def search_byr(keyword):
    """搜索 BYR PT"""
    env = load_env()
    byr_cookie = env.get('BYR_COOKIE', os.environ.get('BYR_COOKIE', ''))

    if not byr_cookie:
        return {
            "items": [],
            "error": "missing_cookie",
            "message": "缺少 BYR_COOKIE，请在 .env 文件中配置"
        }

    # URL 编码关键词
    encoded_keyword = urllib.parse.quote(keyword)
    search_url = f"https://byr.pt/torrents.php?incldead=0&spstate=0&inclbookmarked=0&search={encoded_keyword}&search_area=0&search_mode=0"

    # 发送请求
    headers = {
        'Cookie': byr_cookie,
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    }

    try:
        response = requests.get(search_url, headers=headers, verify=False, timeout=10)
        response.encoding = 'utf-8'
        html = response.text
    except Exception as e:
        return {
            "items": [],
            "error": "request_failed",
            "message": f"请求失败: {str(e)}"
        }

    # 检查是否被重定向到登录页
    if 'login.php' in html or '请先登录' in html:
        return {
            "items": [],
            "error": "cookie_expired",
            "message": "BYR PT Cookie 已过期，请重新登录并更新 Cookie"
        }

    # 解析 HTML
    soup = BeautifulSoup(html, 'html.parser')
    results = []

    # 查找搜索结果表格
    torrent_table = soup.find('table', class_='torrents')
    if not torrent_table:
        torrent_table = soup.find('table', id_='torrents')

    if torrent_table:
        tbody = torrent_table.find('tbody')
        if tbody:
            rows = tbody.find_all('tr')
        else:
            rows = torrent_table.find_all('tr')[1:]  # 跳过表头
    else:
        # 备用方案：查找所有有 title 属性的 details.php 链接
        rows = soup.find_all('a', href=re.compile(r'details\.php\?id=\d+'), title=True)

    for row in rows:
        try:
            if row.name != 'tr':
                continue

            cells = row.find_all('td')
            if len(cells) < 11:
                continue

            # 提取标题和ID（第5列，索引4）
            title_link = cells[4].find('a', href=re.compile(r'details\.php\?id=\d+'))
            if not title_link:
                continue

            title = unescape(title_link.get('title', '') or title_link.get_text(strip=True))
            if not title:
                continue

            id_match = re.search(r'id=(\d+)', title_link.get('href', ''))
            if not id_match:
                continue
            torrent_id = id_match.group(1)

            # 提取大小（第10列，索引9）
            size = 'Unknown'
            if len(cells) > 9:
                size_cell = cells[9]
                size_text = size_cell.get_text(strip=True)
                # 清理格式：4.35GiB -> 4.35 GB
                if re.search(r'\d+\s*(KB|MB|GB|TB|KiB|MiB|GiB|TiB)', size_text, re.IGNORECASE):
                    size = size_text.replace('GiB', 'GB').replace('MiB', 'MB').replace('KiB', 'KB').replace('TiB', 'TB')

            # 提取做种人数（第11列，索引10）
            seeders = '0'
            if len(cells) > 10:
                seeder_cell = cells[10]
                # 找到 <b> 或 <a> 标签内的数字
                b_tag = seeder_cell.find('b')
                if b_tag:
                    seeder_text = b_tag.get_text(strip=True)
                    a_tag = b_tag.find('a')
                    if a_tag:
                        seeder_text = a_tag.get_text(strip=True)
                else:
                    seeder_text = seeder_cell.get_text(strip=True)
                if seeder_text.isdigit():
                    seeders = seeder_text

            results.append({
                'title': title,
                'id': torrent_id,
                'size': size,
                'seeders': seeders
            })
        except Exception as e:
            continue

    return {'items': results}


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(json.dumps({
            "items": [],
            "error": "missing_keyword",
            "message": "用法: python byr_search.py <keyword>"
        }, ensure_ascii=False, indent=2))
        sys.exit(1)

    keyword = sys.argv[1]
    result = search_byr(keyword)
    print(json.dumps(result, ensure_ascii=False, indent=2))
