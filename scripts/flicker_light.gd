## 警示燈閃爍：緩慢的呼吸式明暗，偶爾突然熄滅一下（接觸不良的感覺）。掛在 PointLight2D 上。
extends PointLight2D

@export var base_energy := 5.0
@export var pulse_speed := 1.6         # 呼吸的速度（每秒弧度倍率）
@export_range(0.0, 1.0, 0.05) var min_ratio := 0.35  # 最暗時是 base_energy 的幾倍
@export_range(0.0, 1.0, 0.01) var dropout_chance := 0.012  # 每個畫面突然熄滅的機率
## A3：跟著火焰動畫（AnimatedSprite2D）一起跳動：每一格乘上 frame_strength 的倍率（火焰高的格亮一點）。不設定時照舊。
## 用 NodePath（不用節點型別的 export）：Toolkit 設定節點型別的 export 時只寫入路徑，載入後會是 null
@export var follow: NodePath
@export var frame_strength := PackedFloat32Array()

var _time := 0.0
var _dropout_left := 0.0
var _follow: AnimatedSprite2D


func _ready() -> void:
	if not follow.is_empty():
		_follow = get_node_or_null(follow) as AnimatedSprite2D


func _process(delta: float) -> void:
	_time += delta
	if _dropout_left > 0.0:
		_dropout_left -= delta
		energy = base_energy * 0.05
		return
	if randf() < dropout_chance:
		_dropout_left = randf_range(0.05, 0.15)
	var pulse := sin(_time * pulse_speed) * 0.5 + 0.5
	energy = base_energy * lerpf(min_ratio, 1.0, pulse) * _frame_factor()


func _frame_factor() -> float:
	if _follow == null or frame_strength.is_empty():
		return 1.0
	return frame_strength[_follow.frame % frame_strength.size()]
