#!/usr/bin/env bash
# coop-docs-check.sh —— 只读。体检：脚本语法 + Markdown 结构 + frontmatter + 内部链接。
#
# 用法：
#   ./_tools/coop-docs-check.sh [-q]               # 默认范围（保守，pre-commit 钩子用这个）
#   ./_tools/coop-docs-check.sh --all              # 连 .cursor/skills 下所有 skill、.cursor/rules 全查
#   ./_tools/coop-docs-check.sh <路径>…            # 只查指定文件 / 目录
#
# 默认范围只用"我们自己的"文件，**故意不碰别的 skill**：
#   agents-cooperation/、.cursor/rules/agents-cooperation.mdc、.cursor/skills/agents-cooperation/
# 理由：钩子若连 skill-creator 之类别人的文档一起查，那些文档不合规就会挡住本仓库的提交。
# 要全查是人的主动选择，用 --all。
#
# 查这些（每条都定位到 文件:行）：
#   1) *.sh        bash -n 语法
#   2) Markdown    代码：围栏是否闭合（按字符和长度，``` 和 ~~~ 不混用；围栏最多缩进 3 格，
#                  缩进 4 格是"缩进代码块"，里面的 ``` 只是字面文本——这条判错过，才补上的）
#   3) Markdown    行内反引号按 CommonMark 配对：长度 N 的串要由下一个长度恰好为 N 的串闭合
#                  （允许跨行配对；所以 ```` ``` ```` 这种包法合法，"行内裸三连反引号"会被判错）
#   4) Markdown    表格每行列数和表头一致
#   5) Markdown    内部链接指向的文件存在
#   6) frontmatter 用 --- 包裹；SKILL.md 要 name + description，.mdc 要 description；
#                  值要符合 YAML 明文标量规则（明文里出现 ': ' 或 ' #' 会被当成新键 / 注释）
#
# 3) / 4) / 5) 只看**正文行**：围栏内和缩进代码块里的都算代码——里面的反引号、`|`、`[x](y)`
# 都是举例用的字面文本，拿它们判错就是冤枉人（这是把自己的文档跑出误报之后补上的规则）。
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
    -h|--help) sed -n '2,31p' "$0"; exit 0 ;;
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

