#!/usr/bin/env bash
# _coop-common.sh —— agents-cooperation 各脚本共用的解析库。
# 不要直接执行，用 `source "<脚本同目录>/_coop-common.sh"` 引入。
#
# 提供：
#   $COOP_SEP        内部字段分隔符（ASCII 31；不能用 TAB，bash 会把空字段吃掉）
#   $COOP_ROOT       协作目录（= 本文件所在目录），所有脚本都以此为根
#   coop_scan_rows   输出所有协作块，一行一个，字段用 $COOP_SEP 分隔：
#                      文件 <SEP> Index <SEP> Valid <SEP> Author <SEP> Title
#                           <SEP> GitBranch <SEP> GitCommitIds
#   coop_next_index  下一个可用编号（= 纯数字 Index 的最大值 + 1）
#   coop_author_seq  某作者的下一个序号（人类编号用）
#   coop_make_index  按作者类型生成新编号（agent 用纯数字，人用 <作者>-<n>）
#   coop_is_ai       作者名是不是 AI（以 agent 结尾）
#   coop_shas_json   把若干 sha 拼成 ["sha", ...] 字面量
#   coop_shas_lines  把 ["sha", ...] / null / 空解析成每行一个 sha
#   coop_file_lines  打印文件里不在围栏代码块内的行（"行号<TAB>原文"）
#   coop_block_exists_in 某个文件里有没有这个编号的块（围栏感知、CRLF 安全）
#   coop_find_block_file 定位编号所在的唯一文件（撞号/找不到都报错）
#   coop_get_field   读某个块里某个字段的值（围栏感知、CRLF 安全）
#   coop_set_field   写某个块里某个字段（有就替换、没有就按字段顺序插入）
#
# ⚠️ 要读/写块里的字段，**一律用上面两个函数**，别在脚本里再手写一遍 awk。
#    历史上 coop-record.sh 手写了第二套 awk，结果：块里缺 [GitBranch] 时静默不写、
#    CRLF 文件里比较不上去（都还打印"已回写"）——同一件事有两个实现就会这样。
#
# 块的边界靠「字段顺序」判断，顺序固定为：
#   Index < Valid < Author < Title < GitBranch < GitCommitIds < Comments
# 出现不高于上一个字段的字段，就认为上一个块结束、新块开始。
# 所以人类块整块不写 [Index] 也能被正确切开。
#
# 解析细节（都是为了少踩坑）：
#   - 字段必须**顶格**（行首无空白）；
#   - 字段名大小写不敏感（[index] 也认），但规范写法是首字母大写；
#   - 冒号半角 `:` 与全角 `：` 都认（中文输入法很容易打出全角）；
#   - **围栏代码块（``` / ~~~）里的内容整段跳过**，所以在文档里演示块格式
#     不会变成"幽灵块"。（coop-lint.sh 会检查围栏是否闭合。）
#   - 但 [Comments] 里**顶格**写出 `[Index]: …` 会被当成新块的开始——
#     coop-lint.sh 会用"看起来像字段但没被解析"的检查兜住常见的写法问题。

COOP_SEP=$'\x1f'
COOP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 编号锁（临时文件，可 gitignore）与编号预留表（要提交，别人 pull 才看得到）
COOP_LOCK_FILE="${COOP_LOCK_FILE:-$COOP_ROOT/.index.lock}"
COOP_RESERVE_FILE="${COOP_RESERVE_FILE:-$COOP_ROOT/index-reserved.txt}"

# 以 `_` 开头的文件 / 目录**不是协作块**，用来放仓库级说明（如 _repo/build.md）。
# 见 SKILL.md「目录结构」。
coop_is_ignored() {
  case "$1" in
    _*|*/_*) return 0 ;;
    *)       return 1 ;;
  esac
}

