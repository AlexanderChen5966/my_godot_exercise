## 主角：只能左右移動（不跳、不受重力）。can_move 為 false 時（對話中）不動。
extends CharacterBody2D

const SPEED := 140.0  # 步履蹣跚，不要太快
# 角色在 32px 畫格裡偏左 1px，左右兩套是互相翻轉的，所以兩個方向的 Sprite 位置不同，轉身時身體中心才不會跳動
const SPRITE_X_RIGHT := 3.0
const SPRITE_X_LEFT := -1.0

var can_move := false
var min_x := 0.0
var max_x := 2304.0
var facing := 1  # 1 = 右，-1 = 左

@onready var sprite: AnimatedSprite2D = $Sprite


func _physics_process(_delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right") if can_move else 0.0
	var old_x := position.x
	velocity = Vector2(direction * SPEED, 0.0)
	move_and_slide()
	position.x = clampf(position.x, min_x, max_x)
	if direction != 0.0:
		facing = 1 if direction > 0.0 else -1
	_update_animation(not is_equal_approx(position.x, old_x))  # 走到區域邊緣被擋住時改回待機


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
