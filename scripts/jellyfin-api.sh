#!/bin/bash
# Jellyfin API 辅助脚本
# 用法: ./scripts/jellyfin-api.sh <action> [args]

ACTION="$1"
shift 1

# 从环境变量读取配置
JELLYFIN_URL="${JELLYFIN_URL:-}"
API_KEY="${JELLYFIN_API_KEY:-}"

if [ -z "$JELLYFIN_URL" ]; then
  echo "错误: 缺少环境变量 JELLYFIN_URL"
  exit 1
fi

if [ -z "$API_KEY" ]; then
  echo "错误: 缺少环境变量 JELLYFIN_API_KEY"
  exit 1
fi

# 获取用户ID
get_user_id() {
  curl -s -H "X-MediaBrowser-Token: $API_KEY" "$JELLYFIN_URL/Users" | jq -r '.[0].Id'
}

# 搜索媒体
search_items() {
  local keyword="$1"
  local user_id=$(get_user_id)

  if [ -z "$user_id" ]; then
    echo "错误: 无法获取用户ID"
    exit 1
  fi

  # URL 编码关键词
  local encoded_keyword=$(echo -n "$keyword" | jq -sRr @uri)

  curl -s -H "X-MediaBrowser-Token: $API_KEY" \
    "$JELLYFIN_URL/Users/$user_id/Items?searchTerm=$encoded_keyword&IncludeItemTypes=Movie,Series"
}

# 获取媒体详情
get_item() {
  local item_id="$1"
  local user_id=$(get_user_id)

  if [ -z "$user_id" ]; then
    echo "错误: 无法获取用户ID"
    exit 1
  fi

  curl -s -H "X-MediaBrowser-Token: $API_KEY" \
    "$JELLYFIN_URL/Users/$user_id/Items/$item_id"
}

# 获取电视剧的季信息
get_seasons() {
  local series_id="$1"
  local user_id=$(get_user_id)

  if [ -z "$user_id" ]; then
    echo "错误: 无法获取用户ID"
    exit 1
  fi

  curl -s -H "X-MediaBrowser-Token: $API_KEY" \
    "$JELLYFIN_URL/Users/$user_id/Items?ParentId=$series_id&IncludeItemTypes=Season&SortBy=SortName"
}

# 获取某一季的所有剧集
get_episodes() {
  local season_id="$1"
  local user_id=$(get_user_id)

  if [ -z "$user_id" ]; then
    echo "错误: 无法获取用户ID"
    exit 1
  fi

  curl -s -H "X-MediaBrowser-Token: $API_KEY" \
    "$JELLYFIN_URL/Users/$user_id/Items?ParentId=$season_id&IncludeItemTypes=Episode&SortBy=SortName"
}

# 检查媒体是否存在
check_exists() {
  local keyword="$1"
  local media_type="$2"  # Movie, Series, or empty for both

  local user_id=$(get_user_id)
  if [ -z "$user_id" ]; then
    echo "错误: 无法获取用户ID"
    exit 1
  fi

  local encoded_keyword=$(echo -n "$keyword" | jq -sRr @uri)
  local type_param=""
  if [ -n "$media_type" ]; then
    type_param="&IncludeItemTypes=$media_type"
  fi

  curl -s -H "X-MediaBrowser-Token: $API_KEY" \
    "$JELLYFIN_URL/Users/$user_id/Items?searchTerm=$encoded_keyword${type_param}"
}

# 执行请求
case "$ACTION" in
  search)
    search_items "$@"
    ;;
  get)
    get_item "$@"
    ;;
  user-id)
    get_user_id
    ;;
  seasons)
    get_seasons "$@"
    ;;
  episodes)
    get_episodes "$@"
    ;;
  check)
    check_exists "$@"
    ;;
  *)
    echo "用法: $0 <search|get|user-id|seasons|episodes|check> [args]"
    echo "示例:"
    echo "  $0 search \"星际穿越\""
    echo "  $0 get \"abc123-item-id\""
    echo "  $0 user-id"
    echo "  $0 seasons \"series-id\""
    echo "  $0 episodes \"season-id\""
    echo "  $0 check \"小猪佩奇\""
    echo "  $0 check \"小猪佩奇\" \"Series\""
    exit 1
    ;;
esac
