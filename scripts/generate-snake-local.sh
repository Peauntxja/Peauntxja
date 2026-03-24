#!/usr/bin/env bash
# 本地生成贡献蛇 SVG（与 .github/workflows/snake.yml 中 Platane/snk/svg-only 输出一致）
# 依赖：Node.js >= 18（推荐 20+）、curl、tar
# 认证：必须设置 GITHUB_TOKEN（匿名请求易被 API 限流导致 fetch failed）
#   export GITHUB_TOKEN="$(gh auth token)"   # 已登录 gh CLI 时
#   或在 https://github.com/settings/tokens 创建 Fine-grained / classic PAT，勾选 read-only 用户资料与贡献图所需权限
#
# 用法：在仓库根目录执行
#   chmod +x scripts/generate-snake-local.sh
#   export GITHUB_TOKEN="$(gh auth token)"
#   ./scripts/generate-snake-local.sh
# 生成结果在 ./snake-dist/，再按 README 中说明推送到 output 分支

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SNK_VERSION="${SNK_VERSION:-main}"
CACHE_DIR="$REPO_ROOT/.snk-cache"
SNK_ROOT="$CACHE_DIR/snk-src"
OUT_DIR="$REPO_ROOT/snake-dist"
USER_NAME="${GITHUB_USER_NAME:-Peauntxja}"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "错误: 请设置环境变量 GITHUB_TOKEN（例如: export GITHUB_TOKEN=\"\$(gh auth token)\"）" >&2
  echo "未认证的 GitHub API 容易触发 rate limit，snk 会报 fetch failed。" >&2
  exit 1
fi

node_ok() {
  local bin="$1"
  local major
  major="$("$bin" -p "parseInt(process.version.slice(1), 10)" 2>/dev/null || echo 0)"
  [[ "$major" -ge 18 ]]
}

resolve_node() {
  local bin d
  if command -v node >/dev/null 2>&1; then
    bin="$(command -v node)"
    if node_ok "$bin"; then echo "$bin"; return 0; fi
  fi
  for d in "$HOME/.local/share/fnm/node-versions"/v*/installation/bin; do
    bin="$d/node"
    [[ -x "$bin" ]] && node_ok "$bin" && echo "$bin" && return 0
  done
  for d in "$HOME/.nvm/versions/node"/v*/bin; do
    bin="$d/node"
    [[ -x "$bin" ]] && node_ok "$bin" && echo "$bin" && return 0
  done
  echo "错误: 未找到 Node >= 18。请安装 Node 20+ 或使用 nvm/fnm 切换版本。" >&2
  exit 1
}

NODE_BIN="$(resolve_node)"
echo "使用 Node: $($NODE_BIN -v) ($NODE_BIN)"

if [[ ! -f "$SNK_ROOT/svg-only/dist/index.js" ]]; then
  echo "下载 Platane/snk (${SNK_VERSION})…"
  mkdir -p "$CACHE_DIR"
  rm -rf "$SNK_ROOT"
  curl -fsSL "https://github.com/Platane/snk/archive/refs/heads/${SNK_VERSION}.tar.gz" | tar xz -C "$CACHE_DIR"
  mv "$CACHE_DIR/snk-${SNK_VERSION}" "$SNK_ROOT"
fi

mkdir -p "$OUT_DIR"
cd "$SNK_ROOT/svg-only"
mkdir -p dist

export INPUT_GITHUB_USER_NAME="$USER_NAME"
export INPUT_GITHUB_TOKEN="$GITHUB_TOKEN"
export INPUT_OUTPUTS="dist/github-contribution-grid-snake.svg
dist/github-contribution-grid-snake-dark.svg?palette=github-dark"

"$NODE_BIN" dist/index.js

cp -f dist/github-contribution-grid-snake.svg "$OUT_DIR/"
cp -f dist/github-contribution-grid-snake-dark.svg "$OUT_DIR/"

echo
echo "已生成:"
echo "  $OUT_DIR/github-contribution-grid-snake.svg"
echo "  $OUT_DIR/github-contribution-grid-snake-dark.svg"
echo
echo "下一步: 推送到远程 output 分支（见仓库 README「贡献蛇」小节或 scripts/push-snake-output.sh）"
