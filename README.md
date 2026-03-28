# Jellyfin 搜索 Skill

这个 skill 允许从 Jellyfin 媒体服务器搜索电影和电视剧。

## 安装

1. 将此 skill 目录复制到你的 Claude skills 目录
2. 配置 Jellyfin 连接信息

## 配置

在项目根目录创建 `config.json` 文件：

```json
{
  "jellyfin": {
    "url": "http://localhost:8096",
    "apiKey": "your-api-key-here"
  }
}
```

### 获取 Jellyfin API Key

1. 登录 Jellyfin Web 界面
2. 点击右上角用户图标 → 设置
3. 选择 "API 密钥"
4. 点击 "+" 添加新的 API 密钥
5. 复制生成的密钥到配置文件

## 使用方法

在 Claude 中询问：

- "搜索电影 '星际穿越'"
- "找电视剧 '黑镜'"
- "Jellyfin 里有什么动作片？"

## 测试

运行测试用例：

```bash
# 确保配置文件存在并包含有效的 API Key
claude -s jellyfin-search "搜索电影'泰坦尼克号'"
```

## 工作原理

1. 从 `config.json` 读取 Jellyfin 服务器配置
2. 调用 Jellyfin API 搜索匹配的媒体项
3. 格式化结果为易读的文本
4. 包含海报图片URL（如果有）

## 注意事项

- 确保 Jellyfin 服务器可访问
- API Key 需要有足够的权限（通常需要用户级别权限）
- 搜索关键词会自动进行 URL 编码
