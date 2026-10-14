## A4：音效的名稱 → 檔案。資料裡寫 "sfx": "growl" 時，從 growl_1、growl_2… 隨機挑一個；
## 沒有編號的變化時用 growl.ogg；寫完整檔名（例如 "fence.ogg"）時直接用那個檔案。
class_name SoundLib

const SFX_DIR := "res://assets/sfx/"
const MAX_VARIANTS := 9

static var _cache := {}
static var _registered: Array[AudioStream] = []  # 留住註冊過的聲音，免得被釋放後再載入時又要重新解碼


## 這個名稱的所有變化（找不到時是空陣列）
static func variants(sound_name: String) -> Array[AudioStream]:
	if _cache.has(sound_name):
		return _cache[sound_name]
	var list: Array[AudioStream] = []
	for path in paths(sound_name):
		list.append(load(path))
	_cache[sound_name] = list
	return list


## 這個名稱對應的檔案路徑（劇本檢查也用它確認檔案存在）
static func paths(sound_name: String) -> Array[String]:
	var out: Array[String] = []
	if sound_name.is_empty():
		return out
	if sound_name.ends_with(".ogg") or sound_name.ends_with(".wav"):
		if ResourceLoader.exists(SFX_DIR + sound_name):
			out.append(SFX_DIR + sound_name)
		return out
	for i in range(1, MAX_VARIANTS + 1):
		var path := "%s%s_%d.ogg" % [SFX_DIR, sound_name, i]
		if not ResourceLoader.exists(path):
			break
		out.append(path)
	if out.is_empty() and ResourceLoader.exists(SFX_DIR + sound_name + ".ogg"):
		out.append(SFX_DIR + sound_name + ".ogg")
	return out


## 隨機挑一個變化；找不到時回傳 null
static func pick(sound_name: String) -> AudioStream:
	var list := variants(sound_name)
	return null if list.is_empty() else list[randi() % list.size()]


## A4-3：網頁版預設用瀏覽器的 Sample 方式播放，第一次播放某個聲音時要先解碼，會延遲（開門聲、槍聲在轉場後才出來）。
## 遊戲啟動時先把 assets/sfx/ 的音效都註冊成 sample。
static func register_all() -> void:
	var done := {}
	for file in DirAccess.get_files_at(SFX_DIR):
		var file_name := file.trim_suffix(".remap").trim_suffix(".import")  # 匯出後的檔名會多 .remap／.import
		if done.has(file_name) or not (file_name.ends_with(".ogg") or file_name.ends_with(".wav")):
			continue
		done[file_name] = true
		var stream := load(SFX_DIR + file_name) as AudioStream
		if stream and not AudioServer.is_stream_registered_as_sample(stream):
			AudioServer.register_stream_as_sample(stream)
			_registered.append(stream)
