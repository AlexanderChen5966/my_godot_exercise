## 可走動區域的根節點（所有區域共用）：設定玩家起點、移動範圍與鏡頭範圍，並把互動點的訊號轉給 Main。
extends Node2D

signal point_entered(point_id: String)   # 玩家走進互動點範圍
signal point_exited(point_id: String)    # 玩家離開互動點範圍

@export var area_width := 2304.0
@export var area_height := 768.0
@export var player_start := Vector2(160, 640)
@export var edge_margin := 16.0  # 主角色塊半寬，避免身體超出區域邊緣

@export_group("景深（視差）")
## 各層相對鏡頭的移動倍率：小於 1 越遠、越慢；大於 1 越近、越快。區域裡沒有該層時忽略。
@export var far_scroll := 0.3
@export var mid_scroll := 0.7
@export var front_scroll := 1.3

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D


func _ready() -> void:
	player.position = player_start
	player.min_x = edge_margin
	player.max_x = area_width - edge_margin
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(area_width)
	camera.limit_bottom = int(area_height)
	camera.make_current()
	_apply_parallax()
	if has_node("Points"):
		for point in $Points.get_children():
			if point.has_signal("player_entered"):
				point.player_entered.connect(func(id: String) -> void: point_entered.emit(id))
				point.player_exited.connect(func(id: String) -> void: point_exited.emit(id))


func _apply_parallax() -> void:
	for pair in [["FarLayer", far_scroll], ["MidLayer", mid_scroll], ["FrontLayer", front_scroll]]:
		if has_node(pair[0]):
			get_node(pair[0]).scroll_scale = Vector2(pair[1], 1.0)


func set_can_move(value: bool) -> void:
	player.can_move = value


func consume_point(point_id: String) -> void:
	for point in $Points.get_children():
		if point.get("point_id") == point_id and point.has_method("consume"):
			point.consume()
