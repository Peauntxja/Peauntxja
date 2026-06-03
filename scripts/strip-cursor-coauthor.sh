#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --msg-filter \
  "grep -v '^Co-authored-by: Cursor <cursoragent@cursor.com>\$'" \
  -- --all
echo "完成。请执行: git push --force-with-lease origin main"
