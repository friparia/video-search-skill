# 智能媒体搜索 Skill

这个 skill 提供**智能双源搜索**：优先查询本地 Jellyfin 媒体库，如果没有找到则自动搜索 BYR PT 站点。

## 安装

1. 将此 skill 目录复制到你的 Claude skills 目录
2. 配置 Jellyfin 连接信息
3. （可选）配置 BYR Cookie 以启用 PT 站点搜索

## 配置

在项目根目录创建 `config.json` 文件：

```json
{
  "jellyfin": {
    "url": "http://localhost:8096",
    "apiKey": "your-api-key-here"
  },
  "byr": {
    "cookie": "session_id=xxx; auth_token=yyy"
  }
}
```

### 获取 Jellyfin API Key

1. 登录 Jellyfin Web 界面
2. 点击右上角用户图标 → 设置
3. 选择 "API 密钥"
4. 点击 "+" 添加新的 API 密钥
5. 复制生成的密钥到配置文件

### 获取 BYR Cookie（可选）

1. 登录 https://byr.pt
2. 打开浏览器开发者工具（F12）→ Application → Cookies → byr.pt
3. 复制 `session_id` 和 `auth_token` 的值
4. 组合格式：`session_id=值1; auth_token=值2`

**重要**：
- Jellyfin 配置是必需的
- BYR 配置是可选的（如果不配置则只搜索本地）

## 使用方法

在 Claude 中询问：

**本地资源查询**：
- "有没有电影 '星际穿越'？"
- "搜索电视剧 '黑镜'"
- "小猪佩奇有几季？"
- "老友记的剧集全吗？"

**组合搜索**（本地没有则自动搜索 PT）：
- "找找 '沙丘 2'"
- "有没有 '三体' 电视剧"

## 工作原理

**本地优先，远程兜底**：

```
用户搜索请求
    ↓
1. 搜索本地 Jellyfin 媒体库
    ↓
2. 如果找到 → 显示本地资源
    ↓
3. 如果没找到 → 搜索 BYR PT 站点
    ↓
4. 显示 PT 搜索结果（含下载链接）
```

## 功能特性

- ✅ **本地搜索**：查询 Jellyfin 媒体库中的电影和电视剧
- ✅ **PT 搜索**：本地没有时自动搜索 BYR 站点
- ✅ **季数查询**：查看电视剧有几季
- ✅ **完整性检查**：检查某季的剧集是否完整
- ✅ **友好输出**：使用表情符号和格式化文本，便于聊天展示

## 注意事项

- Jellyfin 服务器需要可访问
- API Key 需要有足够的权限（通常需要用户级别权限）
- BYR Cookie 可能会过期，搜索失败时需要重新获取
- 电视剧季数/集数查询只针对本地资源（PT 资源按种子发布，不适合统计）
