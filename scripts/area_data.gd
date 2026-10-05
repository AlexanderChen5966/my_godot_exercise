## 區域資料：讀取 data/areas/*.json，提供「場景 id → 區域」查詢、互動點的文字與條件判斷，以及劇本檢查。
## 格式見 docs/Lv製作流程.md 的 Lv4「資料格式」。文字可以直接寫在資料裡（title／text），也可以用 Lv1 的 from 引用 story.json。
class_name AreaData
extends RefCounted

const AREA_DIR := "res://data/areas/"
const POINT_TYPES := ["inspect", "item", "choice", "exit", "approach"]
const TRIGGERS := ["interact", "approach"]
const ONCE_BY_DEFAULT := ["item", "choice"]

var _areas: Dictionary = {}     # 區域 id -> 區域 Dictionary
var _by_scene: Dictionary = {}  # 被接管的場景 id -> 區域 id


func load_areas(dir: String = AREA_DIR) -> bool:
	_areas.clear()
	_by_scene.clear()
	var ok := true
	for file in DirAccess.get_files_at(dir):
		if not file.ends_with(".json"):
			continue
		var data = JSON.parse_string(FileAccess.get_file_as_string(dir + file))
		if typeof(data) != TYPE_DICTIONARY or not data.has("id"):
			push_error("區域資料格式錯誤：%s" % file)
			ok = false
			continue
		_areas[data["id"]] = data
		for scene_id in data.get("replaces_scenes", []):
			_by_scene[int(scene_id)] = data["id"]
	return ok


## 回傳接管這個場景的區域；沒有被接管時回傳空字典。
func area_for_scene(scene_id: int) -> Dictionary:
	if not _by_scene.has(scene_id):
		return {}
	return _areas[_by_scene[scene_id]]


func get_area(area_id: String) -> Dictionary:
	return _areas.get(area_id, {})


func area_ids() -> Array:
	return _areas.keys()


# ---- 互動點 ----

## 依目前狀態套用 variants：由上往下找第一個 require 符合的，用它的欄位覆蓋互動點本身的欄位。
## 套用了第幾個 variant 記在 "_variant"（once 的判斷要分開：沒拿錄音筆時看過診療椅，不代表坐下聽過錄音）。
static func view(point: Dictionary, state: GameStateData) -> Dictionary:
	var result := point.duplicate()
	result.erase("variants")
	var variants: Array = point.get("variants", [])
	for i in variants.size():
		if state.check(variants[i].get("require", {})):
			for key in variants[i]:
				if key != "require":
					result[key] = variants[i][key]
			result["_variant"] = i
			break
	return result


## once 用的完成紀錄代號：互動點本身用「區域.互動點」，套用 variant 時加上「#編號」。
static func done_key(point_key: String, view_point: Dictionary) -> String:
	if view_point.has("_variant"):
		return "%s#%d" % [point_key, int(view_point["_variant"])]
	return point_key


## 互動點本身的 require 是否符合（不符合時互動點不反應）。
static func is_available(point: Dictionary, state: GameStateData) -> bool:
	return state.check(point.get("require", {}))


## interact：靠近後按互動鍵；approach：走進範圍自動觸發（Lv1 的 type: approach 也算）。
static func trigger_of(point: Dictionary) -> String:
	return point.get("trigger", "approach" if point.get("type") == "approach" else "interact")


static func is_once(point: Dictionary) -> bool:
	return point.get("once", ONCE_BY_DEFAULT.has(point.get("type", "")))


## 對話框的標題與內文：優先用資料裡的 title／text，沒有時用 from 引用。
static func text_of(story: StoryData, holder: Dictionary) -> Dictionary:
	if holder.has("text"):
		return { "title": holder.get("title", ""), "text": holder["text"] }
	return resolve(story, holder.get("from", {}))


## 出口的去處：{ "area": id } 或 { "scene": id }；沒寫 to 時用區域的 exit_to（Lv1 格式）。
static func exit_target(area: Dictionary, point: Dictionary) -> Dictionary:
	if point.has("to"):
		return point["to"]
	if area.has("exit_to"):
		return { "scene": int(area["exit_to"]) }
	return {}


## 解析 from 引用，回傳 { "title": 對話框標題, "text": 內文 }；引用無效時回傳空字典。
## { scene: N }             → 場景 N 的 title 與 text
## { scene: N, choice: i }  → 場景 N 第 i 個選項的 text（當標題）與 response
static func resolve(story: StoryData, from: Dictionary) -> Dictionary:
	if not from.has("scene") or not story.has_scene(int(from["scene"])):
		return {}
	var scene := story.get_scene(int(from["scene"]))
	if not from.has("choice"):
		return { "title": scene["title"], "text": scene["text"] }
	var index := int(from["choice"])
	var choices: Array = scene["choices"]
	if index < 0 or index >= choices.size():
		return {}
	return { "title": choices[index]["text"], "text": choices[index]["response"] }


