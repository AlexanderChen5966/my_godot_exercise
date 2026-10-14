## A3：裝在槍上的手電筒（警衛）。跟著人物動畫的格數，把燈移到燈頭、轉到槍的角度，光永遠沿著槍管。
## 掛在 PointLight2D（錐形光貼圖：頂點在左邊中間、往右照），和人物的 Figure 放在同一個父節點底下。
## 每格燈頭的位置與角度由 art/design/a3/guard.py 印出。
extends PointLight2D

@export var follow: NodePath  # 人物的 AnimatedSprite2D（Figure）
## idle 每一格的（燈頭 x, 燈頭 y, 槍口往下的角度）：位置是圖上的像素（左上角為 0,0），人物面向左
## 用 PackedVector3Array 存在一起：Toolkit 沒有 PackedFloat32Array 的寫法，寫成一般陣列存檔時可能被丟掉
@export var idle_frames := PackedVector3Array()
## event（瞄準）那一格的（燈頭 x, 燈頭 y, 角度）
@export var event_frame := Vector3.ZERO

var _sprite: AnimatedSprite2D


func _ready() -> void:
	_sprite = get_node_or_null(follow) as AnimatedSprite2D
	if texture:
		# 貼圖往前推半個寬度（要乘上 texture_scale，offset 本身不會跟著放大），錐形光的頂點才會落在燈頭上
		offset = Vector2(texture.get_width() * 0.5 * texture_scale, 0.0)
	_update()


func _process(_delta: float) -> void:
	_update()


func _update() -> void:
	if _sprite == null:
		return
	visible = _sprite.visible
	var f := event_frame
	if _sprite.animation != &"event" and not idle_frames.is_empty():
		f = idle_frames[_sprite.frame % idle_frames.size()]
	var point := Vector2(f.x, f.y)
	var angle := f.z
	var frame_size := _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame).get_size()
	var local := (point - frame_size / 2.0) * _sprite.scale
	var rad := deg_to_rad(angle)
	if _sprite.flip_h:  # 面向右：位置左右翻轉，光往右下
		local.x = -local.x
		rotation = rad
	else:               # 面向左：光往左下
		rotation = PI - rad
	position = _sprite.position + local