# ---- 2) 先判定"哪些行是正文"，后面 3) / 4) / 5) 共用 ----
#
# 为什么非要有这一步：代码块里的东西是**举例用的字面文本**，拿它们判错就是冤枉人。已经冤枉过两次：
#   - 四空格缩进的"缩进代码块"里写了一行 ``` → 被当成围栏；
#   - 围栏里的行内示例反引号 / 示例链接 → 被当成正文检查。
# 所以规则统一成一条：**围栏内 + 缩进代码块内的行 = 代码，不参与后面三项**。
# 顺带好处：围栏状态机只有这一处，不会出现"两个函数对围栏的判断不一样"。
#
# 输出：每行 "真实行号<TAB>正文"（正文里含 Tab 也不影响，按**第一个** Tab 切）。
# 围栏没闭合时，最后多吐一行 "!<TAB>围栏起始行"，由调用方报错。
prose_scan() {
  awk '
    # 围栏最多缩进 3 格（CommonMark）；缩进 4 格是缩进代码块，里面的 ``` 只是字面文本
    function fence(s,   m, ind) {
      if (!match(s, /^[ \t]*(`{3,}|~{3,})/)) return ""
      m = substr(s, RSTART, RLENGTH)
      ind = length(m)
      sub(/^[ \t]*/, "", m)
      ind -= length(m)
      if (ind > 3) return ""
      return m
    }
    {
      r = fence($0)
      if (r != "") {
        if (!open) { open = 1; oc = substr(r, 1, 1); olen = length(r); fstart = NR }
        else if (substr(r, 1, 1) == oc && length(r) >= olen) { open = 0 }
        next
      }
      if (open) next
      if ($0 ~ /^\t/ || $0 ~ /^[ \t][ \t][ \t][ \t]/) next   # 缩进代码块
      printf "%d\t%s\n", NR, $0
    }
    END { if (open) printf "!\t%d\n", fstart }
  ' "$1"
}

# ---- 3) 行内反引号配对（吃 prose_scan 的输出）----
# CommonMark 真相：反引号串**可以跨行配对**（一个 code span 能横跨换行）。
# 所以要按出现顺序排成一条队列，逐个找"下一个同长度的串"；只有找不到同长度串的才算问题。
# 千万别按行独立判断——那会把合法的跨行写法冤枉掉（真实踩过）。
backtick_find() {
  awk '
    {
      p = index($0, "\t")
      nr = substr($0, 1, p - 1)
      if (nr == "!") next
      s = substr($0, p + 1)
      i = 1; L = length(s)
      while (i <= L) {
        c = substr(s, i, 1)
        if (c == "\\") { i += 2; continue }
        if (c == "`") {
          j = i
          while (j <= L && substr(s, j, 1) == "`") j++
          n++; rlen[n] = j - i; rlin[n] = nr
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
  '
}

# ---- 4) 表格列数一致（吃 prose_scan 的输出）----
table_find() {
  awk '
    function cells(line,   t, a) {
      t = line
      sub(/^[ \t]*\|/, "", t); sub(/\|[ \t]*$/, "", t)
      gsub(/\\\|/, "\001", t)
      return split(t, a, "|")
    }
    function flush(   i) {
      if (rows > 0) for (i = 1; i <= rows; i++)
        if (col[i] != col[1]) printf "%d\t%d\t%d\n", ln[i], col[i], col[1]
      rows = 0
    }
    {
      p = index($0, "\t")
      nr = substr($0, 1, p - 1)
      if (nr == "!") next
      s = substr($0, p + 1)
      if (s ~ /^[ \t]*\|.*\|[ \t]*$/) { rows++; ln[rows] = nr; col[rows] = cells(s); next }
      flush()
    }
    END { flush() }
  '
}

# ---- 5) 内部链接（吃 prose_scan 的输出）----
# 两种"不是链接"的情形都要排除，否则全是误报：
#   a) 围栏 / 缩进代码块里的示例 → prose_scan 已经排掉了；
#   b) 行内 code span 里写的示例（比如"写法是 `[标题](路径)`"）→ 这里先把 span 抹掉再找链接。
#      span 是按**行内**配对处理的（跨行 span 里写链接会漏掉，这条近似是有意认下的）。
link_find() {
  awk '
    function strip_spans(s,   i, L, c, j, rl, rp, cnt, k, found, out, from, to, pad, t) {
      L = length(s); cnt = 0; i = 1
      while (i <= L) {
        c = substr(s, i, 1)
        if (c == "\\") { i += 2; continue }
        if (c == "`") {
          j = i
          while (j <= L && substr(s, j, 1) == "`") j++
          cnt++; rl[cnt] = j - i; rp[cnt] = i
          i = j
          continue
        }
        i++
      }
      out = s
      j = 1
      while (j <= cnt) {
        found = 0
        for (k = j + 1; k <= cnt; k++) if (rl[k] == rl[j]) { found = k; break }
        if (found) {
          from = rp[j]; to = rp[found] + rl[found] - 1
          pad = ""
          for (t = 1; t <= to - from + 1; t++) pad = pad " "
          out = substr(out, 1, from - 1) pad substr(out, to + 1)
        }
        j = found ? found + 1 : j + 1
      }
      return out
    }
    {
      p = index($0, "\t")
      nr = substr($0, 1, p - 1)
      if (nr == "!") next
      s = strip_spans(substr($0, p + 1))
      while (match(s, /\]\([^()[:space:]]+\)/)) {
        printf "%s\t%s\n", nr, substr(s, RSTART + 2, RLENGTH - 3)
        s = substr(s, RSTART + RLENGTH)
      }
    }
  '
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
  # 正文流只算一次，三项检查共用（顺带在这里报未闭合的围栏）
  prose=()
  while IFS= read -r line; do
    if [[ "${line%%$'\t'*}" == "!" ]]; then
      fail "$f:${line#*$'\t'}  代码围栏没闭合（从这里开始）"
      continue
    fi
    prose+=("$line")
  done < <(prose_scan "$f")

  while IFS=$'\t' read -r n len; do
    [[ -n "${n:-}" ]] && fail "$f:$n  行内反引号没配对（长度 $len 的串找不到同长度的闭合串）"
  done < <(printf '%s\n' ${prose[@]+"${prose[@]}"} | backtick_find)

  while IFS=$'\t' read -r n got exp; do
    [[ -n "${n:-}" ]] && fail "$f:$n  表格这行 $got 列，表头 $exp 列"
  done < <(printf '%s\n' ${prose[@]+"${prose[@]}"} | table_find)

  while IFS=$'\t' read -r n t; do
    [[ -z "${n:-}" ]] && continue
    case "$t" in ''|http*|https*|mailto:*|\#*) continue ;; esac
    t="${t%%#*}"
    [[ -e "$(dirname "$f")/$t" ]] || fail "$f:$n  内部链接指向不存在的文件：$t"
  done < <(printf '%s\n' ${prose[@]+"${prose[@]}"} | link_find)

  fm_check "$f"
done

if (( errors )); then
  printf '✗ 体检没通过：%d 个问题。\n' "$errors" >&2
  exit 1
fi
printf '✓ 体检通过：%d 个脚本、%d 份文档，没查出语法 / 结构问题（结构检查，不等于 shellcheck）\n' \
  "${#sh[@]}" "${#md[@]}"
