#!/bin/zsh
# 在「拿掉 MCP 外掛的專案副本」上執行劇本檢查與遊玩測試。
# 不直接對專案跑 headless：外掛的 MCPRuntimeServer 在 headless 也會啟動，會蓋掉 godot-mcp-toolkit 的 runtime 登錄。
# 用法（在專案根目錄）：zsh tests/run_tests.sh            劇本檢查＋所有 tests/test_*.gd
#                      zsh tests/run_tests.sh test_lv4   只跑指定的測試
set -u
PROJECT="${0:A:h:h}"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
COPY="${TMPDIR:-/tmp}/shiyuzhe_test_copy"

echo "== 建立副本：$COPY"
mkdir -p "$COPY"
rsync -a --delete --exclude addons/ --exclude .mcp.json --exclude build/ --exclude .git/ "$PROJECT/" "$COPY/"
sed -i '' '/^MCPRuntimeServer=/d; /^enabled=PackedStringArray("res:\/\/addons\/godot_mcp_toolkit\/plugin.cfg")/d' "$COPY/project.godot"
"$GODOT" --headless --path "$COPY" --import >/dev/null 2>&1

fails=0
echo "\n== 劇本檢查"
"$GODOT" --headless --path "$COPY" --script res://tools/validate_story.gd 2>&1 | grep -v "^Godot Engine\|^$"
[ ${pipestatus[1]} -eq 0 ] || fails=$((fails + 1))

for test in "$COPY"/tests/test_*.gd; do
	name="${test:t:r}"
	[ $# -gt 0 ] && [ "$name" != "$1" ] && continue
	echo "\n== $name"
	"$GODOT" --headless --path "$COPY" --script "res://tests/$name.gd" 2>&1 | grep -v "^Godot Engine\|^$\|leaked at exit\|still in use at exit\|at: cleanup\|at: clear"
	[ ${pipestatus[1]} -eq 0 ] || fails=$((fails + 1))
done

echo ""
if [ $fails -eq 0 ]; then echo "✓ 全部通過"; else echo "✗ 有 $fails 項失敗"; fi
exit $fails
