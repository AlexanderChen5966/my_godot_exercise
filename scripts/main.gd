## 主畫面：顯示場景與選項；點選項後先顯示 response，再點擊前往 next_id。
## 主文字與 response 以打字機效果顯示，換場時背景淡出淡入，BGM 以兩個播放器交替淡入淡出。
extends Control

enum State { TITLE, TRANSITION, TYPING, CHOOSING, RESPONSE, EXPLORE, AREA_TEXT }

const EXTRA_HINT_COLOR := "#a8a8a8"
const CHOSEN_MODULATE := Color(1, 1, 1, 0.45)
const CHARS_PER_SECOND := 30.0
const SILENT_CHARS := " \n，。、！？：；「」『』（）…—,.!?:;\"'()-"  # 打到這些字元時不出打字聲
const FADE_HALF_TIME := 0.2  # 淡出 + 淡入共約 0.4 秒
const BGM_FADE_TIME := 0.8
const LOCKED_TEXT := "……（你想不起來）"   # 數值不夠時，選項顯示的文字
const ENDING_LABEL := "— 結局 —"
const BAD_ENDING_COLOR := Color(0.85, 0.35, 0.3)

# 節點都設為 unique name（%Name），之後搬動節點層級時不用改這裡。
@onready var background: TextureRect = %Background
@onready var world: Node2D = %World
@onready var fade: ColorRect = %Fade
@onready var title_layer: Control = %TitleLayer
@onready var title_label: Label = %TitleLabel
@onready var start_label: Label = %StartLabel
@onready var story_layer: Control = %StoryLayer
@onready var dialog_panel: PanelContainer = %DialogPanel
@onready var ending_tag: Label = %EndingTag
@onready var scene_title: Label = %SceneTitle
@onready var body: RichTextLabel = %Body
@onready var hint: RichTextLabel = %Hint
@onready var continue_label: Label = %Continue
@onready var choices_box: VBoxContainer = %Choices
@onready var bgm_players: Array[AudioStreamPlayer] = [%BgmA, %BgmB]
@onready var sfx: AudioStreamPlayer = %Sfx
@onready var type_sfx: AudioStreamPlayer = %TypeSfx
@onready var rotate_hint: ColorRect = %RotateHint
@onready var prompt_label: Label = %PromptLabel

var story := StoryData.new()
var areas := AreaData.new()
var _area: Node2D = null  # 目前在 World 底下的區域場景
var _area_id := ""
var _nearby_point := ""      # 玩家目前所在範圍內、可按互動鍵的互動點
var _closing_point := ""     # 目前顯示的區域文字屬於哪個互動點（開場文字為空字串）
var _closing_view: Dictionary = {}  # 打開時套用 variants 後的互動點內容（關閉時用同一份，不受途中狀態改變影響）
var _area_choosing := false  # 目前的選項屬於區域的 choice 互動點（不是視覺小說的選項）
var _area_choice: Dictionary = {}     # 區域裡選了哪個選項（有 to 時，關閉文字後前往）
var _pending_choice: Dictionary = {}  # 視覺小說裡選了哪個選項（回應讀完後決定去處）
var _checkpoint: Dictionary = {}      # Bad End「從這裡重試」回到的位置與狀態
var _debug_label: Label               # F3 數值顯示（只在 debug 版建立）
var current_id: int = -1
var state: State = State.TITLE
var _pending_next_id: int = -1
var _chosen_in_scene: Dictionary = {}  # 本場景已選過的選項索引（留在原地時變暗）

var _button_styles: Dictionary = {}  # 狀態名稱 -> StyleBoxFlat
var _typing_tween: Tween
var _after_typing: Callable
var _typed_text := ""        # 目前打字中的純文字（判斷標點用）
var _typed_count := 0
var _next_tick_at := 0        # 打到第幾個字時發出下一次打字聲
var _type_base_db := 0.0

var _audio_unlocked := false  # 瀏覽器要求使用者互動後才能播放聲音
var _bgm_file := ""           # 目前播放（或淡入中）的曲目
var _bgm_index := 0           # bgm_players 中目前使用的播放器
var _bgm_tween: Tween
var _start_blink: Tween


