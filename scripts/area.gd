## 可走動區域的根節點（所有區域共用）：設定玩家起點、移動範圍與鏡頭範圍，並把互動點的訊號轉給 Main。
extends Node2D

signal point_entered(point_id: String)   # 玩家走進互動點範圍
signal point_exited(point_id: String)    # 玩家離開互動點範圍

@export var area_width := 2304.0
@export var area_height := 768.0
@export var player_start := Vector2(160, 640)
@export var edge_margin := 16.0  # 主角色塊半寬，避免身體超出區域邊緣

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
	if has_node("Points"):
		for point in $Points.get_children():
			if point.has_signal("player_entered"):
				point.player_entered.connect(func(id: String) -> void: point_entered.emit(id))
				point.player_exited.connect(func(id: String) -> void: point_exited.emit(id))


func set_can_move(value: bool) -> void:
	player.can_move = value
