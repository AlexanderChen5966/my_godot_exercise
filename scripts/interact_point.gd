## 區域中的互動點：玩家進入／離開範圍時發出訊號。互動點的類型與文字定義在 data/areas/*.json（以 point_id 對應）。
extends Area2D

signal player_entered(point_id: String)
signal player_exited(point_id: String)

@export var point_id := ""


func _ready() -> void:
	body_entered.connect(func(body: Node2D) -> void:
		if body is CharacterBody2D:
			player_entered.emit(point_id))
	body_exited.connect(func(body: Node2D) -> void:
		if body is CharacterBody2D:
			player_exited.emit(point_id))


const SCREAM_TIME := 0.5     # 逃跑前尖叫幾秒
const FLEE_SPEED := 240.0    # 逃跑速度（px/秒，約主角的 1.7 倍）
const FLEE_DISTANCE := 760.0  # 跑多遠才消失（跑出畫面）


## 事件結束後讓替代美術消失（例如婦人逃走）。
## A3：有 flee_from_x（主角的 x）而且人物有 run 動畫時，先尖叫，再往遠離主角的方向跑出畫面才消失；
## 回到區域時（已經發生過的事件）不傳 flee_from_x，直接隱藏。
func consume(flee_from_x := NAN) -> void:
	if not has_node("Figure"):
		return
	var figure := $Figure as CanvasItem
	var sprite := figure as AnimatedSprite2D
	if is_nan(flee_from_x) or sprite == null or not sprite.sprite_frames.has_animation("run"):
		figure.visible = false
		return
	_flee(sprite, flee_from_x)


## 圖是面向左畫的：尖叫時面向主角，逃跑時背對主角
func _flee(sprite: AnimatedSprite2D, from_x: float) -> void:
	var dir := 1.0 if global_position.x >= from_x else -1.0
	sprite.flip_h = dir < 0.0
	sprite.play("scream")
	var tween := create_tween()
	tween.tween_interval(SCREAM_TIME)
	tween.tween_callback(func() -> void:
		sprite.flip_h = dir > 0.0
		sprite.play("run"))
	tween.tween_property(sprite, "position:x", sprite.position.x + dir * FLEE_DISTANCE, FLEE_DISTANCE / FLEE_SPEED)
	tween.tween_callback(func() -> void: sprite.visible = false)
