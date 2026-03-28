---
name: video-search
description: 智能媒体搜索 - 结合本地 Jellyfin 媒体库和 BYR PT 站点进行搜索。优先查询本地 Jellyfin，如果没有找到则自动搜索 BYR。支持查询电影和电视剧信息、检查媒体是否存在、查询电视剧季数和剧集完整性。当用户询问"有没有XX电影/电视剧"、"搜索XX"、"XXX有几季"、"剧集是否完整"等问题时使用此 skill。
---

# 智能媒体搜索

这个 skill 提供智能媒体搜索功能：**优先查询本地 Jellyfin 媒体库，如果没有找到则自动在 PT 网站搜索**。

## 配置

通过环境变量配置：

**必需环境变量**：
```bash
export JELLYFIN_URL="http://your-jellyfin-server"
export JELLYFIN_API_KEY="your-jellyfin-api-key"
```

**可选环境变量**（用于 PT 网站搜索）：
```bash
export BYR_COOKIE="session_id=xxx; auth_token=yyy"
```

**配置说明**：
- `JELLYFIN_URL`: Jellyfin 服务器地址（可以带或不带尾部斜杠）
- `JELLYFIN_API_KEY`: Jellyfin API 密钥（在 Jellyfin 设置中生成）
- `BYR_COOKIE`: BYR（北邮人PT）的完整 cookie 字符串

**获取 BYR Cookie**：
1. 登录 https://byr.pt
2. 打开浏览器开发者工具（F12）→ Application → Cookies → byr.pt
3. 复制 `session_id` 和 `auth_token` 的值
4. 组合格式：`session_id=值1; auth_token=值2`

**重要**：
- Jellyfin 配置是必需的（本地搜索）
- BYR 配置是可选的（远程搜索，如果没有配置则只搜索本地）
- 如果配置文件不存在或字段为空，返回友好的错误提示

## 工作流程

### 核心逻辑：本地优先，远程兜底

当用户问"有没有XX"时：

```
1. 搜索本地 Jellyfin 媒体库
   ↓
2. 如果找到结果 → 显示本地资源
   ↓
3. 如果没找到 → 搜索 BYR PT 网站
   ↓
4. 显示 PT 搜索结果（包含下载链接）
```

### 场景1：检查媒体是否存在（"有没有XX"）

**示例：用户问"有没有盗梦空间？"**

#### 步骤1：本地搜索

```bash
# 搜索本地 Jellyfin
keyword="盗梦空间"
encoded_keyword=$(echo -n "$keyword" | jq -sRr @uri)
curl -s -H "X-MediaBrowser-Token: ${apiKey}" \
  "${jellyfinUrl}/Users/${userId}/Items?searchTerm=${encoded_keyword}&IncludeItemTypes=Movie,Series"
```

- 如果找到结果 → 显示本地媒体信息
- 如果没找到 → 继续步骤2

#### 步骤2：远程搜索（如果本地没找到）

```bash
# 搜索 BYR PT
./scripts/byr-search.sh config.json "盗梦空间" "1"  # 1=电影
```

#### 输出格式

**本地找到**：
```
✅ 找到了！（本地）

📽️ 盗梦空间 (2010)
   类型: 科幻 / 悬疑 / 动作
   评分: ⭐ 8.8
   时长: 148 分钟
   简介: 一名神偷拥有潜入他人梦境窃取机密的能力...
```

**本地没有，PT 找到**：
```
❌ 本地没有找到"盗梦空间"

🔍 在 PT 网站找到了以下资源：

📦 [电影] 盗梦空间 Inception (2010)
   大小: 4.37 GB
   完成数: 1523

📦 [电影] 盗梦空间 1080P 中英双字
   大小: 8.12 GB
   完成数: 892
```

**都没找到**：
```
❌ 本地和 PT 网站都没有找到"盗梦空间"

💡 建议：
   - 检查关键词是否正确
   - 尝试使用英文名搜索
   - 尝试搜索其他 PT 网站
```

### 场景2：查询电视剧季数和集数

**只查询本地 Jellyfin**（PT 网站通常按资源发布，不适合统计季数）

**示例：用户问"小猪佩奇有几季？"**

1. 先搜索本地获取电视剧 ID
2. 调用 jellyfin-api.sh 的 `seasons` 命令获取所有季
3. 对每一季调用 `episodes` 命令获取集数
4. 检查集号是否连续

**输出格式**：
```
📺 小猪佩奇（本地）

共有 7 季：
- 第1季：52集 ✅ 完整
- 第2季：52集 ✅ 完整
- 第3季：52集 ✅ 完整
- 第4季：52集 ✅ 完整
- 第5季：52集 ✅ 完整
- 第6季：52集 ✅ 完整
- 第7季：48集 ✅ 完整

总计：312 集
```

### 场景3：检查剧集完整性

**示例：用户问"老友记的剧集全吗？"**

