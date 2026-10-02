## 警示燈閃爍：緩慢的呼吸式明暗，偶爾突然熄滅一下（接觸不良的感覺）。掛在 PointLight2D 上。
extends PointLight2D

@export var base_energy := 5.0
@export var pulse_speed := 1.6         # 呼吸的速度（每秒弧度倍率）
@export_range(0.0, 1.0, 0.05) var min_ratio := 0.35  # 最暗時是 base_energy 的幾倍
@export_range(0.0, 1.0, 0.01) var dropout_chance := 0.012  # 每個畫面突然熄滅的機率

var _time := 0.0
var _dropout_left := 0.0


func _process(delta: float) -> void:
	_time += delta
	if _dropout_left > 0.0:
		_dropout_left -= delta
		energy = base_energy * 0.05
		return
	if randf() < dropout_chance:
		_dropout_left = randf_range(0.05, 0.15)
	var pulse := sin(_time * pulse_speed) * 0.5 + 0.5
	energy = base_energy * lerpf(min_ratio, 1.0, pulse)
