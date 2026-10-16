## A5 躲藏：警衛原地左右轉身（面向左 face_left 秒、面向右 face_right 秒交替），槍上手電筒的光錐照到
## 不在掩護裡的主角超過 spot_time 秒就發出 spotted。由 Main 依互動點的 patrol 資料建立，加在警衛的互動點底下。
## 光的位置跟著 gun_torch.gd（Torch 節點），範圍＝錐形光貼圖的寬 × texture_scale × FLOOR_REACH。
extends Node

signal spotted

const FLOOR_REACH := 0.65  # 判定範圍＝畫面上看得到光的地面（實測約手電筒前方 260 px，再遠光就淡掉了；0.9 時看不到光的地方也會被發現）

var face_left := 4.0
var face_right := 3.0
var spot_time := 0.4
var active := false     # Main 每個畫面設定：可以走動、警衛事件還沒發生時才巡視
var exposed := false    # 這個畫面主角是不是在光裡（測試用）

var _figure: AnimatedSprite2D
var _torch: PointLight2D
var _player: Node2D
var _turn_left := 0.0
var _exposed_time := 0.0


func setup(config: Dictionary, figure: AnimatedSprite2D, torch: PointLight2D, player: Node2D) -> void:
	face_left = float(config.get("face_left", face_left))
	face_right = float(config.get("face_right", face_right))
	spot_time = float(config.get("spot_time", spot_time))
	_figure = figure
	_torch = torch
	_player = player
	_figure.flip_h = false  # 一開始面向左（照向主角進來的方向）
	_turn_left = face_left


func _process(delta: float) -> void:
	if not active or _figure == null or not _figure.visible:
		exposed = false
		_exposed_time = 0.0
		return
	_turn_left -= delta
	if _turn_left <= 0.0:
		_figure.flip_h = not _figure.flip_h  # 轉身（gun_torch.gd 會把手電筒跟著翻過去）
		_turn_left = face_right if _figure.flip_h else face_left
	exposed = in_light()
	_exposed_time = _exposed_time + delta if exposed else 0.0
	if _exposed_time >= spot_time:
		active = false
		_exposed_time = 0.0
		spotted.emit()


## 主角在不在光裡：警衛面向主角這一側，主角在手電筒前方「光照到的地面」範圍內（光錐長度 × FLOOR_REACH），而且不在掩護裡。
## 不用光錐的幾何角度判定：手電筒在胸口高度、往下照，縱深帶裡的主角身上幾乎都在光錐上緣之外，只有貼到腳邊才會被照到（實測）。
func in_light() -> bool:
	if _player == null or _player.get("in_cover"):
		return false
	var toward := 1.0 if _figure.flip_h else -1.0   # 面向右是 +1
	var dx := (_player.global_position.x - _torch.global_position.x) * toward
	return dx > -20.0 and dx <= floor_reach()


## 光照到的地面有多遠（px）
func floor_reach() -> float:
	var length := _torch.texture.get_width() * _torch.texture_scale if _torch.texture else 400.0
	return length * FLOOR_REACH


## 被發現或事件開始時，轉向主角（圖是面向左畫的：主角在右邊就翻轉）
func face_toward(x: float) -> void:
	if _figure:
		_figure.flip_h = x > _figure.global_position.x
		_turn_left = face_right if _figure.flip_h else face_left


func is_facing_right() -> bool:
	return _figure != null and _figure.flip_h
