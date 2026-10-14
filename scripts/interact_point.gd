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


## A3：事件文字打開時，人物有 event 動畫就播（例如女科學家遞出筆記本）；事件結束、人物沒有要消失時回到 idle
func on_event_start() -> void:
	_play_if_has("event")


func on_event_end() -> void:
	_play_if_has("idle")


func _play_if_has(anim: StringName) -> void:
	var sprite := get_node_or_null("Figure") as AnimatedSprite2D
	if sprite and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)


## 圖是面向左畫的：尖叫時面向主角，逃跑時背對主角；沒有 scream 動畫的人物直接跑（例如女科學家）
func _flee(sprite: AnimatedSprite2D, from_x: float) -> void:
	var dir := 1.0 if global_position.x >= from_x else -1.0
	var tween := create_tween()
	if sprite.sprite_frames.has_animation("scream"):
		sprite.flip_h = dir < 0.0
		sprite.play("scream")
		tween.tween_interval(SCREAM_TIME)
	tween.tween_callback(func() -> void:
		sprite.flip_h = dir > 0.0
		sprite.play("run"))
	tween.tween_property(sprite, "position:x", sprite.position.x + dir * FLEE_DISTANCE, FLEE_DISTANCE / FLEE_SPEED)
	tween.tween_callback(func() -> void: sprite.visible = false)
