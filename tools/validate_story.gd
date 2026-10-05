## 劇本檢查工具：確認 data/story.json 格式正確、所有圖片/音樂都存在、沒有斷掉的跳轉；
## 並檢查 data/areas/*.json：文字與引用、出口、互動點與區域場景是否對應、物品／旗標／數值是否對得上、每個區域都走得到
## （使用遊戲本身的 StoryData／AreaData）。最後窮舉所有路線：每個結局與 Bad End 都要走得到，並算出數值的上限。
## 用法（終端機）：
##   Godot --headless --path . --script res://tools/validate_story.gd
extends SceneTree

const STORY := "res://data/story.json"
const BG_DIR := "res://assets/bg/"
const BGM_DIR := "res://assets/bgm/"
const ACTIONS := ["retry", "title"]

func _init() -> void:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var text := FileAccess.get_file_as_string(STORY)
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		print("✗ story.json 無法解析")
		quit(1)
		return
	var ids := {}
	for s in data["scenes"]:
		ids[int(s["id"])] = s
	var stats: Dictionary = data.get("stats", {})
	var start_area: String = data.get("start_area", "")
	if start_area.is_empty() and not ids.has(int(data.get("start_id", 1))):
		errors.append("start_id %s 不存在" % data.get("start_id", 1))
	var ts: Dictionary = data.get("title_screen", {})
	for key in ["bg", "bgm"]:
		if ts.has(key):
			var p: String = (BG_DIR if key == "bg" else BGM_DIR) + ts[key]
			if not ResourceLoader.exists(p):
				errors.append("標題畫面缺檔：%s" % p)
	for key in stats:
		if typeof(stats[key]) not in [TYPE_INT, TYPE_FLOAT]:
			errors.append("stats 的 %s 不是數字：%s" % [key, stats[key]])

	var story := StoryData.new()
	var areas := AreaData.new()
	if not story.load_story() or not areas.load_areas():
		print("✗ 劇本或區域資料無法載入")
		quit(1)
		return
	if not start_area.is_empty() and areas.get_area(start_area).is_empty():
		errors.append("start_area 指向不存在的區域：%s" % start_area)

	var endings := 0
	var bad_endings := 0
	for id in ids:
		var s: Dictionary = ids[id]
		var tag := "場景 %d" % id
		if not ResourceLoader.exists(BG_DIR + s["bg"]):
			errors.append("%s 缺背景：%s" % [tag, s["bg"]])
		if not ResourceLoader.exists(BGM_DIR + s["bgm"]):
			errors.append("%s 缺音樂：%s" % [tag, s["bgm"]])
		if s.get("is_ending", false):
			endings += 1
			if s.get("ending_type", "normal") == "bad":
				bad_endings += 1
				var actions: Array = s["choices"].map(func(c): return c.get("action", ""))
				for need in ACTIONS:
					if not actions.has(need):
						errors.append("%s 是 Bad End，但缺少 action「%s」的選項" % [tag, need])
		if s["choices"].is_empty():
			errors.append("%s 沒有選項" % tag)
		for c in s["choices"]:
			var ctag := "%s 的選項「%s」" % [tag, c.get("text", "")]
			var targets := 0
			if c.has("next_id"):
				targets += 1
				if not ids.has(int(c["next_id"])):
					errors.append("%s 指向不存在的場景 %s" % [ctag, str(c["next_id"]).trim_suffix(".0")])
			if c.has("next_area"):
				targets += 1
				if areas.get_area(c["next_area"]).is_empty():
					errors.append("%s 的 next_area 不存在：%s" % [ctag, c["next_area"]])
			if c.has("action"):
				targets += 1
				if not ACTIONS.has(c["action"]):
					errors.append("%s 的 action 只能是 retry 或 title：%s" % [ctag, c["action"]])
			if targets != 1:
				errors.append("%s 要剛好有 next_id、next_area、action 其中一個（目前 %d 個）" % [ctag, targets])
			for key in c.get("effects", {}).keys() + c.get("require", {}).keys():
				if not stats.has(key):
					errors.append("%s 用到數值 %s，但 stats 沒有定義" % [ctag, key])
	print("場景 %d 個、結局 %d 個（其中 Bad End %d 個）" % [ids.size(), endings, bad_endings])
	if not stats.is_empty():
		print("數值：%s" % ", ".join(stats.keys().map(func(k): return "%s=%s" % [k, str(stats[k]).trim_suffix(".0")])))

	errors.append_array(areas.validate(story, warnings))
	for area_id in areas.area_ids():
		var bgm: String = areas.get_area(area_id).get("bgm", "")
		if not bgm.is_empty() and not ResourceLoader.exists(BGM_DIR + bgm):
			errors.append("區域 %s 缺音樂：%s" % [area_id, bgm])
	print("區域 %d 個：%s" % [areas.area_ids().size(), ", ".join(areas.area_ids())])
	if errors.is_empty():
		_check_routes(story, areas, start_area, ids, stats, errors, warnings)

	for w in warnings:
		print("⚠ " + w)
	if errors.is_empty():
		print("✓ 劇本檢查通過")
		quit(0)
	else:
		for e in errors:
			print("✗ " + e)
		quit(1)


