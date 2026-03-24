#!/usr/bin/env bash
# 将 ./snake-dist/ 下的两个 SVG 推送到 origin 的 output 分支
# 使用前请先运行: ./scripts/generate-snake-local.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

for f in github-contribution-grid-snake.svg github-contribution-grid-snake-dark.svg; do
  if [[ ! -f "snake-dist/$f" ]]; then
    echo "错误: 缺少 snake-dist/$f，请先运行 scripts/generate-snake-local.sh" >&2
    exit 1
  fi
done

CURRENT="$(git branch --show-current)"
REMOTE="${1:-origin}"

read -r -p "将用本地 snake-dist 覆盖远程 ${REMOTE} 的 output 分支，是否继续? [y/N] " ok
[[ "${ok:-}" == "y" || "${ok:-}" == "Y" ]] || { echo "已取消"; exit 0; }

git fetch "$REMOTE" 2>/dev/null || true

if git show-ref --verify --quiet "refs/heads/output"; then
  git checkout output
  git rm -rf . >/dev/null 2>&1 || true
else
  git checkout --orphan output
  git rm -rf . >/dev/null 2>&1 || true
fi

# 工作区仅保留两个 SVG；勿删除未跟踪的 snake-dist/（生成目录）
shopt -s dotglob nullglob
for p in ./*; do
  [[ "$p" == "./.git" ]] && continue
  [[ "$p" == "./snake-dist" ]] && continue
  rm -rf "$p"
done
shopt -u dotglob

cp -f "$REPO_ROOT/snake-dist/github-contribution-grid-snake.svg" .
cp -f "$REPO_ROOT/snake-dist/github-contribution-grid-snake-dark.svg" .

git add github-contribution-grid-snake.svg github-contribution-grid-snake-dark.svg
if git diff --staged --quiet 2>/dev/null; then
  echo "无变更，跳过提交。"
else
  git commit -m "chore: 更新贡献蛇 SVG（本地生成）"
fi

git push -u "$REMOTE" output --force

git checkout "$CURRENT"

echo "完成。请在 README 中恢复指向 output 分支的 <picture> 蛇图块。"