func _ready() -> void:
	_type_base_db = type_sfx.volume_db
	_setup_style()
	get_window().size_changed.connect(_on_window_resized)
	_on_window_resized()
	if not story.load_story():
		return
	areas.load_areas()
	if OS.is_debug_build():
		_create_debug_label()
	show_title()


## StyleBox 與主題覆寫在這裡設定（按鈕是動態產生的，樣式需由程式套用）。
func _setup_style() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0.65)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(20)
	dialog_panel.add_theme_stylebox_override("panel", box)

	scene_title.add_theme_font_size_override("font_size", 26)
	scene_title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.6))
	body.add_theme_font_size_override("normal_font_size", 20)
	body.add_theme_constant_override("line_separation", 6)
	hint.add_theme_font_size_override("normal_font_size", 18)
	continue_label.add_theme_font_size_override("font_size", 18)
	continue_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.6))

	choices_box.add_theme_constant_override("separation", 10)
	var bg_colors := {
		"normal": Color(0.08, 0.08, 0.1, 0.8),
		"hover": Color(0.25, 0.2, 0.12, 0.9),
		"pressed": Color(0.4, 0.3, 0.15, 0.95),
	}
	for style_name in bg_colors:
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg_colors[style_name]
		sb.set_corner_radius_all(6)
		sb.set_border_width_all(1)
		sb.border_color = Color(1.0, 0.86, 0.6, 0.5)
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		_button_styles[style_name] = sb
	_button_styles["focus"] = _button_styles["hover"]
	var disabled: StyleBoxFlat = _button_styles["normal"].duplicate()
	disabled.bg_color = Color(0.05, 0.05, 0.06, 0.55)
	disabled.border_color = Color(1.0, 0.86, 0.6, 0.15)
	_button_styles["disabled"] = disabled


func show_title() -> void:
	current_id = -1
	_free_area()  # 從區域中回到標題時，一併釋放區域
	background.visible = true
	dialog_panel.visible = true
	title_label.text = story.game_title
	background.texture = load(StoryData.bg_path(story.title_screen["bg"]))
	title_layer.visible = true
	story_layer.visible = false
	ending_tag.visible = false
	if fade.color.a > 0.0:
		# 從結局回來：黑幕淡出後才接受點擊
		state = State.TRANSITION
		var tween := create_tween()
		tween.tween_property(fade, "color:a", 0.0, FADE_HALF_TIME)
		tween.tween_callback(func() -> void: state = State.TITLE)
	else:
		state = State.TITLE
	if _audio_unlocked:
		play_bgm(story.title_screen["bgm"])
	if _start_blink:
		_start_blink.kill()
	start_label.modulate.a = 1.0
	_start_blink = create_tween().set_loops()
	_start_blink.tween_property(start_label, "modulate:a", 0.3, 0.9)
	_start_blink.tween_property(start_label, "modulate:a", 1.0, 0.9)


func _start_game() -> void:
	GameState.reset(story.stats)  # 新的一輪：清空旗標、物品，數值回到初始值
	_audio_unlocked = true
	sfx.play()
	if _start_blink:
		_start_blink.kill()
		_start_blink = null
	state = State.TRANSITION
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, FADE_HALF_TIME)
	tween.tween_callback(func() -> void:
		title_layer.visible = false
		story_layer.visible = true
		scene_title.text = ""
		body.text = ""
		_clear_choices()
		hint.visible = false
		continue_label.visible = false
		_checkpoint = {}
		if not story.start_area.is_empty():
			enter_area(story.start_area, -1, false)  # v1.5：直接從停車場開始
		else:
			show_scene(story.start_id, false)
	)