coop_scan_rows() {
  local f rel
  while IFS= read -r -d '' f; do
    rel="${f#"$COOP_ROOT"/}"
    coop_is_ignored "$rel" && continue
    awk -v file="$rel" -v sep="$COOP_SEP" '
      BEGIN {
        R["index"] = 1; R["valid"] = 2; R["author"] = 3; R["title"] = 4
        R["gitbranch"] = 5; R["gitcommitids"] = 6; R["comments"] = 7
      }
      function flush() {
        if (open) printf "%s%s%s%s%s%s%s%s%s%s%s%s%s\n", \
          file, sep, idx, sep, valid, sep, author, sep, title, sep, branch, sep, commits
        open = 0; idx = ""; valid = ""; author = ""; title = ""; branch = ""; commits = ""
        lastrank = 0
      }
      /^[ \t]*(```|~~~)/ { in_fence = !in_fence; next }
      in_fence { next }
      /^\[[A-Za-z]+\]:/ || /^\[[A-Za-z]+\]：/ {
        close_at = index($0, "]")
        name = tolower(substr($0, 2, close_at - 2))
        if (!(name in R)) next
        value = substr($0, close_at + 1)
        sub(/^[ \t]*/, "", value)
        sub(/^:/, "", value)      # 半角冒号
        sub(/^：/, "", value)      # 全角冒号
        sub(/^[ \t]*/, "", value)
        sub(/\r$/, "", value)
        if (open && R[name] <= lastrank) flush()
        open = 1; lastrank = R[name]
        if      (name == "index")        idx = value
        else if (name == "valid")        valid = value
        else if (name == "author")       author = value
        else if (name == "title")        title = value
        else if (name == "gitbranch")    branch = value
        else if (name == "gitcommitids") commits = value
        next
      }
      END { flush() }
    ' "$f"
  done < <(find "$COOP_ROOT" -type f \( -name '*.md' -o -name '*.markdown' \) -print0 | sort -z)
}

coop_next_index() {
  local row idx max=0 reserved
  while IFS= read -r row; do
    [[ -z "$row" ]] && continue
    IFS="$COOP_SEP" read -r _f idx _v _a _t _b _c <<<"$row"
    if [[ "$idx" =~ ^[0-9]+$ ]]; then
      if (( idx > max )); then max=$idx; fi
    fi
  done < <(coop_scan_rows)
  # 预留表里已经占掉的号也算，免得两个工作区/分支同时用同一个号
  reserved="$(coop_reserved_max)"
  if (( reserved > max )); then max=$reserved; fi
  echo $(( max + 1 ))
}

# 预留表里最大的编号（没有预留表就是 0）
coop_reserved_max() {
  local n max=0
  [[ -f "$COOP_RESERVE_FILE" ]] || { echo 0; return 0; }
  while read -r n _rest; do
    [[ "$n" =~ ^[0-9]+$ ]] || continue
    if (( n > max )); then max=$n; fi
  done < "$COOP_RESERVE_FILE"
  echo "$max"
}

# 登记一个预留编号（必须在 coop_lock 之后调用）
coop_reserve_index() {
  printf '%s %s %s\n' "$1" "${2:-}" "$(date '+%Y-%m-%d %H:%M:%S')" >> "$COOP_RESERVE_FILE"
}

# 取编号锁：同一工作区并发时靠它串行化"算号 + 写块"。
# flock 优先；没有 flock 就退化成 mkdir 自旋。用完记得 coop_unlock。
coop_lock() {
  if command -v flock >/dev/null 2>&1; then
    exec 9>>"$COOP_LOCK_FILE"
    flock 9
  else
    local n=0
    while ! mkdir "${COOP_LOCK_FILE}.d" 2>/dev/null; do
      sleep 0.2
      n=$(( n + 1 ))
      if (( n > 150 )); then
        echo "取编号锁超时（${COOP_LOCK_FILE}.d 还占着？）" >&2
        return 1
      fi
    done
    COOP_LOCK_DIR="${COOP_LOCK_FILE}.d"
  fi
  return 0
}

coop_unlock() {
  if [[ -n "${COOP_LOCK_DIR:-}" ]]; then
    rmdir "$COOP_LOCK_DIR" 2>/dev/null || true
    unset COOP_LOCK_DIR
  else
    exec 9>&- 2>/dev/null || true
  fi
}

coop_is_ai() { [[ "${1,,}" == *agent ]]; }

# 某个作者的下一个可用序号（人类编号用）：看它已用过的纯数字编号和 <作者>-<n> 里的最大值
coop_author_seq() {
  local want="$1" row idx author n max=0
  while IFS= read -r row; do
    [[ -z "$row" ]] && continue
    IFS="$COOP_SEP" read -r _f idx _v author _t _b _c <<<"$row"
    if [[ "$author" == "$want" && "$idx" =~ ^[0-9]+$ ]]; then
      if (( idx > max )); then max=$idx; fi
    fi
    if [[ "$idx" =~ ^(.+)-([0-9]+)$ ]]; then
      if [[ "${BASH_REMATCH[1]}" == "$want" ]]; then
        n="${BASH_REMATCH[2]}"
        if (( n > max )); then max=$n; fi
      fi
    fi
  done < <(coop_scan_rows)
  echo $(( max + 1 ))
}

# 给作者生成一个该用的编号：AI 用纯数字，人用 <作者>-<序号>
coop_make_index() {
  if coop_is_ai "$1"; then coop_next_index; else echo "$1-$(coop_author_seq "$1")"; fi
}

coop_shas_json() {
  local out="" s
  for s in "$@"; do out+="\"$s\", "; done
  out="${out%, }"
  printf '[%s]' "$out"
}

# 把 ["a","b"] / null / 空 解析成每行一个 sha
coop_shas_lines() {
  local raw="$1"
  [[ -z "$raw" || "$raw" == "null" ]] && return 0
  printf '%s' "$raw" | tr -d '[]" ' | tr ',' '\n' | sed '/^$/d'
}

# 打印文件里不在围栏代码块内的行，格式："行号<TAB>原文"
coop_file_lines() {
  awk '
    /^[ \t]*(```|~~~)/ { fence = !fence; next }
    fence { next }
    { printf "%d\t%s\n", NR, $0 }
  ' "$1"
}