# ---- 劇本檢查 ----

## 檢查所有區域資料，回傳錯誤訊息清單（空清單＝通過）。給 tools/validate_story.gd 使用。
## warnings 會收到「尚未建立區域場景」這類不算錯誤的提醒。
func validate(story: StoryData, warnings: Array[String] = []) -> Array[String]:
	var errors: Array[String] = []
	var given_items := {}    # 拿得到的物品
	var set_flags := {}      # 有地方設定的旗標
	var needed: Array = []   # [說明, "items"／"flags", 名稱]
	var stat_keys := {}      # effects 用到的數值名稱 -> 說明
	for area_id in _areas:
		var area: Dictionary = _areas[area_id]
		var tag := "區域 %s" % area_id
		for scene_id in area.get("replaces_scenes", []):
			if not story.has_scene(int(scene_id)):
				errors.append("%s 的 replaces_scenes 指向不存在的場景 %d" % [tag, int(scene_id)])
		if area.has("exit_to") and not story.has_scene(int(area["exit_to"])):
			errors.append("%s 的 exit_to 不存在：%s" % [tag, str(area["exit_to"]).trim_suffix(".0")])
		if area.has("intro") and text_of(story, area["intro"]).is_empty():
			errors.append("%s 的開場沒有文字或引用無效：%s" % [tag, area["intro"]])
		for key in area.get("spawns", {}):
			if key != "default" and not _areas.has(key):
				errors.append("%s 的 spawns 指向不存在的區域：%s" % [tag, key])
		var points: Dictionary = area.get("points", {})
		var exits := 0
		for point_id in points:
			var point: Dictionary = points[point_id]
			var ptag := "%s 的互動點 %s" % [tag, point_id]
			set_flags["%s.%s" % [area_id, point_id]] = true  # 自動旗標
			_collect_require(point.get("require", {}), ptag, needed)
			# 互動點本身與每一個 variant 都要各自完整
			var shapes: Array = [point]
			for variant in point.get("variants", []):
				_collect_require(variant.get("require", {}), ptag, needed)
				var merged := point.duplicate()
				merged.erase("variants")
				for key in variant:
					if key != "require":
						merged[key] = variant[key]
				shapes.append(merged)
			for shape in shapes:
				if shape.get("type") == "exit":
					exits += 1
				errors.append_array(_validate_shape(story, area, shape, ptag))
				if shape.get("type") == "item" and shape.has("item"):
					given_items[shape["item"]] = true
				for flag in shape.get("set_flags", []):
					set_flags[flag] = true
				for key in shape.get("effects", {}):
					stat_keys[key] = ptag
				for choice in shape.get("choices", []):
					if choice.has("item"):
						given_items[choice["item"]] = true
					for flag in choice.get("set_flags", []):
						set_flags[flag] = true
					for key in choice.get("effects", {}):
						stat_keys[key] = ptag
		if exits == 0:
			errors.append("%s 沒有出口（type: exit）" % tag)
		errors.append_array(_validate_scene_file(area, tag, warnings))
	for need in needed:
		if need[1] == "items" and not given_items.has(need[2]):
			errors.append("%s 需要物品 %s，但沒有任何 item 互動點給這個物品" % [need[0], need[2]])
		if need[1] == "flags" and not set_flags.has(need[2]):
			errors.append("%s 用到旗標 %s，但沒有地方設定它" % [need[0], need[2]])
	for key in stat_keys:
		if not story.stats.has(key):
			errors.append("%s 的 effects 用到 %s，但 story.json 的 stats 沒有定義" % [stat_keys[key], key])
	errors.append_array(_validate_reachable(story))
	return errors


static func _collect_require(require: Dictionary, ptag: String, needed: Array) -> void:
	for item in require.get("items", []):
		needed.append([ptag, "items", item])
	for flag in require.get("flags", []) + require.get("not_flags", []):
		needed.append([ptag, "flags", flag])