## 把區域場景實例化到 World 底下（同時只會有一個區域）。
## from_area：從哪個區域走過來，用來決定出現位置（spawns）；從視覺小說進來時為空字串。
func _instantiate_area(area_id: String, from_area := "") -> Node2D:
	_free_area()
	var area := areas.get_area(area_id)
	_area = (load(area["scene"]) as PackedScene).instantiate()
	_area_id = area_id
	_nearby_point = ""
	world.add_child(_area)
	_area.point_entered.connect(_on_point_entered)
	_area.point_exited.connect(_on_point_exited)
	var spawns: Dictionary = area.get("spawns", {})
	var spawn_key := from_area if spawns.has(from_area) else "default"
	if spawns.has(spawn_key):
		_area.place_player(float(spawns[spawn_key]))
	# 已經完成的事件（例如婦人逃走），回到這個區域時不再出現
	var points: Dictionary = area.get("points", {})
	for point_id in points:
		if _is_done(point_id) and _hides_when_done(points[point_id]):
			_area.consume_point(point_id)
	return _area


func _free_area() -> void:
	if _area:
		_area.queue_free()
		_area = null
	_area_id = ""
	_nearby_point = ""
	_area_choosing = false
	prompt_label.visible = false


## 進入區域：淡出 → 實例化區域到 World → 隱藏 Background → 換 BGM → 淡入 → 開場文字（同一輪只顯示一次）。
## fade_out 為 false 時表示畫面已經是黑的（例如從標題「開始」進來）。
## from_area：從另一個區域走過來時的來源區域（決定出現位置）。
func enter_area(area_id: String, scene_id: int, fade_out := true, from_area := "") -> void:
	var area := areas.get_area(area_id)
	_save_checkpoint({ "area": area_id, "from": from_area })  # 進入區域時的狀態（開場還沒看過）
	current_id = scene_id
	state = State.TRANSITION
	if area.has("bgm"):
		play_bgm(area["bgm"])
	var tween := create_tween()
	if fade_out:
		tween.tween_property(fade, "color:a", 1.0, FADE_HALF_TIME)
	else:
		fade.color.a = 1.0
	tween.tween_callback(func() -> void:
		_instantiate_area(area_id, from_area)
		title_layer.visible = false
		background.visible = false
		story_layer.visible = true
		dialog_panel.visible = false
		_clear_choices()
	)
	tween.tween_property(fade, "color:a", 0.0, FADE_HALF_TIME)
	tween.tween_callback(func() -> void:
		if area.has("intro") and not GameState.seen_intros.has(area_id):
			GameState.seen_intros[area_id] = true
			_show_area_text(area["intro"])
		else:
			_begin_explore()
	)


## 離開區域：淡出 → 釋放區域 → 顯示 Background → 回到視覺小說流程的 next_id。
func leave_area(next_id: int) -> void:
	state = State.TRANSITION
	_area.set_can_move(false)
	prompt_label.visible = false
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, FADE_HALF_TIME)
	tween.tween_callback(func() -> void:
		_free_area()
		background.visible = true
		dialog_panel.visible = true
		scene_title.text = ""
		body.text = ""
		show_scene(next_id, false)
	)


## 互動點目前的內容：依 GameState 套用 variants。
func _area_point(point_id: String) -> Dictionary:
	var raw: Dictionary = areas.get_area(_area_id).get("points", {}).get(point_id, {})
	return AreaData.view(raw, GameState)


## 互動點現在能不能觸發：require 不符合、或 once 且（這個 variant）已完成時不反應。
func _point_active(point_id: String, point: Dictionary) -> bool:
	if point.is_empty() or not AreaData.is_available(point, GameState):
		return false
	var done := GameState.has_flag(AreaData.done_key(_point_key(point_id), point))
	return not (AreaData.is_once(point) and done)


## 可操作狀態：隱藏對話框，讓主角可以移動。
func _begin_explore() -> void:
	state = State.EXPLORE
	dialog_panel.visible = false
	continue_label.visible = false
	_area.set_can_move(true)
	_update_prompt()


func _update_prompt() -> void:
	var point := _area_point(_nearby_point) if not _nearby_point.is_empty() else {}
	if state != State.EXPLORE or not _point_active(_nearby_point, point):
		prompt_label.visible = false
		return
	prompt_label.text = "E　%s" % point.get("label", "調查")
	prompt_label.visible = true


