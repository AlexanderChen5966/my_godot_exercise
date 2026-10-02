## 劇本檢查工具：確認 data/story.json 格式正確、所有圖片/音樂都存在、沒有斷掉的跳轉。
## 用法（終端機）：
##   Godot --headless --path . --script res://tools/validate_story.gd
extends SceneTree

const STORY := "res://data/story.json"
const BG_DIR := "res://assets/bg/"
const BGM_DIR := "res://assets/bgm/"

func _init() -> void:
	var errors: Array[String] = []
	var text := FileAccess.get_file_as_string(STORY)
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		print("✗ story.json 無法解析")
		quit(1)
		return
	var ids := {}
	for s in data["scenes"]:
		ids[int(s["id"])] = s
	if not ids.has(int(data["start_id"])):
		errors.append("start_id %s 不存在" % data["start_id"])
	var ts: Dictionary = data.get("title_screen", {})
	for key in ["bg", "bgm"]:
		if ts.has(key):
			var p: String = (BG_DIR if key == "bg" else BGM_DIR) + ts[key]
			if not ResourceLoader.exists(p):
				errors.append("標題畫面缺檔：%s" % p)
	var endings := 0
	for id in ids:
		var s: Dictionary = ids[id]
		if not ResourceLoader.exists(BG_DIR + s["bg"]):
			errors.append("場景 %d 缺背景：%s" % [id, s["bg"]])
		if not ResourceLoader.exists(BGM_DIR + s["bgm"]):
			errors.append("場景 %d 缺音樂：%s" % [id, s["bgm"]])
		if s.get("is_ending", false):
			endings += 1
		for c in s["choices"]:
			if not ids.has(int(c["next_id"])):
				errors.append("場景 %d 的選項「%s」指向不存在的場景 %s" % [id, c["text"], c["next_id"]])
	print("場景 %d 個、結局 %d 個" % [ids.size(), endings])
	if errors.is_empty():
		print("✓ 劇本檢查通過")
		quit(0)
	else:
		for e in errors:
			print("✗ " + e)
		quit(1)
