## A6 設定：音樂、音效、環境音的音量（0～1，對應 A4 的音量分組 BGM／SFX／Ambient）與打字聲開關。
## 存在 user://settings.cfg（網頁版存在瀏覽器裡），遊戲啟動時讀取並套用。
class_name GameSettings

const BUSES := { "music": "BGM", "sfx": "SFX", "ambient": "Ambient" }
const DEFAULTS := { "music": 1.0, "sfx": 1.0, "ambient": 1.0, "typing": false }  # 作者 2026-10-16：音量預設 100%，打字聲預設關

static var path := "user://settings.cfg"  # 測試改成另一個檔案，才不會動到實際的設定
static var values := DEFAULTS.duplicate()


static func load_settings() -> void:
	values = DEFAULTS.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		for key in DEFAULTS:
			values[key] = cfg.get_value("settings", key, DEFAULTS[key])
	apply()


static func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key in values:
		cfg.set_value("settings", key, values[key])
	cfg.save(path)


## 改一個設定：立刻套用並存檔
static func set_value(key: String, value) -> void:
	values[key] = value
	apply()
	save_settings()


static func get_value(key: String):
	return values.get(key, DEFAULTS.get(key))


## 把音量套到音量分組（0 時直接靜音）
static func apply() -> void:
	for key in BUSES:
		var bus := AudioServer.get_bus_index(BUSES[key])
		if bus < 0:
			continue
		var volume := clampf(float(values[key]), 0.0, 1.0)
		AudioServer.set_bus_mute(bus, volume <= 0.001)
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.001)))