func _on_point_entered(point_id: String) -> void:
	var point := _area_point(point_id)
	if AreaData.trigger_of(point) == "approach":
		# 接近類：走進範圍自動觸發（遇到人的時候）
		if state == State.EXPLORE and _point_active(point_id, point):
			_show_area_text(point, point_id)
		return
	_nearby_point = point_id
	_update_prompt()


func _on_point_exited(point_id: String) -> void:
	if _nearby_point == point_id:
		_nearby_point = ""
		_update_prompt()


## 區域文字：沿用對話框與打字機。choice 打完字後顯示選項，其他類型顯示「點擊繼續」。
## 調查、撿東西的數值效果在打開時套用（同一個互動點一輪只算一次）。
func _show_area_text(holder: Dictionary, point_id := "") -> void:
	var resolved := AreaData.text_of(story, holder)
	_closing_point = point_id
	_closing_view = holder
	if not point_id.is_empty() and holder.get("type") != "choice":
		GameState.apply_effects(holder.get("effects", {}), AreaData.done_key(_point_key(point_id), holder))
	_area.set_can_move(false)
	prompt_label.visible = false
	dialog_panel.visible = true
	ending_tag.visible = false
	hint.visible = false
	continue_label.visible = false
	_clear_choices()
	scene_title.text = resolved.get("title", "")
	if holder.get("type") == "choice":
		_type_text(resolved.get("text", ""), _show_area_choices.bind(holder.get("choices", [])))
	else:
		_type_text(resolved.get("text", ""), _show_area_continue)


func _show_area_continue() -> void:
	state = State.AREA_TEXT
	if _closing_view.get("type") == "item" and _closing_view.has("item_name"):
		hint.text = "[color=%s]（獲得：%s）[/color]" % [EXTRA_HINT_COLOR, _closing_view["item_name"]]
		hint.visible = true
	continue_label.visible = true


## 區域的選項：沿用視覺小說的按鈕；自動選好第一個，可以用方向鍵與 Enter／空白鍵操作（可走動區域只用鍵盤）。
func _show_area_choices(choices: Array) -> void:
	state = State.CHOOSING
	_area_choosing = true
	_chosen_in_scene.clear()
	_build_choices(choices)
	for button in choices_box.get_children():
		if not (button as Button).disabled:
			(button as Button).grab_focus()
			break


func _on_area_choice_pressed(choice: Dictionary) -> void:
	_area_choosing = false
	_area_choice = choice
	sfx.play()
	_clear_choices()
	GameState.apply_effects(choice.get("effects", {}), AreaData.done_key(_point_key(_closing_point), _closing_view))
	for flag in choice.get("set_flags", []):
		GameState.set_flag(flag)
	_type_text(choice.get("response", ""), _show_area_continue)


func _close_area_text() -> void:
	var point_id := _closing_point
	var point := _closing_view
	_closing_point = ""
	_closing_view = {}
	hint.visible = false
	if point_id.is_empty():  # 開場文字
		_begin_explore()
		return
	_mark_done(point_id)
	GameState.set_flag(AreaData.done_key(_point_key(point_id), point))  # variant 自己的完成紀錄
	if point.get("type") == "item" and point.has("item"):
		GameState.add_item(point["item"])
	for flag in point.get("set_flags", []):
		GameState.set_flag(flag)
	if _hides_when_done(point):
		_area.consume_point(point_id)  # 例如婦人逃走後消失
	var chosen := _area_choice
	_area_choice = {}
	if chosen.has("to"):
		_go_to(chosen["to"])  # 例如警衛逼近時選「停下不動」→ Bad End
		return
	if point.get("type") == "exit":
		_go_through_exit(point)
		return
	_begin_explore()


## 互動點觸發過後設定自動旗標「區域.互動點」（同一輪記得，換區域、回頭走都有效）。
func _mark_done(point_id: String) -> void:
	GameState.set_flag(_point_key(point_id))


func _is_done(point_id: String) -> bool:
	return GameState.has_flag(_point_key(point_id))


## 互動點在整個遊戲中的代號「區域.互動點」：自動旗標與數值效果的來源都用它。
func _point_key(point_id: String) -> String:
	return "%s.%s" % [_area_id, point_id]


