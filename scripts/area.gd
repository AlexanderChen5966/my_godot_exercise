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

@export_group("光影")
## 世界整體亮度（CanvasModulate）。0 = 全黑、1 = 原本亮度。UI 不受影響。
@export_range(0.0, 1.0, 0.01) var world_brightness := 0.32
## 手電筒光暈的大小倍率與亮度。
@export_range(0.1, 4.0, 0.05) var flashlight_scale := 1.5
@export_range(0.0, 4.0, 0.05) var flashlight_energy := 1.6
## 出口附近紅色警示燈的亮度與呼吸速度（RedLight）。
## 2D 燈光是「燈色 × 表面顏色」：停車場是暗青色，紅色成分少，所以紅燈的亮度要比手電筒高很多才看得見。
@export_range(0.0, 10.0, 0.1) var red_light_energy := 5.0
@export_range(0.1, 6.0, 0.1) var red_light_speed := 1.6

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
	_apply_lighting()
	if has_node("Points"):
		for point in $Points.get_children():
			if point.has_signal("player_entered"):
				point.player_entered.connect(func(id: String) -> void: point_entered.emit(id))
				point.player_exited.connect(func(id: String) -> void: point_exited.emit(id))


func _apply_parallax() -> void:
	for pair in [["FarLayer", far_scroll], ["MidLayer", mid_scroll], ["FrontLayer", front_scroll]]:
		if has_node(pair[0]):
			get_node(pair[0]).scroll_scale = Vector2(pair[1], 1.0)


func _apply_lighting() -> void:
	if has_node("Darkness"):
		$Darkness.color = Color(world_brightness, world_brightness, world_brightness * 1.08)
	if has_node("Player/Flashlight"):
		$Player/Flashlight.texture_scale = flashlight_scale
		$Player/Flashlight.energy = flashlight_energy
	if has_node("RedLight"):
		$RedLight.base_energy = red_light_energy
		$RedLight.pulse_speed = red_light_speed


func set_can_move(value: bool) -> void:
	player.can_move = value


func consume_point(point_id: String) -> void:
	for point in $Points.get_children():
		if point.get("point_id") == point_id and point.has_method("consume"):
			point.consume()