## 窮舉路線：從起點沿著區域的出口、區域選項的 to、視覺小說選項的 next_id／next_area 走，
## 列出走得到的結局；數值上限＝每個走得到的來源（互動點／場景）取最大的增加量相加（忽略彼此互斥的選擇，是寬鬆的上限）。
func _check_routes(story: StoryData, areas: AreaData, start_area: String, ids: Dictionary,
		stats: Dictionary, errors: Array[String], warnings: Array[String]) -> void:
	var start := "area:" + start_area if not start_area.is_empty() else "scene:%d" % int(story.start_id)
	var queue: Array = [start]
	var seen := { start: true }
	var best: Dictionary = {}   # 來源 -> { 數值: 最大增加量 }
	var locked: Array = []      # [說明, require]
	while not queue.is_empty():
		var node: String = queue.pop_front()
		var nexts: Array = []
		if node.begins_with("area:"):
			var area_id := node.substr(5)
			var area := areas.get_area(area_id)
			for point_id in area.get("points", {}):
				var point: Dictionary = area["points"][point_id]
				for shape in [point] + point.get("variants", []):
					var merged := point.duplicate()
					merged.erase("variants")
					merged.merge(shape, true)
					if merged.get("type") == "exit":
						nexts.append(AreaData.exit_target(area, merged))
					_note_effects(best, "%s.%s" % [area_id, point_id], merged.get("effects", {}))
					for choice in merged.get("choices", []):
						_note_effects(best, "%s.%s" % [area_id, point_id], choice.get("effects", {}))
						if choice.has("require"):
							locked.append(["區域 %s 的「%s」" % [area_id, choice.get("text", "")], choice["require"]])
						if choice.has("to"):
							nexts.append(choice["to"])
		else:
			var scene: Dictionary = ids[int(node.substr(6))]
			for choice in scene["choices"]:
				_note_effects(best, node, choice.get("effects", {}))
				if choice.has("require"):
					locked.append(["場景 %d 的「%s」" % [int(scene["id"]), choice.get("text", "")], choice["require"]])
				if choice.has("next_id"):
					nexts.append({ "scene": int(choice["next_id"]) })
				if choice.has("next_area"):
					nexts.append({ "area": choice["next_area"] })
		for target in nexts:
			var key: String = "area:" + target["area"] if target.has("area") else "scene:%d" % int(target.get("scene", -1))
			if not seen.has(key) and (target.has("area") or ids.has(int(target.get("scene", -1)))):
				seen[key] = true
				queue.append(key)
	var reached: Array[String] = []
	for id in ids:
		if ids[id].get("is_ending", false):
			if seen.has("scene:%d" % id):
				reached.append("%d %s" % [id, ids[id]["title"]])
			else:
				errors.append("結局／Bad End 走不到：場景 %d %s" % [id, ids[id]["title"]])
	for id in ids:
		if not seen.has("scene:%d" % id):
			warnings.append("場景 %d %s 從起點走不到" % [id, ids[id]["title"]])
	print("走得到的結局：%s" % "、".join(reached))
	var top: Dictionary = stats.duplicate()
	for source in best:
		for key in best[source]:
			top[key] = int(top.get(key, 0)) + int(best[source][key])
	print("數值上限（寬鬆估計）：%s" % ", ".join(top.keys().map(func(k): return "%s=%d" % [k, int(top[k])])))
	for item in locked:
		for key in item[1]:
			if int(top.get(key, 0)) < int(item[1][key]):
				errors.append("%s 需要 %s ≥ %d，但最多只能到 %d" % [item[0], key, int(item[1][key]), int(top.get(key, 0))])


static func _note_effects(best: Dictionary, source: String, effects: Dictionary) -> void:
	if not best.has(source):
		best[source] = {}
	for key in effects:
		best[source][key] = maxi(int(best[source].get(key, 0)), int(effects[key]))