## 完成後要隱藏場景中人物或道具的互動點：hide_on_done，或 Lv1 格式的 approach（婦人）。
func _hides_when_done(point: Dictionary) -> bool:
	return point.get("hide_on_done", point.get("type") == "approach")


## 出口：通往另一個區域（to.area），或接回視覺小說（to.scene／Lv1 的 exit_to）。
func _go_through_exit(point: Dictionary) -> void:
	_go_to(AreaData.exit_target(areas.get_area(_area_id), point))


## 從區域前往 { "area": id }（另一個區域）或 { "scene": id }（視覺小說／Bad End）。
func _go_to(target: Dictionary) -> void:
	if target.has("area"):
		_switch_area(target["area"])
	elif target.has("scene"):
		leave_area(int(target["scene"]))


## 區域之間移動：記住從哪裡來，決定在新區域的出現位置。
func _switch_area(next_area: String) -> void:
	var from_area := _area_id
	_area.set_can_move(false)
	prompt_label.visible = false
	enter_area(next_area, -1, true, from_area)


## 換曲：與目前曲目相同時不重播；不同時舊曲淡出、新曲淡入。
func play_bgm(file: String) -> void:
	if file == _bgm_file:
		return
	_bgm_file = file
	var old := bgm_players[_bgm_index]
	_bgm_index = 1 - _bgm_index
	var new := bgm_players[_bgm_index]
	if _bgm_tween:
		_bgm_tween.kill()
	new.stop()
	new.stream = load(StoryData.bgm_path(file))
	new.volume_linear = 0.0
	new.play()
	_bgm_tween = create_tween().set_parallel()
	_bgm_tween.tween_property(new, "volume_linear", 1.0, BGM_FADE_TIME)
	if old.playing:
		_bgm_tween.tween_property(old, "volume_linear", 0.0, BGM_FADE_TIME)
		_bgm_tween.chain().tween_callback(old.stop)


func show_scene(id: int, fade_out := true) -> void:
	var scene := story.get_scene(id)
	if scene.is_empty():
		return
	# 被區域接管的場景：改成進入可走動的區域，不顯示視覺小說畫面
	var area := areas.area_for_scene(id)
	if not area.is_empty():
		enter_area(area["id"], id, fade_out)
		return
	_clear_choices()
	hint.visible = false
	continue_label.visible = false
	dialog_panel.visible = true

	if id == current_id:
		# 留在原場景：已讀過的主文字直接完整顯示，重新給選項。
		body.text = scene["text"]
		body.visible_ratio = 1.0
		_show_choices(scene)
		return

	current_id = id
	_chosen_in_scene.clear()
	if not scene.get("is_ending", false):
		_save_checkpoint({ "scene": id })
	state = State.TRANSITION
	play_bgm(scene["bgm"])
	var tween := create_tween()
	if fade_out:
		tween.tween_property(fade, "color:a", 1.0, FADE_HALF_TIME)
	else:
		fade.color.a = 1.0
	tween.tween_callback(func() -> void:
		background.texture = load(StoryData.bg_path(scene["bg"]))
		scene_title.text = scene["title"]
		ending_tag.visible = scene.get("is_ending", false)
		ending_tag.text = scene.get("ending_label", ENDING_LABEL)
		var bad: bool = scene.get("ending_type", "normal") == "bad"
		ending_tag.add_theme_color_override("font_color", BAD_ENDING_COLOR if bad else Color(1, 1, 1))
		body.text = ""
	)
	tween.tween_property(fade, "color:a", 0.0, FADE_HALF_TIME)
	tween.tween_callback(func() -> void:
		_type_text(scene["text"], _show_choices.bind(scene))
	)


func _show_choices(scene: Dictionary) -> void:
	state = State.CHOOSING
	_show_hint(scene)
	_build_choices(scene["choices"])


func _show_hint(scene: Dictionary) -> void:
	var text: String = scene.get("hint", "")
	var extra: String = scene.get("extra_hint", "")
	if not extra.is_empty():
		text += "\n[color=%s]%s[/color]" % [EXTRA_HINT_COLOR, extra]
	hint.text = text
	hint.visible = not text.is_empty()


