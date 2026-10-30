#!/usr/bin/env bash
# coop-docs-check.sh —— 只读。体检：脚本语法 + Markdown 结构 + frontmatter + 内部链接。
#
# 用法：
#   ./coop-docs-check.sh [-q]               # 默认范围（保守，pre-commit 钩子用这个）
#   ./coop-docs-check.sh --all              # 连 .cursor/skills 下所有 skill、.cursor/rules 全查
#   ./coop-docs-check.sh <路径>…            # 只查指定文件 / 目录
#
# 默认范围只用"我们自己的"文件，**故意不碰别的 skill**：
#   agents-cooperation/、.cursor/rules/agents-cooperation.mdc、.cursor/skills/agents-cooperation/
# 理由：钩子若连 skill-creator 之类别人的文档一起查，那些文档不合规就会挡住本仓库的提交。
# 要全查是人的主动选择，用 --all。
#
# 查这些（每条都定位到 文件:行）：
#   1) *.sh        bash -n 语法
#   2) Markdown    代码围栏是否闭合（按字符和长度，``` 和 ~~~ 不混用）
#   3) Markdown    行内反引号按 CommonMark 配对：长度 N 的串要由下一个长度恰好为 N 的串闭合
#                  （允许跨行配对；所以 ```` ``` ```` 这种包法合法，"行内裸三连反引号"会被判错）
#   4) Markdown    表格每行列数和表头一致
#   5) Markdown    内部链接指向的文件存在
#   6) frontmatter 用 --- 包裹；SKILL.md 要 name + description，.mdc 要 description；
#                  值要符合 YAML 明文标量规则（明文里出现 ': ' 或 ' #' 会被当成新键 / 注释）
#
# 退出码：0 = 没查出问题；1 = 有问题；2 = 用法错。
#
# ⚠️ 这是**结构**检查：它不证明"文档意思写对了"，也不等于 shellcheck——
#    未定义变量、误引用、逻辑错这类查不出来。绿了只代表"没犯这些低级错"。

set -uo pipefail

quiet=0
all=0
want=()
for a in "$@"; do
  case "$a" in
    -q)        quiet=1 ;;
    --all)     all=1 ;;
    -h|--help) sed -n '2,26p' "$0"; exit 0 ;;
    -*)        echo "未知参数: $a" >&2; exit 2 ;;
    *)         want+=("$a") ;;
  esac
done

if root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  cd "$root" || exit 0
else
  echo "提示：不在 git 仓库里，按当前目录查。" >&2
fi

# ---- 收集目标 ----
errors=0
say()  { (( quiet )) || printf '%s\n' "$*"; }
fail() { printf '  ✗ %s\n' "$*"; errors=$(( errors + 1 )); }

