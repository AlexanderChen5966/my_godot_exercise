## 主角：只能左右移動（不跳、不受重力）。can_move 為 false 時（對話中）不動。
extends CharacterBody2D

const SPEED := 140.0  # 步履蹣跚，不要太快

var can_move := false
var min_x := 0.0
var max_x := 2304.0
var facing := 1  # 1 = 右，-1 = 左（Lv3 換成像素角色時用來翻轉）


func _physics_process(_delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right") if can_move else 0.0
	velocity = Vector2(direction * SPEED, 0.0)
	move_and_slide()
	position.x = clampf(position.x, min_x, max_x)
	if direction != 0.0:
		facing = 1 if direction > 0.0 else -1