func _build_choices(choices: Array) -> void:
	_clear_choices()
	for i in choices.size():
		var choice: Dictionary = choices[i]
		var button := Button.new()
		button.text = choice["text"]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 20)
		for style_name in _button_styles:
			button.add_theme_stylebox_override(style_name, _button_styles[style_name])
		if _chosen_in_scene.has(i):
			button.modulate = CHOSEN_MODULATE
		if choice.has("require") and not GameState.meets(choice["require"]):
			# 數值不夠：顯示灰色「……（你想不起來）」，不能選
			button.text = choice.get("locked_text", LOCKED_TEXT)
			button.disabled = true
			button.add_theme_stylebox_override("disabled", _button_styles["disabled"])
			button.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.55))
		button.pressed.connect(_on_choice_pressed.bind(i, choice))
		choices_box.add_child(button)


func _clear_choices() -> void:
	for child in choices_box.get_children():
		choices_box.remove_child(child)
		child.queue_free()


## 打字機效果：逐字增加 visible_characters，結束後呼叫 on_done。
func _type_text(text: String, on_done: Callable) -> void:
	state = State.TYPING
	_after_typing = on_done
	body.text = text
	body.visible_characters = 0
	_typed_text = body.get_parsed_text()
	_typed_count = 0
	_next_tick_at = 1
	if _typing_tween:
		_typing_tween.kill()
	_typing_tween = create_tween()
	_typing_tween.tween_method(_set_typed_count, 0, _typed_text.length(),
			_typed_text.length() / CHARS_PER_SECOND)
	_typing_tween.tween_callback(_finish_typing)


func _set_typed_count(count: int) -> void:
	body.visible_characters = count
	while _typed_count < count:
		_typed_count += 1
		if _typed_count >= _next_tick_at:
			_play_type_tick(_typed_text[_typed_count - 1])


## 鍵盤感：每 2～4 個字隨機響一次，音高與音量帶些微變化，標點與空白不出聲。
func _play_type_tick(ch: String) -> void:
	if SILENT_CHARS.contains(ch):
		_next_tick_at = _typed_count + 1  # 標點後的下一個字馬上出聲，形成停頓後的重音
		return
	_next_tick_at = _typed_count + randi_range(2, 4)
	type_sfx.pitch_scale = randf_range(0.85, 1.25)
	type_sfx.volume_db = _type_base_db + randf_range(-4.0, 1.0)
	type_sfx.play()


func _finish_typing() -> void:
	if state != State.TYPING:
		return
	if _typing_tween:
		_typing_tween.kill()
		_typing_tween = null
	body.visible_characters = -1
	type_sfx.stop()  # 文字全部顯示後立即停止打字聲
	_after_typing.call()


func _on_choice_pressed(index: int, choice: Dictionary) -> void:
	if state != State.CHOOSING:
		return
	if _area_choosing:
		_on_area_choice_pressed(choice)
		return
	_chosen_in_scene[index] = true
	sfx.play()
	_clear_choices()
	hint.visible = false
	_pending_choice = choice
	_pending_next_id = int(choice.get("next_id", -1))
	GameState.apply_effects(choice.get("effects", {}), "scene.%d" % current_id)  # 同一個場景一輪只算一次
	if str(choice.get("response", "")).is_empty():
		_resolve_choice()  # 沒有回應文字（例如 Bad End 的「從這裡重試」）時直接前往
		return
	_type_text(choice["response"], _show_continue)


## 視覺小說的選項讀完回應後的去處：action（retry／title）> next_area > 結局回標題 > next_id。
func _resolve_choice() -> void:
	var choice := _pending_choice
	_pending_choice = {}
	continue_label.visible = false
	match choice.get("action", ""):
		"retry":
			_retry()
		"title":
			_return_to_title()
		_:
			if choice.has("next_area"):
				enter_area(choice["next_area"], -1, true)
			elif story.get_scene(current_id).get("is_ending", false):
				_return_to_title()  # 1.0 格式的結局：選「重新開始」回到標題畫面
			else:
				# next_id 等於目前場景時（例如「停留不動」）會重新顯示同一場景的選項。
				show_scene(_pending_next_id)


