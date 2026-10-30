#!/usr/bin/env bash
# coop-review.sh —— 给"代码自评"摆材料（只读）。**它不猜分数。**
#
# 分数必须由 agent 按 references/code-review.md 的细则打：
#   可读性 / 最小实现与合理性 / 协作风格一致性 / 安全性  各 10 分，总分 40。
#
# 用法：
#   ./_tools/coop-review.sh               # 审**当前未提交的改动**（提交前自评用，最常用）
#   ./_tools/coop-review.sh <编号>         # 审某个块已记录的提交（[GitCommitIds] 里那些）
#   ./_tools/coop-review.sh --diff [...]   # 连完整 diff 一起打印（默认只给统计，省 context）
#
# 输出：改动文件与行数统计（+ 可选 diff）、评分表骨架、等级与处置。

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_coop-common.sh"

show_diff=0
args=()
for a in "$@"; do
  case "$a" in
    --diff) show_diff=1 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) args+=("$a") ;;
  esac
done

root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$root" ]] || root="$(dirname "$COOP_ROOT")"
gitr() { git -C "$root" "$@"; }

table() {
  cat <<'EOF'

------------------------------------------------------------------
按 references/code-review.md 打分（每维度 10 分，总分 40），把下面这张表
原样填好、发给用户（这是要给人看的产出，不是内部思考）：

| 维度 | 得分 | 为什么给这个分 | 扣分点（要指到 文件:行） |
| --- | --- | --- | --- |
| 可读性 | ?/10 | | |
| 最小实现与合理性 | ?/10 | | |
| 协作风格一致性 | ?/10 | | |
| 安全性 | ?/10 | | |
| **总分** | **?/40（?）** | | |

另外两节也要有：
  ① 「验收对照」——对照块 [Comments] 里写的验收标准逐条打勾（功能做没做到）；
  ② 「过程要求」一行（一个提交一个块 / 正文有思路 / 带 Coop-* trailer）。

等级与处置：
  ≥36   A  直接提交
  30–35 B  直接提交，但把扣分项写进块的 [Comments]（遗留问题）
  24–29 C  先别提交：把扣分点讲给用户，问"改还是接受"；
           联系不上用户又必须交差 → 提交，但扣分项写进块 + 正文写自评分数
  <24   D  先改，改完再提交
N/A 的检查项不计分，该维度按"实得 ÷ 可评满分"折算成 10 分制。
再补一句"我最不放心的三点是什么"——这句话比分数有价值。
------------------------------------------------------------------
EOF
}

# ---- 审当前未提交的改动 ----
if (( ${#args[@]} == 0 )); then
  echo "== 自评范围：当前未提交的改动 =="
  echo
  if gitr rev-parse --verify -q HEAD >/dev/null 2>&1; then
    echo "-- 已跟踪文件的改动统计 --"
    gitr diff HEAD --stat || true
    echo
    echo "-- 改动行数（已跟踪文件）--"
    gitr diff HEAD --numstat 2>/dev/null | awk '{ add += $1; del += $2 } END { printf "  新增 %d 行，删除 %d 行\n", add+0, del+0 }' || true
  else
    echo "（这个仓库还没有任何提交，下面只列新增文件。）"
  fi
  echo
  untracked="$(gitr ls-files --others --exclude-standard 2>/dev/null || true)"
  if [[ -n "$untracked" ]]; then
    echo "-- 新增（未跟踪）文件 --"
    printf '%s\n' "$untracked"
    echo
  fi
  if (( show_diff )); then
    echo "-- 完整 diff --"
    if gitr rev-parse --verify -q HEAD >/dev/null 2>&1; then
      gitr diff HEAD || true
    else
      echo "（没有 HEAD，无可比对的 diff；看上面的新增文件即可。）"
    fi
  else
    echo "（要完整 diff 加 --diff；自评时通常按文件看更省 context）"
  fi
  table
  exit 0
fi

# ---- 审某个块已记录的提交 ----
id="${args[0]}"
f="$(coop_find_block_file "$id")" || exit 1

title="$(coop_get_field "$f" "$id" Title)"
commits="$(coop_get_field "$f" "$id" GitCommitIds)"

echo "== 自评范围：块 #$id —— $title =="
echo "  文件: ${f#"$COOP_ROOT"/}"
echo

mapfile -t SHAS < <(coop_shas_lines "$commits")
if (( ${#SHAS[@]} == 0 )); then
  echo "这个块的 [GitCommitIds] 还是 null，没有可审的提交。"
  echo "（第一次实现时应该审「当前未提交的改动」——不带参数跑本脚本。）"
  table
  exit 0
fi
# 从旧到新看，读起来更像"一步步演进"
if command -v tac >/dev/null 2>&1; then
  mapfile -t SHAS < <(printf '%s\n' "${SHAS[@]}" | tac)
fi

for sha in "${SHAS[@]}"; do
  echo "-- $sha --"
  gitr show --stat --oneline "$sha" 2>/dev/null || { echo "  找不到这个提交（被 rebase 掉了？）"; continue; }
  if (( show_diff )); then
    gitr show --format= "$sha" 2>/dev/null || true
  fi
  echo
done

echo "-- 合计改动 --"
for sha in "${SHAS[@]}"; do
  gitr show --numstat --format= "$sha" 2>/dev/null || true
done | awk '{ add += $1; del += $2 } END { printf "  新增 %d 行，删除 %d 行\n", add+0, del+0 }'

table