# 文件 $1 里有没有编号 $2 的块。（围栏感知、CRLF 安全）
coop_block_exists_in() {
  awk -v id="$2" '
    /^[ \t]*(```|~~~)/ { fence = !fence; next }
    fence { next }
    /^\[[Ii]ndex\][:：]/ {
      v = $0; sub(/\r$/, "", v)
      sub(/^\[[Ii]ndex\][:：][ \t]*/, "", v); sub(/[ \t]+$/, "", v)
      if (v == id) { found = 1; exit }
    }
    END { exit(found ? 0 : 1) }
  ' "$1"
}

# 定位编号所在的**唯一**文件，成功时打印绝对路径。
# 找不到 / 撞号 → 报错到 stderr 并返回非 0（调用方 `|| exit 1` 即可）。
coop_find_block_file() {
  local id="$1" f rel
  local -a hits=()
  while IFS= read -r -d '' f; do
    rel="${f#"$COOP_ROOT"/}"
    coop_is_ignored "$rel" && continue
    coop_block_exists_in "$f" "$id" && hits+=("$f")
  done < <(find "$COOP_ROOT" -type f \( -name '*.md' -o -name '*.markdown' \) -print0 | sort -z)

  if (( ${#hits[@]} == 0 )); then
    printf '没找到编号为 %s 的协作块。\n' "'$id'" >&2
    return 1
  fi
  if (( ${#hits[@]} > 1 )); then
    printf '编号 %s 在多个文件里出现，不猜是哪个：\n' "$id" >&2
    printf '  %s\n' "${hits[@]#"$COOP_ROOT"/}" >&2
    printf '先跑 ./coop-lint.sh 修掉撞号，再继续。\n' >&2
    return 1
  fi
  printf '%s\n' "${hits[0]}"
}

# 读块 $2（在文件 $1 里）的字段 $3 的值。字段名大小写不敏感。
coop_get_field() {
  awk -v id="$2" -v want="$3" '
    BEGIN { w = tolower(want) }
    /^[ \t]*(```|~~~)/ { fence = !fence; next }
    fence { next }
    /^\[[A-Za-z]+\][:：]/ {
      line = $0; sub(/\r$/, "", line)
      close_at = index(line, "]")
      name = tolower(substr(line, 2, close_at - 2))
      value = substr(line, close_at + 1)
      sub(/^[ \t]*/, "", value); sub(/^:/, "", value); sub(/^：/, "", value); sub(/^[ \t]*/, "", value)
      if (name == "index") { cur = value; next }
      if (cur == id && name == w) { print value; exit }
    }
  ' "$1"
}