## 檢查點：進入區域或非結局的過場時存一份（位置＋完整狀態），Bad End 重試時還原。
func _save_checkpoint(place: Dictionary) -> void:
	_checkpoint = place.duplicate()
	_checkpoint["state"] = GameState.snapshot()


func _retry() -> void:
	if _checkpoint.is_empty():
		_return_to_title()
		return
	GameState.restore(_checkpoint["state"])
	current_id = -1
	if _checkpoint.has("area"):
		enter_area(_checkpoint["area"], -1, true, _checkpoint.get("from", ""))
	else:
		show_scene(int(_checkpoint["scene"]))


func _show_continue() -> void:
	state = State.RESPONSE
	continue_label.visible = true


## 除錯用：F3 顯示目前的數值（只在 debug 版建立，Web 正式版不會出現）。
func _create_debug_label() -> void:
	_debug_label = Label.new()
	_debug_label.name = "DebugStats"
	_debug_label.position = Vector2(16, 12)
	_debug_label.add_theme_font_size_override("font_size", 18)
	_debug_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_debug_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_debug_label.add_theme_constant_override("outline_size", 4)
	_debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_debug_label.visible = false
	add_child(_debug_label)


func _process(_delta: float) -> void:
	if _debug_label and _debug_label.visible:
		var parts: Array[String] = []
		for key in GameState.stats:
			parts.append("%s %d" % [{ "memory": "記憶", "humanity": "人性" }.get(key, key), GameState.stats[key]])
		_debug_label.text = "【F3】" + "　".join(parts) + ("　物品：" + "、".join(GameState.items.keys()) if not GameState.items.is_empty() else "")


## 除錯用：回傳目前 FPS（給 MCP 的 execute_code 讀取；execute_code 不能直接存取 Engine）。正式版回傳 -1。
func debug_fps() -> float:
	return Engine.get_frames_per_second() if OS.is_debug_build() else -1.0


## 直式畫面（高 > 寬，例如手機直拿）時顯示「請將裝置橫向持握」，並暫停點擊推進。
func _on_window_resized() -> void:
	update_rotate_hint(get_window().size)


func update_rotate_hint(window_size: Vector2i) -> void:
	rotate_hint.visible = window_size.y > window_size.x


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if _debug_label and key and key.pressed and not key.echo and key.keycode == KEY_F3:
		_debug_label.visible = not _debug_label.visible
		get_viewport().set_input_as_handled()
		return
	if rotate_hint.visible:
		get_viewport().set_input_as_handled()
		return
	if state == State.EXPLORE:
		# 同一個輸入事件只處理一次：開啟文字後立即標記為已處理，不會同時被當成「關閉」。
		if event.is_action_pressed("interact") and not _nearby_point.is_empty():
			get_viewport().set_input_as_handled()
			var point := _area_point(_nearby_point)
			if not _point_active(_nearby_point, point):
				return
			if point.get("type") == "exit" and AreaData.text_of(story, point).is_empty():
				_mark_done(_nearby_point)
				_go_through_exit(point)  # 沒有文字的出口（例如「回到停車場」）直接換區域
			else:
				_show_area_text(point, _nearby_point)
		return
	if state != State.TITLE and state != State.TYPING and state != State.RESPONSE \
			and state != State.AREA_TEXT:
		return
	var mb := event as InputEventMouseButton
	var clicked := mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if not (clicked or event.is_action_pressed("ui_accept") or event.is_action_pressed("interact")):
		return
	get_viewport().set_input_as_handled()
	if state == State.AREA_TEXT:
		_close_area_text()
	elif state == State.TITLE:
		_start_game()
	elif state == State.TYPING:
		_finish_typing()  # 打字中點擊：直接顯示全部
	else:
		_resolve_choice()


func _return_to_title() -> void:
	state = State.TRANSITION
	continue_label.visible = false
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, FADE_HALF_TIME)
	tween.tween_callback(show_title)
