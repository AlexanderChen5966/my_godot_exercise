## 主角：在縱深帶裡上下左右移動（A1.5，像《小朋友齊打交 2》；不跳、不受重力）。can_move 為 false 時（對話中）不動。
extends CharacterBody2D

const SPEED := 140.0  # 步履蹣跚，不要太快
const DEPTH_SPEED_RATIO := 0.6  # 上下（往畫面裡外）走得比左右慢，這類遊戲的慣例
const SHADOW_TEXTURE := preload("res://assets/sprites/characters/shadow.png")
const FEET_SIZE := Vector2(24, 12)  # 互動判定的腳底範圍
# 角色在 32px 畫格裡偏左 1px，左右兩套是互相翻轉的，所以兩個方向的 Sprite 位置不同，轉身時身體中心才不會跳動
const SPRITE_X_RIGHT := 3.0
const SPRITE_X_LEFT := -1.0
## A4：行走 6 格裡腳著地的兩格（兩腳張得最開，第 0、3 格）；腳步聲在這兩格播放
const STEP_FRAMES := [0, 3]
const STEP_DB := -8.0
const STEP_STOP_FADE := 0.08  # A4-3：停下來時，正在播的腳步聲在這段時間內淡出（作者：停下後腳步聲還在持續）

var can_move := false
var min_x := 0.0
var max_x := 2304.0
var min_y := 650.0  # 縱深帶（腳的 y 範圍），由區域設定
var max_y := 735.0
var facing := 1  # 1 = 右，-1 = 左
var acting := false  # A3：正在做動作（調查時伸手），這段時間不切換待機／行走
var lean := false    # A3：衝動強度高，站著不動時改成前傾（由 Main 每個畫面設定）
var lean_toward := NAN  # 前傾時轉向的 x（衝動最強的那個人）
var step_sounds: Array[AudioStream] = []  # A4：目前區域地面的腳步聲（由 Main 依區域資料的 floor 設定）

var _steps: AudioStreamPlayer
var steps_played := 0  # 播過幾次腳步聲（測試用）
var in_cover := false  # A5 躲藏：躲在掩護後面（變暗、半透明，警衛的光照到也不會發現）；一移動就出來
var _steps_tween: Tween

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	# 腳下的影子：7 個區域場景各有一份 Player，所以在這裡加，不用逐一改場景
	var shadow := Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = SHADOW_TEXTURE
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shadow.scale = Vector2(2, 2)
	shadow.position = Vector2(1, -2)
	add_child(shadow)
	move_child(shadow, sprite.get_index())  # 畫在角色下面
	# 互動判定只用腳底（A1.5）：要走到物件前面的地面才會觸發，不會因為身體高度而在縱深帶外側也觸發
	var feet := RectangleShape2D.new()
	feet.size = FEET_SIZE
	$Shape.shape = feet
	$Shape.position = Vector2(0, -FEET_SIZE.y / 2.0)
	# A4：腳步聲
	_steps = AudioStreamPlayer.new()
	_steps.name = "Steps"
	_steps.bus = &"SFX"
	_steps.volume_db = STEP_DB
	_steps.max_polyphony = 2
	add_child(_steps)
	sprite.frame_changed.connect(_on_frame_changed)


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down") if can_move else Vector2.ZERO
	if in_cover and direction != Vector2.ZERO:
		set_in_cover(false)  # 移動就從掩護後面出來
	var old_position := position
	velocity = Vector2(direction.x * SPEED, direction.y * SPEED * DEPTH_SPEED_RATIO)
	move_and_slide()
	position = Vector2(clampf(position.x, min_x, max_x), clampf(position.y, min_y, max_y))
	if direction.x != 0.0:
		facing = 1 if direction.x > 0.0 else -1
	_update_animation(not position.is_equal_approx(old_position))  # 走到邊緣被擋住時改回待機


## 直接設定面向（換區域時使用），並立刻換成對應的待機動畫。
func face(direction: int) -> void:
	facing = direction
	_update_animation(false)


## A3：調查時轉向物件（x）並伸手，停在最後一格，直到 end_action()
func reach_toward(x: float) -> void:
	if not is_nan(x) and absf(x - position.x) > 4.0:
		facing = 1 if x > position.x else -1
	acting = true
	sprite.play("reach_right" if facing > 0 else "reach_left")
	sprite.position.x = SPRITE_X_RIGHT if facing > 0 else SPRITE_X_LEFT


func end_action() -> void:
	acting = false


## A5 躲藏：躲到掩護後面／出來（樣子先用變暗、半透明；蹲下的動畫是之後的升級方案）
func set_in_cover(value: bool) -> void:
	in_cover = value
	modulate = Color(0.35, 0.35, 0.42, 0.6) if value else Color.WHITE


## A5：比出手勢「我——在——這——裡」（約 2 秒）。toward_x 有值時先轉向那個人。播完才結束，用 await 等。
func play_gesture(toward_x := NAN) -> void:
	if not is_nan(toward_x) and absf(toward_x - position.x) > 4.0:
		facing = 1 if toward_x > position.x else -1
	acting = true
	_fade_out_step()
	sprite.play("gesture_right" if facing > 0 else "gesture_left")
	sprite.position.x = SPRITE_X_RIGHT if facing > 0 else SPRITE_X_LEFT
	await sprite.animation_finished
	acting = false
	_update_animation(false)


## 左右各一套動畫（不用 flip_h），依「是否移動 × 面向」選擇；站著時衝動強度高就前傾
func _update_animation(moving: bool) -> void:
	if acting:
		return
	if lean and not moving and not is_nan(lean_toward) and absf(lean_toward - position.x) > 4.0:
		facing = 1 if lean_toward > position.x else -1  # 被人吸引：朝著那個人前傾
	var side := "right" if facing > 0 else "left"
	var anim := ("walk_" if moving else ("lean_" if lean else "idle_")) + side
	if sprite.animation != anim:
		var was_walking := String(sprite.animation).begins_with("walk_")
		sprite.play(anim)
		if moving:
			_play_step()  # 開始走的第一格（第 0 格）就是腳著地，frame_changed 不會觸發
		elif was_walking:
			_fade_out_step()
	sprite.position.x = SPRITE_X_RIGHT if facing > 0 else SPRITE_X_LEFT


## A4：行走到腳著地的那兩格時播放腳步聲（地面材質由區域決定，每次隨機挑一個、音高稍微變化）
func _on_frame_changed() -> void:
	if String(sprite.animation).begins_with("walk_") and sprite.frame in STEP_FRAMES:
		_play_step()


func _play_step() -> void:
	if step_sounds.is_empty():
		return
	if _steps_tween:
		_steps_tween.kill()
	_steps.volume_db = STEP_DB
	_steps.stream = step_sounds[randi() % step_sounds.size()]
	_steps.pitch_scale = randf_range(0.92, 1.08)
	_steps.play()
	steps_played += 1


func _fade_out_step() -> void:
	if not _steps.playing:
		return
	if _steps_tween:
		_steps_tween.kill()
	_steps_tween = create_tween()
	_steps_tween.tween_property(_steps, "volume_db", -40.0, STEP_STOP_FADE)
	_steps_tween.tween_callback(_steps.stop)
