## 一輪遊戲的全域狀態：旗標、物品、數值、看過的開場。以 autoload「GameState」使用；
## 劇本檢查工具也會 new 一份來模擬。開始新遊戲、回標題時呼叫 reset()。
class_name GameStateData
extends Node

var flags: Dictionary = {}        # 旗標名稱 -> true
var items: Dictionary = {}        # 物品代號 -> true
var stats: Dictionary = {}        # 數值名稱 -> int
var seen_intros: Dictionary = {}  # 區域 id -> true
var _applied: Dictionary = {}     # 已套用過效果的來源（同一個來源一輪只套用一次）


func reset(initial_stats: Dictionary = {}) -> void:
	flags.clear()
	items.clear()
	seen_intros.clear()
	_applied.clear()
	stats.clear()
	for key in initial_stats:
		stats[key] = int(initial_stats[key])


func has_flag(flag: String) -> bool:
	return flags.has(flag)


func set_flag(flag: String) -> void:
	flags[flag] = true


func has_item(item: String) -> bool:
	return items.has(item)


func add_item(item: String) -> void:
	items[item] = true


## 套用數值增減；source 相同的效果一輪只套用一次（例如反覆調查同一處不能重複加記憶）。
## 回傳是否有套用。
func apply_effects(effects: Dictionary, source: String) -> bool:
	if effects.is_empty() or _applied.has(source):
		return false
	_applied[source] = true
	for key in effects:
		stats[key] = int(stats.get(key, 0)) + int(effects[key])
	return true


## 數值門檻：{ "memory": 6, "humanity": 3 }，每一項都要大於或等於才回傳 true。
func meets(minimums: Dictionary) -> bool:
	for key in minimums:
		if int(stats.get(key, 0)) < int(minimums[key]):
			return false
	return true


## 檢查點用：完整複製目前的狀態（Bad End 的「從這裡重試」會還原成這一份）。
func snapshot() -> Dictionary:
	return {
		"flags": flags.duplicate(true), "items": items.duplicate(true), "stats": stats.duplicate(true),
		"seen_intros": seen_intros.duplicate(true), "applied": _applied.duplicate(true),
	}


func restore(snap: Dictionary) -> void:
	flags = snap.get("flags", {}).duplicate(true)
	items = snap.get("items", {}).duplicate(true)
	stats = snap.get("stats", {}).duplicate(true)
	seen_intros = snap.get("seen_intros", {}).duplicate(true)
	_applied = snap.get("applied", {}).duplicate(true)


## 條件：{ items: [...], flags: [...], not_flags: [...], stats: {數值: 最低值} }，全部符合才回傳 true；空條件一律符合。
func check(require: Dictionary) -> bool:
	if not meets(require.get("stats", {})):
		return false
	for item in require.get("items", []):
		if not has_item(item):
			return false
	for flag in require.get("flags", []):
		if not has_flag(flag):
			return false
	for flag in require.get("not_flags", []):
		if has_flag(flag):
			return false
	return true
