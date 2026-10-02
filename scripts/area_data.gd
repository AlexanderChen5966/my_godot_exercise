## 區域資料：讀取 data/areas/*.json，解析 from 引用（文字取自 story.json），提供「場景 id → 區域」查詢。
class_name AreaData
extends RefCounted

const AREA_DIR := "res://data/areas/"
const POINT_TYPES := ["inspect", "approach", "exit"]

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


## 檢查所有區域資料，回傳錯誤訊息清單（空清單＝通過）。給 tools/validate_story.gd 使用。
## warnings 會收到「尚未建立區域場景」這類不算錯誤的提醒。
func validate(story: StoryData, warnings: Array[String] = []) -> Array[String]:
	var errors: Array[String] = []
	for area_id in _areas:
		var area: Dictionary = _areas[area_id]
		var tag := "區域 %s" % area_id
		for scene_id in area.get("replaces_scenes", []):
			if not story.has_scene(int(scene_id)):
				errors.append("%s 的 replaces_scenes 指向不存在的場景 %d" % [tag, int(scene_id)])
		if not area.has("exit_to") or not story.has_scene(int(area["exit_to"])):
			errors.append("%s 的 exit_to 不存在：%s" % [tag, str(area.get("exit_to", "（未設定）")).trim_suffix(".0")])
		if area.has("intro") and resolve(story, area["intro"].get("from", {})).is_empty():
			errors.append("%s 的 intro 引用無效：%s" % [tag, area["intro"]])
		var points: Dictionary = area.get("points", {})
		var exits := 0
		for point_id in points:
			var point: Dictionary = points[point_id]
			if not POINT_TYPES.has(point.get("type", "")):
				errors.append("%s 的互動點 %s 類型不正確：%s" % [tag, point_id, point.get("type")])
			if point.get("type") == "exit":
				exits += 1
			if resolve(story, point.get("from", {})).is_empty():
				errors.append("%s 的互動點 %s 引用無效：%s" % [tag, point_id, point.get("from")])
		if exits == 0:
			errors.append("%s 沒有出口（type: exit）" % tag)
		errors.append_array(_validate_scene_file(area, tag, warnings))
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
