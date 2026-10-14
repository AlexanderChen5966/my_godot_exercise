## 劇本資料：讀取 data/story.json，提供依 id 查詢場景。
class_name StoryData
extends RefCounted

const STORY := "res://data/story.json"
const BG_DIR := "res://assets/bg/"
const BGM_DIR := "res://assets/bgm/"

var game_title: String = ""
var start_id: int = 1
var title_screen: Dictionary = {}
var stats: Dictionary = {}  # 數值的初始值（v1.5），例如 { "memory": 0, "humanity": 3 }
var start_area := ""       # 開始遊戲時進入的區域（v1.5）；空字串時從 start_id 的場景開始

var gesture_alone := ""      # A5：附近沒有會反應的人時，第一次比手勢的獨白
var resist_prompt := ""      # A5 壓抑衝動：量表上方的提示
var resist_success := ""     # A5 壓抑衝動：成功時、選項出現前的一句
var _scenes: Dictionary = {}  # int id -> Dictionary


func load_story(path: String = STORY) -> bool:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("無法讀取劇本：%s" % path)
		return false
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("劇本格式錯誤：%s" % path)
		return false
	game_title = data.get("game_title", "")
	start_id = int(data.get("start_id", 1))
	title_screen = data.get("title_screen", {})
	stats = data.get("stats", {})
	start_area = data.get("start_area", "")
	gesture_alone = data.get("gesture_alone", "")
	resist_prompt = data.get("resist_prompt", "")
	resist_success = data.get("resist_success", "")
	_scenes.clear()
	for s in data.get("scenes", []):
		_scenes[int(s["id"])] = s
	return true


func get_scene(id: int) -> Dictionary:
	if not _scenes.has(id):
		push_error("找不到場景 id：%d" % id)
		return {}
	return _scenes[id]


func has_scene(id: int) -> bool:
	return _scenes.has(id)


func scene_ids() -> Array:
	return _scenes.keys()


static func bg_path(file: String) -> String:
	return BG_DIR + file


static func bgm_path(file: String) -> String:
	return BGM_DIR + file