输出格式：
```
📺 老友记（本地）

共有 10 季：
- 第1季：24集 ✅ 完整
- 第2季：24集 ✅ 完整
- 第3季：25集 ✅ 完整
- 第4季：24集 ✅ 完整
- 第5季：24集 ✅ 完整
- 第6季：25集 ✅ 完整
- 第7季：24集 ✅ 完整
- 第8季：24集 ✅ 完整
- 第9季：24集 ✅ 完整
- 第10季：18集 ✅ 完整

✅ 所有季的剧集都是完整的！
总计：236 集
```

或如果有缺失：
```
⚠️ 部分剧集不完整：

- 第5季：应有 24 集，实际 20 集 ❌ 缺少第 3、7、12、18 集
- 第8季：应有 24 集，实际 22 集 ❌ 缺少第 5、15 集
```

## Jellyfin API 基础

Jellyfin 提供 HTTP API 接口。主要端点：

- **搜索**: `GET /Users/{userId}/Items`
  - 查询参数: `searchTerm`（搜索关键词）、`IncludeItemTypes`（Movie,Series）
  - 返回匹配的媒体项列表

- **获取用户ID**: `GET /Users`
  - 返回服务器上的用户列表，取第一个用户的ID

- **获取媒体详情**: `GET /Users/{userId}/Items/{itemId}`
  - 返回单个媒体的完整信息

- **获取季信息**: `GET /Users/{userId}/Items?ParentId={seriesId}&IncludeItemTypes=Season`
  - 返回电视剧的所有季

- **获取剧集**: `GET /Users/{userId}/Items?ParentId={seasonId}&IncludeItemTypes=Episode`
  - 返回某一季的所有剧集

所有请求需要携带 Header: `X-MediaBrowser-Token: {apiKey}`

## BYR PT 搜索脚本

脚本位置：`scripts/byr-search.sh`

**用法**：
```bash
./byr-search.sh <config_path> <keyword> [type]
```

**参数**：
- `config_path`: 配置文件路径
- `keyword`: 搜索关键词
- `type`: 媒体类型（可选）
  - `0` 或不传：全部
  - `1`: 电影（cat=408）
  - `2`: 电视剧（cat=401）
  - `3`: 纪录片（cat=410）
  - `5`: 综艺（cat=404）
  - `6`: 动画（cat=404）

**返回格式**（JSON）：
```json
{
  "items": [
    {
      "title": "电影标题",
      "id": "torrent_id",
      "size": "4.37 GB",
      "uploader": "上传者名称",
      "finish": "1523"
    }
  ]
}
```

**下载链接格式**：
```
https://byr.pt/torrents.php?action=download&id={torrent_id}
```

## 输出格式规范

使用友好的文本格式，包含表情符号，便于微信等聊天平台展示：

### 搜索结果
```
🎬 搜索结果: "关键词"

📽️ 电影名称 (2024)
   类型: 动作 / 科幻
   评分: ⭐ 8.5
   简介: 影片剧情简介...

找到共 2 个结果
```

### PT 搜索结果
```
🔍 PT 搜索结果: "关键词"

📦 [类型] 标题
   大小: XX GB
   上传者: xxx
   完成数: 1523
   下载: https://byr.pt/torrents.php?action=download&id=123456
```

## 错误处理

常见错误及处理方式：

### Jellyfin 错误
- **连接失败**: 检查服务器地址是否正确，Jellyfin 是否运行
- **认证失败**: API Key 可能无效，提示用户检查配置
- **无结果**: 继续搜索 PT 网站或提示未找到

### BYR PT 错误
- **Cookie 失效**: auth_token 过期，提示用户重新登录获取
- **连接失败**: 检查网络连接，BYR 网站是否可访问
- **无结果**: 友好提示 PT 网站也没有找到

## 检测剧集完整性的逻辑

对每一季：
1. 获取所有剧集列表
2. 提取每集的 `IndexNumber`（集号）
3. 排序后检查：
   - 最小值应该是 1
   - 最大值应该是剧集总数
   - 检查中间是否有缺失的数字

示例代码逻辑：
```bash
# 获取剧集列表并检查完整性
episodes=$(获取剧集JSON)
episode_numbers=$(echo "$episodes" | jq -r '.Items[].IndexNumber' | sort -n)

# 检查是否连续
expected=1
missing=()
for num in $episode_numbers; do
  if [ "$num" -ne "$expected" ]; then
    missing+=("$expected")
  fi
  expected=$((num + 1))
done

if [ ${#missing[@]} -gt 0 ]; then
  echo "缺失第 ${missing[@]} 集"
fi
```

## 注意事项

- 用户输入的关键词需要进行 URL 编码
- 本地搜索结果限制显示前 10 个最相关的结果
- PT 搜索结果显示前 5 个资源（按完成数排序）
- 媒体类型区分：Movie（电影）、Series（电视剧）、Episode（剧集单集）
- BYR Cookie 可能会过期，如果搜索失败提示用户重新获取
- 对于电视剧季数查询，只查询本地（PT 资源按种子发布，不适合统计）
- 如果用户没有配置 BYR Cookie，只进行本地搜索
