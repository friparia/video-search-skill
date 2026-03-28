# BYR Cookie 获取指南

## 获取完整 Cookie（推荐）

### 方法1：从 Network 请求中复制

1. 打开 https://byr.pt 并登录
2. 按 F12 打开开发者工具
3. 切换到 **Network** 标签
4. 在网站上随便点一个链接（比如搜索）
5. 在 Network 列表中找到任意请求
6. 点击该请求 → 右侧切换到 **Headers** 标签
7. 找到 **Request Headers** 部分的 `Cookie:` 字段
8. 复制整个 Cookie 值（完整的一行）

示例：
```
Cookie: session_id=xxxxx-xxxx-xxxx-xxxx; pass=yyyyy; c_lang=en
```

### 方法2：使用浏览器开发者工具

1. 打开 Chrome 浏览器
2. 访问 https://byr.pt 并登录
3. 按 F12 打开开发者工具
4. 切换到 **Application** 标签（Chrome）或 **Storage** 标签（Firefox）
5. 在左侧找到 **Cookies** → 展开 → 点击 `https://byr.pt`
6. 手动组合 Cookie：`session_id=值1; pass=值2; c_lang=en`

## 配置到环境变量

将复制的 Cookie 设置到环境变量：

```bash
export BYR_COOKIE="session_id=xxxxx; pass=yyyyy; c_lang=en"
```

或者在 `.env` 文件中：

```
BYR_COOKIE=session_id=xxxxx; pass=yyyyy; c_lang=en
```
  }
}
```

## 注意事项

- **需要同时配置 `session_id` 和 `auth_token`**，缺少任何一个都会导致搜索失败
- `auth_token` 是 JWT 格式，可能会过期（通常有效期较长）
- `session_id` 也会过期，需要定期重新获取
- 如果 PT 搜索失败，可能需要重新登录并重新获取这两个值
- Cookie 是敏感信息，请勿泄露给他人
