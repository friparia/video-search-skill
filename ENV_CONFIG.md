# 视频搜索和下载 - 环境变量配置

## 必需的环境变量

### Jellyfin（本地视频搜索）
```bash
export JELLYFIN_URL="http://"
export JELLYFIN_API_KEY="your-jellyfin-api-key"
```

### BYR PT（视频搜索和下载）
```bash
# 直接从浏览器复制完整的 Cookie 字符串
export BYR_COOKIE="session_id=xxxxx; pass=yyyyy; c_lang=en"
```

### Transmission（下载）
```bash
export TRANSMISSION_HOST="192.168.10.2"
export TRANSMISSION_PORT="9091"
export TRANSMISSION_USER=""  # 如果需要认证
export TRANSMISSION_PASSWORD=""  # 如果需要认证
```

## 设置方式

参考项目根目录的 `.env.example` 文件。

## 验证配置

```bash
# 测试 Jellyfin 连接
curl -H "X-MediaBrowser-Token: $JELLYFIN_API_KEY" $JELLYFIN_URL/Users

# 测试 BYR 连接
curl -I -H "Cookie: $BYR_COOKIE" https://byr.pt/torrents.php

# 测试 Transmission 连接
curl -I http://$TRANSMISSION_HOST:$TRANSMISSION_PORT/transmission/rpc
```
