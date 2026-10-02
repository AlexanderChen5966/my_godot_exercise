## 主畫面：顯示場景與選項；點選項後先顯示 response，再點擊前往 next_id。
## 主文字與 response 以打字機效果顯示，換場時背景淡出淡入，BGM 以兩個播放器交替淡入淡出。
extends Control

enum State { TITLE, TRANSITION, TYPING, CHOOSING, RESPONSE }

const EXTRA_HINT_COLOR := "#a8a8a8"
const CHOSEN_MODULATE := Color(1, 1, 1, 0.45)
const CHARS_PER_SECOND := 30.0
const SILENT_CHARS := " \n，。、！？：；「」『』（）…—,.!?:;\"'()-"  # 打到這些字元時不出打字聲
const FADE_HALF_TIME := 0.2  # 淡出 + 淡入共約 0.4 秒
const BGM_FADE_TIME := 0.8

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

var story := StoryData.new()
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


func show_title() -> void:
	current_id = -1
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
		show_scene(story.start_id, false)
	)


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
	_clear_choices()
	hint.visible = false
	continue_label.visible = false

	if id == current_id:
		# 留在原場景：已讀過的主文字直接完整顯示，重新給選項。
		body.text = scene["text"]
		body.visible_ratio = 1.0
		_show_choices(scene)
		return

	current_id = id
	_chosen_in_scene.clear()
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
	_chosen_in_scene[index] = true
	sfx.play()
	_clear_choices()
	hint.visible = false
	_pending_next_id = int(choice["next_id"])
	_type_text(choice["response"], _show_continue)


func _show_continue() -> void:
	state = State.RESPONSE
	continue_label.visible = true


## 直式畫面（高 > 寬，例如手機直拿）時顯示「請將裝置橫向持握」，並暫停點擊推進。
func _on_window_resized() -> void:
	update_rotate_hint(get_window().size)


func update_rotate_hint(window_size: Vector2i) -> void:
	rotate_hint.visible = window_size.y > window_size.x


func _input(event: InputEvent) -> void:
	if rotate_hint.visible:
		get_viewport().set_input_as_handled()
		return
	if state != State.TITLE and state != State.TYPING and state != State.RESPONSE:
		return
	var mb := event as InputEventMouseButton
	var clicked := mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if not (clicked or event.is_action_pressed("ui_accept")):
		return
	get_viewport().set_input_as_handled()
	if state == State.TITLE:
		_start_game()
	elif state == State.TYPING:
		_finish_typing()  # 打字中點擊：直接顯示全部
	elif story.get_scene(current_id).get("is_ending", false):
		_return_to_title()  # 結局選「重新開始」回到標題畫面，而不是直接回場景 1
	else:
		# next_id 等於目前場景時（例如「停留不動」）會重新顯示同一場景的選項。
		show_scene(_pending_next_id)


func _return_to_title() -> void:
	state = State.TRANSITION
	continue_label.visible = false
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, FADE_HALF_TIME)
	tween.tween_callback(show_title)