## 單一互動點（或套用 variant 後）的欄位檢查。
func _validate_shape(story: StoryData, area: Dictionary, shape: Dictionary, ptag: String) -> Array[String]:
	var errors: Array[String] = []
	var type: String = shape.get("type", "")
	if not POINT_TYPES.has(type):
		errors.append("%s 類型不正確：%s" % [ptag, type])
		return errors
	if shape.has("trigger") and not TRIGGERS.has(shape["trigger"]):
		errors.append("%s 的 trigger 不正確：%s" % [ptag, shape["trigger"]])
	var has_text := not text_of(story, shape).is_empty()
	if type == "exit":
		# 出口可以沒有文字（直接換區域），但有寫 from 時引用要有效
		if shape.has("from") and not has_text:
			errors.append("%s 引用無效：%s" % [ptag, shape["from"]])
		errors.append_array(_validate_target(story, exit_target(area, shape), ptag))
	elif not has_text:
		errors.append("%s 沒有文字或引用無效" % ptag)
	if type == "item" and str(shape.get("item", "")).is_empty():
		errors.append("%s 是 item，但沒有寫 item（物品代號）" % ptag)
	if type == "choice":
		var choices: Array = shape.get("choices", [])
		if choices.is_empty():
			errors.append("%s 是 choice，但沒有選項" % ptag)
		for choice in choices:
			if str(choice.get("text", "")).is_empty() or str(choice.get("response", "")).is_empty():
				errors.append("%s 的選項缺少 text 或 response：%s" % [ptag, choice])
			if choice.has("to"):
				errors.append_array(_validate_target(story, choice["to"], "%s 的選項「%s」" % [ptag, choice.get("text", "")]))
			for key in choice.get("require", {}):
				if not story.stats.has(key):
					errors.append("%s 的選項 require 用到 %s，但 story.json 的 stats 沒有定義" % [ptag, key])
	return errors


func _validate_target(story: StoryData, target: Dictionary, ptag: String) -> Array[String]:
	var errors: Array[String] = []
	if target.has("area"):
		if not _areas.has(target["area"]):
			errors.append("%s 的出口通往不存在的區域：%s" % [ptag, target["area"]])
	elif target.has("scene"):
		if not story.has_scene(int(target["scene"])):
			errors.append("%s 的出口通往不存在的場景：%s" % [ptag, str(target["scene"]).trim_suffix(".0")])
	else:
		errors.append("%s 是出口，但沒有 to，區域也沒有 exit_to" % ptag)
	return errors


## 從入口出發（story.json 的 start_area、視覺小說選項的 next_area、被接管的場景），
## 沿著出口與選項的 to.area，每個區域都要走得到。
func _validate_reachable(story: StoryData) -> Array[String]:
	var errors: Array[String] = []
	var queue: Array = []
	var seen := {}
	var entries: Array = [story.start_area]
	for scene_id in story.scene_ids():
		for choice in story.get_scene(scene_id).get("choices", []):
			entries.append(choice.get("next_area", ""))
	for area_id in _areas:
		if not _areas[area_id].get("replaces_scenes", []).is_empty():
			entries.append(area_id)
	for area_id in entries:
		if _areas.has(area_id) and not seen.has(area_id):
			queue.append(area_id)
			seen[area_id] = true
	while not queue.is_empty():
		var area: Dictionary = _areas[queue.pop_front()]
		for point_id in area.get("points", {}):
			var point: Dictionary = area["points"][point_id]
			for shape in [point] + point.get("variants", []):
				var targets: Array = [shape.get("to", {})]
				for choice in shape.get("choices", []):
					targets.append(choice.get("to", {}))
				for target in targets:
					var next_id = target.get("area", "")
					if _areas.has(next_id) and not seen.has(next_id):
						seen[next_id] = true
						queue.append(next_id)
	for area_id in _areas:
		if not seen.has(area_id):
			errors.append("區域 %s 走不到（不是 start_area、沒有視覺小說進入它，也沒有出口通往它）" % area_id)
	return errors


## 區域場景存在時，比對場景裡互動點的 point_id 與 JSON 的 points 是否一一對應。
func _validate_scene_file(area: Dictionary, tag: String, warnings: Array[String]) -> Array[String]:
	var errors: Array[String] = []
	var path: String = area.get("scene", "")
	if path.is_empty():
		errors.append("%s 沒有指定 scene" % tag)
		return errors
	if not ResourceLoader.exists(path):
		warnings.append("%s 的區域場景尚未建立：%s" % [tag, path])
		return errors
	var instance := (load(path) as PackedScene).instantiate()
	var in_scene: Array[String] = []
	for node in instance.find_children("*", "", true, false):
		if "point_id" in node and not str(node.get("point_id")).is_empty():
			in_scene.append(str(node.get("point_id")))
	instance.free()
	var in_json: Array = area.get("points", {}).keys()
	for point_id in in_json:
		if not in_scene.has(point_id):
			errors.append("%s：JSON 的互動點 %s 在場景中找不到" % [tag, point_id])
	for point_id in in_scene:
		if not in_json.has(point_id):
			errors.append("%s：場景中的互動點 %s 在 JSON 裡沒有資料" % [tag, point_id])
	return errors
