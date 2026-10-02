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


## 事件結束後讓替代美術消失（例如婦人逃走）。
func consume() -> void:
	if has_node("Figure"):
		$Figure.visible = false