# 写块 $2（在文件 $1 里）的字段 $3 = $4：
#   - 字段已存在 → 原地替换（只动这一行，Comments 等多行字段不受影响）；
#   - 字段不存在 → 按字段顺序（Index<Valid<Author<Title<GitBranch<GitCommitIds<Comments）
#     插到正确位置（缺 [GitBranch] 的块也能被补齐）；
#   - 围栏代码块里的同名行不动；CRLF 文件保持 CRLF。
coop_set_field() {
  local file="$1" id="$2" field="$3" value="$4"
  local cr="" tmp
  grep -qU $'\r$' "$file" 2>/dev/null && cr=$'\r'
  tmp="$(mktemp)"

  awk -v id="$id" -v field="$field" -v value="$value" -v cr="$cr" '
    BEGIN {
      R["index"] = 1; R["valid"] = 2; R["author"] = 3; R["title"] = 4
      R["gitbranch"] = 5; R["gitcommitids"] = 6; R["comments"] = 7
      w = tolower(field)
      wrank = (w in R) ? R[w] : 99
    }
    { lines[NR] = $0 }
    END {
      n = NR
      # 围栏标记：fe[i]=1 表示第 i 行在围栏里（围栏标记行本身算在围栏外）
      inf = 0
      for (i = 1; i <= n; i++) {
        l = lines[i]; sub(/\r$/, "", l)
        fe[i] = inf
        if (l ~ /^[ \t]*(```|~~~)/) inf = !inf
      }

      # 1) 找目标块的范围 [start, finish]
      start = 0; finish = 0
      for (i = 1; i <= n; i++) {
        if (fe[i]) continue
        l = lines[i]; sub(/\r$/, "", l)
        if (l ~ /^\[[Ii]ndex\][:：]/) {
          v = l; sub(/^\[[Ii]ndex\][:：][ \t]*/, "", v); sub(/[ \t]+$/, "", v)
          if (start == 0) { if (v == id) start = i }
          else            { finish = i - 1; break }
        }
      }
      if (start == 0) { for (i = 1; i <= n; i++) print lines[i]; exit 0 }   # 没这个块：原样输出
      if (finish == 0 || finish < start) finish = n

      # 2) 块里有没有这个字段
      fld = 0
      for (i = start + 1; i <= finish; i++) {
        if (fe[i]) continue
        l = lines[i]; sub(/\r$/, "", l)
        if (l ~ /^\[[A-Za-z]+\][:：]/) {
          close_at = index(l, "]")
          nm = tolower(substr(l, 2, close_at - 2))
          if (nm == w) { fld = i; break }
        }
      }

      # 3) 没有就找插入点：最后一个 rank 更小的字段行之后
      ins = start + 1
      if (fld == 0) {
        for (i = start + 1; i <= finish; i++) {
          if (fe[i]) continue
          l = lines[i]; sub(/\r$/, "", l)
          if (l ~ /^\[[A-Za-z]+\][:：]/) {
            close_at = index(l, "]")
            nm = tolower(substr(l, 2, close_at - 2))
            if ((nm in R) && R[nm] < wrank) ins = i + 1
          }
        }
      }

      # 4) 输出
      for (i = 1; i <= n; i++) {
        if (i == fld) { print "[" field "]: " value cr; continue }
        if (fld == 0 && i == ins) print "[" field "]: " value cr
        print lines[i]
      }
      if (fld == 0 && ins > n) print "[" field "]: " value cr
    }
  ' "$file" > "$tmp"

  mv "$tmp" "$file"
}
