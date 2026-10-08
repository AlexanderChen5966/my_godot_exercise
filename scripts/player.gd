## 主角：在縱深帶裡上下左右移動（A1.5，像《小朋友齊打交 2》；不跳、不受重力）。can_move 為 false 時（對話中）不動。
extends CharacterBody2D

const SPEED := 140.0  # 步履蹣跚，不要太快
const DEPTH_SPEED_RATIO := 0.6  # 上下（往畫面裡外）走得比左右慢，這類遊戲的慣例
const SHADOW_TEXTURE := preload("res://assets/sprites/characters/shadow.png")
const FEET_SIZE := Vector2(24, 12)  # 互動判定的腳底範圍
# 角色在 32px 畫格裡偏左 1px，左右兩套是互相翻轉的，所以兩個方向的 Sprite 位置不同，轉身時身體中心才不會跳動
const SPRITE_X_RIGHT := 3.0
const SPRITE_X_LEFT := -1.0

var can_move := false
var min_x := 0.0
var max_x := 2304.0
var min_y := 650.0  # 縱深帶（腳的 y 範圍），由區域設定
var max_y := 735.0
var facing := 1  # 1 = 右，-1 = 左

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


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down") if can_move else Vector2.ZERO
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


## 左右各一套動畫（不用 flip_h），依「是否移動 × 面向」選擇
func _update_animation(moving: bool) -> void:
	var side := "right" if facing > 0 else "left"
	var anim := ("walk_" if moving else "idle_") + side
	if sprite.animation != anim:
		sprite.play(anim)
	sprite.position.x = SPRITE_X_RIGHT if facing > 0 else SPRITE_X_LEFT