targets=()
if (( ${#want[@]} > 0 )); then
  targets=("${want[@]}")
elif (( all )); then
  targets=("agents-cooperation" ".cursor/skills" ".cursor/rules")
else
  targets=("agents-cooperation" ".cursor/rules/agents-cooperation.mdc" ".cursor/skills/agents-cooperation")
fi

md=()
sh=()
missing=()
for t in "${targets[@]}"; do
  if [[ ! -e "$t" ]]; then
    # 默认范围里缺目录是正常的（别的仓库可能没装 skill），但**人显式给的路径**不存在就是错
    if (( ${#want[@]} > 0 )); then missing+=("$t"); fi
    continue
  fi
  if [[ -d "$t" ]]; then
    while IFS= read -r -d '' f; do
      md+=("$f")
    done < <(find "$t" -type f \( -name '*.md' -o -name '*.markdown' -o -name '*.mdc' \) \
             -not -path '*/.git/*' -print0 2>/dev/null | sort -z)
    while IFS= read -r -d '' f; do
      sh+=("$f")
    done < <(find "$t" -type f -name '*.sh' -not -path '*/.git/*' -print0 2>/dev/null | sort -z)
  else
    case "$t" in
      *.md|*.markdown|*.mdc) md+=("$t") ;;
      *.sh)                  sh+=("$t") ;;
    esac
  fi
done

say "体检：$((${#sh[@]})) 个脚本 + $((${#md[@]})) 份文档…"
for t in ${missing[@]+"${missing[@]}"}; do fail "$t  路径不存在"; done
# ---- 1) bash -n ----
# 用 LC_ALL=C 跑：中文 locale 下 bash 会说"行4"，英文才是 "line 4"，抽行号更稳。
for f in ${sh[@]+"${sh[@]}"}; do
  if ! out="$(LC_ALL=C bash -n "$f" 2>&1)"; then
    ln="$(printf '%s\n' "$out" | sed -n 's/^[^:]*: line \([0-9][0-9]*\):.*/\1/p' | head -1)"
    fail "$f:${ln:-?}  bash 语法错误：$(printf '%s\n' "$out" | head -1)"
  fi
done

# ---- 2) 围栏闭合 ----
fence_scan() {
  awk '
    function run(s,   t) {
      t = s; sub(/^[ \t]*/, "", t)
      if (match(t, /^`{3,}/)) return substr(t, RSTART, RLENGTH)
      if (match(t, /^~{3,}/)) return substr(t, RSTART, RLENGTH)
      return ""
    }
    {
      r = run($0)
      if (r == "") next
      if (!open) { open = 1; oc = substr(r, 1, 1); olen = length(r); start = NR }
      else if (substr(r, 1, 1) == oc && length(r) >= olen) { open = 0 }
    }
    END { if (open) printf "%d\n", start }
  ' "$1"
}

# ---- 3) 行内反引号配对 ----
# CommonMark 真相：反引号串**可以跨行配对**（一个 code span 能横跨换行）。
# 所以必须把整篇文档（围栏之外）的反引号串按出现顺序排成一条队列，逐个找"下一个同长度的串"。
# 只有找不到同长度串的那个才算问题——**别按行独立判断**，那会冤枉合法的跨行写法。
backtick_scan() {
  awk '
    function run(s,   t) {
      t = s; sub(/^[ \t]*/, "", t)
      if (match(t, /^`{3,}/)) return substr(t, RSTART, RLENGTH)
      if (match(t, /^~{3,}/)) return substr(t, RSTART, RLENGTH)
      return ""
    }
    {
      r = run($0)
      if (r != "") {
        if (!open) { open = 1; oc = substr(r, 1, 1); olen = length(r) }
        else if (substr(r, 1, 1) == oc && length(r) >= olen) { open = 0 }
        next
      }
      if (open) next
      L = length($0); i = 1
      while (i <= L) {
        c = substr($0, i, 1)
        if (c == "\\") { i += 2; continue }
        if (c == "`") {
          j = i
          while (j <= L && substr($0, j, 1) == "`") j++
          n++; rlen[n] = j - i; rlin[n] = NR
          i = j
          continue
        }
        i++
      }
    }
    END {
      j = 1
      while (j <= n) {
        found = 0
        for (k = j + 1; k <= n; k++) if (rlen[k] == rlen[j]) { found = k; break }
        if (!found) printf "%d\t%d\n", rlin[j], rlen[j]
        j = found ? found + 1 : j + 1
      }
    }
  ' "$1"
}

# ---- 4) 表格列数一致 ----
table_scan() {
  awk '
    function cells(line,   t, n, a) {
      t = line
      sub(/^[ \t]*\|/, "", t); sub(/\|[ \t]*$/, "", t)
      gsub(/\\\|/, "\001", t)
      n = split(t, a, "|")
      return n
    }
    function flush(   i) {
      if (rows > 0) for (i = 1; i <= rows; i++)
        if (col[i] != col[1]) printf "%d\t%d\t%d\n", ln[i], col[i], col[1]
      rows = 0
    }
    /^[ \t]*\|.*\|[ \t]*$/ { rows++; ln[rows] = NR; col[rows] = cells($0); next }
    { flush() }
    END { flush() }
  ' "$1"
}

# ---- 5) 内部链接 ----
link_check() {
  local f="$1" dir entry n t
  dir="$(dirname "$f")"
  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    n="${entry%%:*}"
    t="${entry#*:}"
    t="${t#](}"; t="${t%)}"
    case "$t" in ''|http*|https*|mailto:*|\#*) continue ;; esac
    t="${t%%#*}"
    [[ -e "$dir/$t" ]] || fail "$f:$n  内部链接指向不存在的文件：$t"
  done < <(grep -noE '\]\([^()[:space:]]+\)' "$f" 2>/dev/null || true)
}

# ---- 6) frontmatter ----
fm_check() {
  local f="$1" kind="" first close ln=0 line key val
  case "$f" in
    *.mdc)                kind="mdc" ;;
    */SKILL.md|SKILL.md)  kind="skill" ;;
    *)                    return 0 ;;
  esac
  first="$(head -1 "$f")"
  if [[ "$first" != "---" ]]; then
    fail "$f:1  frontmatter 必须以 --- 开头"
    return 0
  fi
  close="$(awk 'NR > 1 && $0 == "---" { print NR; exit }' "$f")"
  if [[ -z "$close" ]]; then
    fail "$f:1  frontmatter 没有闭合的 ---"
    return 0
  fi
  while IFS= read -r line; do
    ln=$(( ln + 1 ))
    (( ln == 1 )) && continue
    (( ln >= close )) && break
    [[ -z "${line// /}" ]] && continue
    [[ "$line" == '#'* ]] && continue
    case "$line" in
      *:*) ;;
      *) fail "$f:$ln  frontmatter 这行不是 key: value：$line"; continue ;;
    esac
    key="${line%%:*}"
    val="${line#*:}"
    val="${val#"${val%%[! ]*}"}"
    if [[ -z "$val" ]]; then
      fail "$f:$ln  frontmatter 的 $key 值是空的"
      continue
    fi
    case "$val" in
      '"'*|"'"*)
        # 引号包裹：只要求首尾同一种引号、且成对
        if (( ${#val} < 2 )) || [[ "${val:0:1}" != "${val: -1}" ]]; then
          fail "$f:$ln  $key 的引号没闭合"
        fi
        continue
        ;;
    esac
    [[ "$val" == *": "* ]] && fail "$f:$ln  $key 的明文值里有 ': '（YAML 会当成新的键；要写就加引号）"
    [[ "$val" == *" #"* ]] && fail "$f:$ln  $key 的明文值里有 ' #'（YAML 会当成注释；要写就加引号）"
    case "$val" in
      '!'*|'&'*|'*'*|'|'*|'>'*|'%'*|'@'*|'`'*|'['*|'{'*|','*|'-'*|'?'*)
        fail "$f:$ln  $key 的明文值以 YAML 指示符开头：$val" ;;
    esac
  done < "$f"
  if [[ "$kind" == "skill" ]]; then
    grep -qE '^name:[[:space:]]*[^[:space:]]' "$f"        || fail "$f  frontmatter 缺 name（SKILL.md 必须有）"
    grep -qE '^description:[[:space:]]*[^[:space:]]' "$f" || fail "$f  frontmatter 缺 description（SKILL.md 必须有）"
  else
    grep -qE '^description:[[:space:]]*[^[:space:]]' "$f" || fail "$f  frontmatter 缺 description（.mdc 必须有）"
  fi
}

# ---- 跑 ----
for f in ${md[@]+"${md[@]}"}; do
  s="$(fence_scan "$f")"
  [[ -n "$s" ]] && fail "$f:$s  代码围栏没闭合（从这里开始）"

  while IFS=$'\t' read -r n len; do
    [[ -n "${n:-}" ]] && fail "$f:$n  行内反引号没配对（长度 $len 的串找不到同长度的闭合串）"
  done < <(backtick_scan "$f")

  while IFS=$'\t' read -r n got exp; do
    [[ -n "${n:-}" ]] && fail "$f:$n  表格这行 $got 列，表头 $exp 列"
  done < <(table_scan "$f")

  link_check "$f"
  fm_check "$f"
done

if (( errors )); then
  printf '✗ 体检没通过：%d 个问题。\n' "$errors" >&2
  exit 1
fi
printf '✓ 体检通过：%d 个脚本、%d 份文档，没查出语法 / 结构问题（结构检查，不等于 shellcheck）\n' \
  "${#sh[@]}" "${#md[@]}"
