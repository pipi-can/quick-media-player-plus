#!/usr/bin/env bash
# selftest.sh —— agents-cooperation 脚本的回归测试。**改完脚本先跑它。**
#
# 用法：
#   .cursor/skills/agents-cooperation/assets/selftest.sh
#
# 它在临时目录里搭一个假仓库，把同目录的脚本拷进去，然后逐条验证行为。
# 不碰你的工作区；测完自动删临时目录。全部通过退出码 0，有失败退出码 1。

set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/coop-selftest.XXXXXX")"
cleanup() { rm -rf "$T"; }
trap cleanup EXIT
cd "$T" || exit 2

# 这个目录里没有 selftest.sh 自己，免得被 coop-init 的 *.sh 一起复制。
# 按真实约定的位置放（.cursor/skills/.../assets），这样 coop-init --check-sync 能找到"模板"。
mkdir -p "$T/scripts"
for f in "$SRC"/*.sh; do
  [[ "$(basename "$f")" == "selftest.sh" ]] && continue
  cp "$f" "$T/scripts/"
done
chmod +x "$T/scripts"/*.sh
TPL="$T/.cursor/skills/agents-cooperation/assets"
mkdir -p "$TPL"
cp "$T/scripts"/*.sh "$TPL/"
chmod +x "$TPL"/*.sh

pass=0
fail=0
section() { printf '\n== %s ==\n' "$1"; }
ok()   { pass=$(( pass + 1 )); printf '  ok    %s\n' "$1"; }
bad()  { fail=$(( fail + 1 )); printf '  FAIL  %s\n' "$1"; [[ -n "${2:-}" ]] && printf '        %s\n' "$2"; }

out=""
rc=0
run() { out="$("$@" 2>&1)"; rc=$?; }
expect_rc()  { if [[ "$rc" == "$2" ]]; then ok "$1"; else bad "$1" "期望退出码 $2，实际 $rc；输出：$out"; fi; }
expect_eq()  { if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1" "期望 [$2]，实际 [$3]"; fi; }
expect_has() { if [[ "$out" == *"$2"* ]]; then ok "$1"; else bad "$1" "输出里没有 [$2]；输出：$out"; fi; }
expect_no()  { if [[ "$out" != *"$2"* ]]; then ok "$1"; else bad "$1" "输出里不该有 [$2]；输出：$out"; fi; }

reset_coop() {
  rm -rf "$T/coop"; mkdir -p "$T/coop"
  cp "$T/scripts"/*.sh "$T/coop/"; chmod +x "$T/coop"/*.sh
  : > "$T/coop/index-reserved.txt"      # coop-init 会生成它；缺了 lint 会警告
}

# 造一个块：mkblock <文件> <编号> <作者> <标题> [valid] [commits]
mkblock() {
  local f="$1" idx="$2" author="$3" title="$4" valid="${5:-true}" commits="${6:-null}"
  mkdir -p "$(dirname "$f")"
  {
    printf '\n[Index]: %s\n' "$idx"
    printf '[Valid]: %s\n' "$valid"
    printf '[Author]: %s\n' "$author"
    printf '[Title]: %s\n' "$title"
    printf '[GitBranch]: null\n'
    printf '[GitCommitIds]: %s\n' "$commits"
    printf '[Comments]:\n  测试用。\n'
  } >> "$f"
}

gitq() { git -c user.email=t@t -c user.name=T "$@"; }

# ---------------------------------------------------------------- 编号
section "编号与建块"
reset_coop
run ./coop/get-index.sh --next
expect_rc "空目录 --next 退出码 0" 0
expect_eq "空目录 --next = 1" 1 "$out"

run ./coop/coop-new-block.sh -f orders -t "下单流程" -a opencode-agent
expect_rc "建 AI 块" 0
expect_has "AI 块编号是 #1" "已新建协作块 #1"
run ./coop/coop-new-block.sh -f orders -t "退款流程" -a cursor-agent
expect_has "第二个 AI 块编号是 #2" "已新建协作块 #2"
run ./coop/coop-new-block.sh -f orders -t "手改备注" -a ren
expect_has "人类块编号是 ren-1" "已新建协作块 #ren-1"
run ./coop/coop-new-block.sh -f orders -t "手改备注二" -a ren
expect_has "第二个人类块编号是 ren-2" "已新建协作块 #ren-2"
run ./coop/get-index.sh --next
expect_eq "人类块不占 agent 号段（next=3）" 3 "$out"

# ---------------------------------------------------------------- 预留
section "编号预留（跨工作区防撞号）"
printff() { printf '%s\n' "$@" > "$T/coop/index-reserved.txt"; }
printff "5 opencode-agent 2026-01-01 00:00:00"
run ./coop/get-index.sh --next
expect_eq "预留号 5 被跳过（next=6）" 6 "$out"
run ./coop/get-index.sh
expect_has "报告里提示预留表" "编号预留表"
rm -f "$T/coop/index-reserved.txt"

# ---------------------------------------------------------------- lint 通过
section "lint（正常）"
reset_coop
./coop/coop-new-block.sh -f playback -t "播放暂停按钮" -a opencode-agent >/dev/null
sed -i 's|^  TODO:.*|  目标：播放键在播放/暂停之间切图标。|' "$T/coop/playback/实现思路.md"
sed -i 's|^  （写法参考.*|  设计：用 MultiStateItem，不自己存 isPlaying。|' "$T/coop/playback/实现思路.md"
run ./coop/coop-lint.sh
expect_rc "格式正常 → 退出码 0" 0
expect_has "格式正常 → 统计" "格式没问题"

# ---------------------------------------------------------------- lint 报错
section "lint（各类错误都要抓到）"
reset_coop
mkblock "$T/coop/a/x.md"          1 opencode-agent "正常块"
mkblock "$T/coop/a/y.md"          1 cursor-agent   "撞号块"
run ./coop/coop-lint.sh -q
expect_rc "编号撞号 → 失败" 1
expect_has "编号撞号 → 报出来" "撞了"

reset_coop
printf '[Index]：1\n[Valid]: true\n[Author]: opencode-agent\n[Title]: 全角\n[GitCommitIds]: null\n[Comments]:\n  x\n' > "$T/coop/a/fw.md" 2>/dev/null || { mkdir -p "$T/coop/a"; printf '[Index]：1\n[Valid]: true\n[Author]: opencode-agent\n[Title]: 全角\n[GitCommitIds]: null\n[Comments]:\n  x\n' > "$T/coop/a/fw.md"; }
run ./coop/coop-lint.sh -q
expect_rc "全角冒号 → 失败" 1
expect_has "全角冒号 → 报出来" "全角冒号"
run ./coop/get-index.sh
expect_has "全角冒号照样能被读到（不静默丢块）" "#1"

reset_coop
mkdir -p "$T/coop/a"
printf '[index]: 1\n[valid]: true\n[author]: opencode-agent\n[title]: 小写\n[comments]:\n  x\n' > "$T/coop/a/lc.md"
run ./coop/coop-lint.sh -q
expect_rc "小写字段名 → 失败" 1
expect_has "小写字段名 → 报出来" "字段名大小写不对"

reset_coop
mkblock "$T/coop/a/i.md" 1 opencode-agent "缩进测试"
sed -i 's|^\[GitCommitIds\]: null|[GitCommitIds]: null|' "$T/coop/a/i.md"
printf '  [Comments]:\n' >> "$T/coop/a/i.md"
run ./coop/coop-lint.sh -q
expect_rc "缩进字段只是警告（退出码 0）" 0
expect_has "缩进字段 → 给警告" "字段被缩进了"

reset_coop
mkdir -p "$T/coop/a"
printf '[Index]: 1\n[Valid]: true\n[Author]: opencode-agent\n[Title]: 围栏没关\n[GitCommitIds]: null\n[Comments]:\n  x\n\n```markdown\n内容\n' > "$T/coop/a/f.md"
run ./coop/coop-lint.sh -q
expect_rc "围栏没闭合 → 失败" 1
expect_has "围栏没闭合 → 报出来" "围栏代码块没闭合"

reset_coop
mkblock "$T/coop/a/t.md" 1 opencode-agent "TODO 没删" true null
printf '  TODO: 删掉这行，写清楚实现思路\n' >> "$T/coop/a/t.md"
run ./coop/coop-lint.sh -q
expect_rc "TODO 占位符没删 → 失败" 1
expect_has "TODO 占位符没删 → 报出来" "TODO 占位符"

reset_coop
mkblock "$T/coop/a/s.md" 1 opencode-agent "坏 sha" true '["abc"]'
run ./coop/coop-lint.sh -q
expect_rc "非法 sha → 失败" 1
expect_has "非法 sha → 报出来" "不合法的项"

reset_coop
mkblock "$T/coop/a/b.md" 1 opencode-agent "分支带空格"
sed -i 's|^\[GitBranch\]: null|[GitBranch]: feat/x y|' "$T/coop/a/b.md"
run ./coop/coop-lint.sh -q
expect_rc "分支名带空格 → 失败" 1
expect_has "分支名带空格 → 报出来" "不能含空格"

reset_coop
mkblock "$T/coop/root.md" 1 opencode-agent "放在根目录"
run ./coop/coop-lint.sh -q
expect_rc "块没放在功能文件夹 → 失败" 1
expect_has "块没放在功能文件夹 → 报出来" "应放在功能文件夹下"

# ---------------------------------------------------------------- 围栏
section "围栏代码块里的示例不算真块"
reset_coop
mkdir -p "$T/coop/a"
cat > "$T/coop/a/d.md" <<'EOF'
[Index]: 1
[Valid]: true
[Author]: opencode-agent
[Title]: 真块
[GitCommitIds]: null
[Comments]:
  下面是格式示例：

```markdown
[Index]: 99
[Valid]: true
[Author]: ren
[Title]: 代码块里的示例
[Comments]:
  不算
```
EOF
run ./coop/get-index.sh
expect_has "真块还在" "#1"
if [[ "$out" == *"#99"* ]]; then bad "围栏里的示例被当成了真块" "$out"; else ok "围栏里的示例没有被当成真块"; fi
run ./coop/get-index.sh --next
expect_eq "围栏示例不影响下一个编号（=2）" 2 "$out"

# ---------------------------------------------------------------- 过滤
section "get-index 过滤"
reset_coop
mkblock "$T/coop/a/1.md" 1 opencode-agent "有效块"
mkblock "$T/coop/a/2.md" 2 cursor-agent   "作废块" false
mkblock "$T/coop/b/3.md" 3 opencode-agent "另一个功能"
run ./coop/get-index.sh --valid
expect_has "--valid 保留有效块" "#1"
if [[ "$out" == *"#2"* ]]; then bad "--valid 没滤掉作废块" "$out"; else ok "--valid 滤掉了作废块"; fi
run ./coop/get-index.sh --folder a
expect_has "--folder 只留该文件夹" "(a/"
if [[ "$out" == *"(b/"* ]]; then bad "--folder 没滤掉别的文件夹" "$out"; else ok "--folder 滤掉了别的文件夹"; fi

# ---------------------------------------------------------------- record/history
section "回写与历史（需要 git）"
reset_coop
gitq init -q .
gitq commit -q --allow-empty -m "init"
mkblock "$T/coop/orders/x.md" 1 opencode-agent "下单流程"
gitq add -A
gitq commit -qm "feat(orders): 下单流程

三步走状态机。

Coop-Block: 1
Coop-Folder: orders
Coop-Author: opencode-agent"
run ./coop/coop-record.sh 1
expect_rc "回写成功" 0
expect_has "回写后记上分支" "分支:"
capture_commits() { grep '^\[GitCommitIds\]:' "$T/coop/orders/x.md" | tr -d ' '; }
sha1="$(gitq rev-parse --short HEAD)"
expect_eq "首次回写只记一个 sha" "[GitCommitIds]:[\"$sha1\"]" "$(capture_commits)"

gitq commit -qm "docs: 回写块 1 (Coop-Block: 1)"
echo "// 改动" >> "$T/coop/orders/x.md.code" 2>/dev/null || true
mkblock "$T/coop/orders/y.md" 2 opencode-agent "无关块"
gitq add -A
gitq commit -qm "fix(orders): 修一处

Coop-Block: 1
Coop-Folder: orders
Coop-Author: opencode-agent"
run ./coop/coop-record.sh 1
sha2="$(gitq rev-parse --short HEAD)"
expect_eq "续写时新 sha 插在最前" "[GitCommitIds]:[\"$sha2\",\"$sha1\"]" "$(capture_commits)"
run ./coop/coop-record.sh 1 "$sha1"
expect_has "重复 sha 不重复插" "已经记了这个提交"

mkblock "$T/coop/orders/z.md" 1 cursor-agent "撞号"
run ./coop/coop-record.sh 1
expect_rc "撞号时拒绝回写" 1
expect_has "撞号时说明原因" "多个文件里出现"

run ./coop/coop-history.sh 1
expect_rc "history 正常" 0
expect_has "history 列出提交标题" "下单流程"
run ./coop/coop-history.sh 999
expect_rc "history 找不到编号 → 失败" 1

# ---------------------------------------------------------------- 钩子
section "git 钩子"
reset_coop
run ./coop/coop-hook.sh commit-msg /dev/null
expect_rc "commit-msg 空文件放行" 0
printf 'feat: 没有 trailer\n' > "$T/msg"
run ./coop/coop-hook.sh commit-msg "$T/msg"
expect_rc "没有 Coop-Block → 拦下" 1
expect_has "说明原因" "Coop-Block"
printf 'feat: 有 trailer\n\nCoop-Block: 1\n' > "$T/msg"
run ./coop/coop-hook.sh commit-msg "$T/msg"
expect_rc "有 Coop-Block → 放行" 0
printf 'docs: 修错别字\n\nCoop-Skip: 只改了文档\n' > "$T/msg"
run ./coop/coop-hook.sh commit-msg "$T/msg"
expect_rc "有 Coop-Skip（带原因）→ 放行" 0
printf 'docs: 修错别字\n\nCoop-Skip:\n' > "$T/msg"
run ./coop/coop-hook.sh commit-msg "$T/msg"
expect_rc "Coop-Skip 没写原因 → 拦下" 1
expect_has "提示 Coop-Skip 要写原因" "Coop-Skip"
printf 'Merge branch x\n' > "$T/msg"
run ./coop/coop-hook.sh commit-msg "$T/msg"
expect_rc "合并提交放行" 0

reset_coop
gitq init -q . 2>/dev/null || true
mkdir -p "$T/coop/orders"
mkblock "$T/coop/orders/x.md" 1 opencode-agent "要被删的块"
mkblock "$T/coop/orders/x.md" ren-1 ren "人类编号的块"
gitq add -A; gitq commit -qm "init coop
Coop-Block: 1"
sed -i '/^\[Index\]: 1$/,$d' "$T/coop/orders/x.md"
run ./coop/coop-hook.sh pre-commit
expect_rc "删掉块 → 钩子拦下" 1
expect_has "说明只作废不删除" "只作废不删除"

reset_coop
gitq init -q . 2>/dev/null || true
mkdir -p "$T/coop/orders"
mkblock "$T/coop/orders/x.md" 1 opencode-agent "留着"
mkblock "$T/coop/orders/y.md" ren-1 ren "人类编号的块"
gitq add -A; gitq commit -qm "init coop
Coop-Block: 1"
sed -i '/^\[Index\]: ren-1$/,$d' "$T/coop/orders/y.md"
run ./coop/coop-hook.sh pre-commit
expect_rc "删人类编号（ren-1）的块也拦下" 1

# ---------------------------------------------------------------- coop-init --hooks
section "coop-init --hooks（真装钩子并试提交）"
# 按 install.md 的顺序：先把目录铺好，再单独装钩子（--hooks 不再顺带复制脚本）
run "$T/scripts/coop-init.sh"
expect_rc "先跑一次无参数 coop-init" 0
run "$T/scripts/coop-init.sh" --hooks
expect_rc "coop-init --hooks 退出码 0" 0
if [[ -f "$T/.git/hooks/pre-commit" && -f "$T/.git/hooks/commit-msg" ]]; then
  ok "pre-commit / commit-msg 都装上了"
else
  bad "钩子没装上" "$(ls -l "$T/.git/hooks" 2>&1)"
fi
printf 'feat: 没有 trailer\n' > "$T/msg2"
run "$T/agents-cooperation/coop-hook.sh" commit-msg "$T/msg2"
expect_rc "coop-hook.sh 能被钩子调起（bash 而不是 dash）" 1
echo y > "$T/y.txt"
gitq add -A
run gitq commit -m "feat: 没有 trailer"
expect_rc "真实提交没有 trailer → 被钩子拦下" 1
run gitq commit -m "feat: 有 trailer

Coop-Block: 1"
expect_rc "真实提交带 trailer → 通过" 0
echo z > "$T/z.txt"
gitq add -A
run gitq commit -m "docs: 修错别字

Coop-Skip: 只改了文档"
expect_rc "真实提交带 Coop-Skip → 通过" 0

# ---------------------------------------------------------------- coop-init 的同步规矩
section "coop-init：脚本同步要显式、可对账，--hooks 不许碰脚本"
reset_coop
rm -rf "$T/agents-cooperation"       # 从零铺，才能断言"新建"
run "$T/scripts/coop-init.sh"
expect_rc "无参数跑 coop-init" 0
expect_has "报告了'新建'" "新建"
# 再跑一次应该"未变"，不该重复报新建
run "$T/scripts/coop-init.sh"
expect_rc "再跑一次 coop-init" 0
expect_has "第二次全是'未变'" "未变 10 个"
expect_no "第二次不再报'新建'" "新建"

# 手改仓库副本 → --check-sync 必须抓到漂移
printf '\n# 手改的\n' >> "$T/agents-cooperation/coop-lint.sh"
run "$T/agents-cooperation/coop-init.sh" --check-sync
expect_rc "副本被手改 → --check-sync 失败" 1
expect_has "点出是哪个文件漂了" "漂移: coop-lint.sh"

# 从模板重新同步 → 只更新那一个，并且提醒看 git diff
run "$T/scripts/coop-init.sh"
expect_rc "重新同步" 0
expect_has "报告'更新 1 个'" "更新 1 个: coop-lint.sh"
expect_has "提醒先看 git diff" "git -C"

run "$T/agents-cooperation/coop-init.sh" --check-sync
expect_rc "同步后 --check-sync 通过" 0
expect_has "明确说一致" "与模板一致"

# --hooks 不许动脚本（这是它以前的副作用）
before_sum="$(cat "$T/agents-cooperation"/*.sh | md5sum)"
run "$T/scripts/coop-init.sh" --hooks
expect_rc "--hooks 单独跑" 0
after_sum="$(cat "$T/agents-cooperation"/*.sh | md5sum)"
if [[ "$before_sum" == "$after_sum" ]]; then
  ok "--hooks 没有改任何脚本"
else
  bad "--hooks 动了脚本（回归了！）"
fi

# 数据目录还没铺好就跑 --hooks → 拒绝并指路
rm -rf "$T/agents-cooperation"
run "$T/scripts/coop-init.sh" --hooks
expect_rc "没铺目录就跑 --hooks → 拒绝" 1
expect_has "告诉先跑无参数版本" "先跑一次不带参数的 coop-init.sh"

# ---------------------------------------------------------------- 字段读写（曾经的静默失败）
section "字段读写：coop-record 不能再'报成功却没写'"
reset_coop
gitq init -q . 2>/dev/null || true
# ① 块里根本没有 [GitBranch] / [GitCommitIds]（人类手写的块可能这样）
mkdir -p "$T/coop/feat"
printf '# F\n\n[Index]: 1\n[Valid]: true\n[Author]: ren\n[Title]: 缺字段的块\n[Comments]:\n  一\n  二\n' > "$T/coop/feat/a.md"
gitq add -A >/dev/null 2>&1; gitq commit -qm "feat: a
Coop-Block: 1" >/dev/null 2>&1
run ./coop/coop-record.sh 1
expect_rc "缺 GitBranch/GitCommitIds 的块也能回写" 0
if grep -q '^\[GitBranch\]: master$' "$T/coop/feat/a.md" \
   && grep -qE '^\[GitCommitIds\]: \["[0-9a-f]{7,40}"\]$' "$T/coop/feat/a.md"; then
  ok "两个字段被补齐了"
else
  bad "字段没补齐" "$(cat "$T/coop/feat/a.md")"
fi
# 插入位置要在 [Comments] 之前（字段顺序）
if [[ "$(grep -n '^\[GitBranch\]:' "$T/coop/feat/a.md" | cut -d: -f1)" \
    -lt "$(grep -n '^\[Comments\]:' "$T/coop/feat/a.md" | cut -d: -f1)" ]]; then
  ok "GitBranch 插在 [Comments] 之前"
else
  bad "字段插错位置" "$(cat "$T/coop/feat/a.md")"
fi
run ./coop/coop-lint.sh -q
expect_rc "补齐后 lint 依然干净" 0

# ② CRLF 的块（以前会静默不写）
reset_coop
mkdir -p "$T/coop/feat"
printf '# F\r\n\r\n[Index]: 1\r\n[Valid]: true\r\n[Author]: opencode-agent\r\n[Title]: crlf\r\n[GitBranch]: null\r\n[GitCommitIds]: null\r\n[Comments]:\r\n  x\r\n' > "$T/coop/feat/crlf.md"
gitq add -A >/dev/null 2>&1; gitq commit -qm "feat: crlf
Coop-Block: 1" >/dev/null 2>&1
run ./coop/coop-record.sh 1
expect_rc "CRLF 的块也能回写" 0
if grep -qU $'^\[GitBranch\]: master\r$' "$T/coop/feat/crlf.md"; then
  ok "CRLF 里写进去了，且保持 CRLF"
else
  bad "CRLF 回写失效" "$(cat -A "$T/coop/feat/crlf.md")"
fi

# ③ 多块文档：只动目标块；标题要取目标块的（不能再取第一个块的）
reset_coop
mkblock "$T/coop/feat/multi.md" 1 a-agent "第一个块"
mkblock "$T/coop/feat/multi.md" 2 b-agent "第二个块"
gitq add -A >/dev/null 2>&1; gitq commit -qm "feat: multi
Coop-Block: 2" >/dev/null 2>&1
run ./coop/coop-record.sh 2
expect_rc "回写块 2" 0
if grep -q '^\[GitBranch\]: null$' <(sed -n '1,9p' "$T/coop/feat/multi.md"); then
  ok "第一个块没被动过"
else
  bad "误改了别的块" "$(cat "$T/coop/feat/multi.md")"
fi
run ./coop/coop-review.sh 2
expect_has "coop-review 取的是目标块的标题" "第二个块"

# ④ 围栏里的同名字段不动
reset_coop
mkdir -p "$T/coop/feat"
{
  printf '[Index]: 1\n[Valid]: true\n[Author]: opencode-agent\n[Title]: 围栏\n'
  printf '[GitBranch]: null\n[GitCommitIds]: null\n[Comments]:\n'
  printf '下面这是示例，别动它：\n\n```\n[GitBranch]: 示例里也写一个\n```\n'
} > "$T/coop/feat/fence.md"
gitq add -A >/dev/null 2>&1; gitq commit -qm "feat: fence
Coop-Block: 1" >/dev/null 2>&1
run ./coop/coop-record.sh 1
expect_rc "围栏文档也能回写" 0
if grep -q '^\[GitBranch\]: 示例里也写一个$' "$T/coop/feat/fence.md"; then
  ok "围栏里的示例没被改写"
else
  bad "围栏里的示例被改了" "$(cat "$T/coop/feat/fence.md")"
fi

# ⑤ 撞号要拒绝，不能猜
reset_coop
mkblock "$T/coop/feat/x1.md" 7 opencode-agent "一号文件"
mkblock "$T/coop/feat/x2.md" 7 opencode-agent "二号文件"
gitq add -A >/dev/null 2>&1; gitq commit -qm "feat: dup
Coop-Block: 7" >/dev/null 2>&1
run ./coop/coop-record.sh 7
expect_rc "撞号 → 拒绝回写" 1
expect_has "说明是撞号" "多个文件"

# ---------------------------------------------------------------- 新增的 lint 检查
section "lint 新增检查：空数组 / 空格文件夹 / 缺预留表"
reset_coop
mkblock "$T/coop/feat/ok.md" 1 opencode-agent "正常块" true '[]'
run ./coop/coop-lint.sh -q
expect_rc "[GitCommitIds]: [] → 报错" 1
expect_has "说清为什么" "空数组"
rm -f "$T/coop/feat/ok.md"
mkblock "$T/coop/feat/ok2.md" 2 opencode-agent "正常块"
run ./coop/coop-lint.sh -q
expect_rc "改回 null 就好了" 0

reset_coop
mkblock "$T/coop/my feat/sp.md" 1 opencode-agent "空格文件夹"
run ./coop/coop-lint.sh -q
expect_rc "空格文件夹只是警告（不拦）" 0
expect_has "提示文件夹名有空格" "有空格"

reset_coop
mkblock "$T/coop/feat/r.md" 1 opencode-agent "缺预留表"
rm -f "$T/coop/index-reserved.txt"
run ./coop/coop-lint.sh -q
expect_rc "缺 index-reserved.txt 只是警告" 0
expect_has "提示撞号保护会失效" "撞号保护"

# 有警告时汇总行不能还打 ✓（信号混淆）
run ./coop/coop-lint.sh
expect_has "有警告时用 △ 不用 ✓" "△"

# ---------------------------------------------------------------- 非块文档 / 查找 / 自评材料
section "非块文档（_ 开头）+ coop-find + coop-review"
reset_coop
mkblock "$T/coop/orders/x.md" 1 opencode-agent "下单流程：OrderState 状态机"
mkdir -p "$T/coop/_repo"
printf '# 构建说明\n这个文件没有块字段\n' > "$T/coop/_repo/build.md"
run ./coop/coop-lint.sh
expect_rc "说明文档不干扰 lint" 0
expect_has "说明文档不触发「没有块」警告" "格式没问题"
run ./coop/coop-lint.sh -q
if [[ "$out" == *"_repo"* ]]; then bad "说明文档被当成块文件了" "$out"; else ok "说明文档被脚本忽略"; fi
run ./coop/get-index.sh
if [[ "$out" == *"build.md"* ]]; then bad "get-index 把说明文档算进去了" "$out"; else ok "get-index 不数说明文档"; fi

run ./coop/coop-find.sh OrderState
expect_rc "coop-find 按关键词命中" 0
expect_has "命中里带块编号" "#1"
expect_has "命中里带标题" "OrderState 状态机"
run ./coop/coop-find.sh 绝对不存在的关键词xyz
expect_rc "coop-find 搜不到 → 退出码 1" 1
run ./coop/coop-find.sh --id 1
expect_rc "coop-find --id 打出原文" 0
expect_has "原文里有字段" "[Index]: 1"
run ./coop/coop-find.sh --list
expect_rc "coop-find --list" 0

run ./coop/coop-review.sh
expect_rc "coop-review（审未提交改动）" 0
expect_has "给出评分表骨架" "总分"
expect_has "给出等级与处置" "24–29 C"
expect_has "要求列出最不放心的三点" "最不放心"
run ./coop/coop-review.sh 1
expect_rc "coop-review <编号>（还没回写也不崩）" 0
expect_has "提示没有可审的提交" "null"

# ---------------------------------------------------------------- 汇总
printf '\n=========================\n'
printf '通过 %d，失败 %d\n' "$pass" "$fail"
if (( fail == 0 )); then
  printf '全部通过 ✓\n'
  exit 0
fi
printf '有失败 ✗\n'
exit 1
