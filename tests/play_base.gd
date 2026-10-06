## 遊玩測試的共用操作（test_lv4.gd、test_lv5.gd 繼承這個檔案）：載入真正的 Main.tscn，用和玩家一樣的輸入（互動鍵、按選項）操作。
## 檔名不是 test_ 開頭，run_tests.sh 不會單獨執行它。
extends SceneTree

const TITLE := 0
const TRANSITION := 1
const TYPING := 2
const CHOOSING := 3
const RESPONSE := 4
const EXPLORE := 5
const AREA_TEXT := 6

var main: Control
var fails := 0
var checks := 0


## 載入主場景、執行 run_tests()、印出結果並結束（子類別覆寫 run_tests）
func _initialize() -> void:
	main = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await frames(5)
	await run_tests()
	print("\n共 %d 項檢查，失敗 %d 項" % [checks, fails])
	main.queue_free()
	await frames(3)
	quit(1 if fails > 0 else 0)


func run_tests() -> void:
	pass


# ---- 操作 ----

func start_game(skip_intro := true) -> void:
	main.call("_start_game")
	await wait_for(func(): return main.state in [TYPING, AREA_TEXT], 5.0)
	if skip_intro:
		await read()


func back_to_title() -> void:
	main.call("_return_to_title")
	await wait_for(func(): return main.state == TITLE, 5.0)


## 主角走到 x（直接設定位置，再等物理更新讓互動點偵測到）
func walk_to(x: float) -> void:
	player().position.x = x
	await physics(4)
	await wait_for(func(): return main.state != TRANSITION, 3.0)


func interact() -> void:
	await key("interact")


## 讀完目前的文字：打字中先按一次顯示全部，再按一次關閉
func read() -> void:
	await wait_for(func(): return main.state in [TYPING, AREA_TEXT, RESPONSE], 5.0)
	if main.state == TYPING:
		await key("interact")
	await wait_for(func(): return main.state in [AREA_TEXT, RESPONSE], 3.0)
	await key("interact")
	await wait_for(func(): return main.state in [EXPLORE, TRANSITION, CHOOSING] or main.current_id >= 3, 3.0)


## 等選項出現（打字中先按一次），按第 index 個選項，再讀完回應
func choose(index: int) -> void:
	await wait_choices()
	(main.choices_box.get_child(index) as Button).pressed.emit()
	await read()


func wait_choices() -> void:
	await wait_for(func(): return main.state in [TYPING, CHOOSING], 5.0)
	if main.state == TYPING:
		await key("interact")
	await wait_for(func(): return main.state == CHOOSING, 3.0)


## 第 index 個選項是否鎖住（數值不夠：灰色、不能按）
func locked(index: int) -> bool:
	return (main.choices_box.get_child(index) as Button).disabled


## 走到出口、按互動鍵、讀完出口文字，等新區域的開場（第一次）並讀完
func go_exit(x: float, next_area: String) -> void:
	await walk_to(x)
	await interact()
	if main.state in [TYPING, AREA_TEXT]:
		await read()
	await enter(next_area)


## 走到通往過場的出口，讀完出口文字，等過場出現
func exit_to_scene(x: float, scene_id: int) -> void:
	await walk_to(x)
	await interact()
	await read()
	await to_scene(scene_id)


## 等進入區域（換場結束），有開場就讀完
func enter(area_id: String) -> void:
	await wait_for(func(): return area() == area_id and main.state != TRANSITION, 6.0)
	if main.state in [TYPING, AREA_TEXT]:
		await read()


## 等過場或結局出現
func to_scene(scene_id: int) -> void:
	await wait_for(func(): return main.current_id == scene_id and main.state in [TYPING, CHOOSING], 6.0)


## 結局／Bad End 的選項（回應是空的，按下去直接重試或回標題）
func end_choice(index: int) -> void:
	await wait_choices()
	(main.choices_box.get_child(index) as Button).pressed.emit()
	await wait_for(func(): return main.state != CHOOSING, 3.0)


func key(action: String) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	await frames(2)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	await frames(2)


# ---- 查詢 ----

func gs() -> GameStateData:
	return root.get_node("GameState")


func area() -> String:
	return main.get("_area_id")


func player() -> CharacterBody2D:
	return main.get("_area").get_node("Player")


func prompt() -> String:
	return main.prompt_label.text if main.prompt_label.visible else ""


func figure_visible(point_name: String) -> bool:
	return main.get("_area").get_node("Points/%s/Figure" % point_name).visible


func ok(cond: bool, name: String) -> void:
	checks += 1
	print(("  ✓ " if cond else "  ✗ ") + name)
	if not cond:
		fails += 1
		print("    狀態 state=%d area=%s scene=%d stats=%s items=%s flags=%s" % [main.state, area(), main.current_id, gs().stats, gs().items.keys(), gs().flags.keys()])


# ---- 等待 ----

func frames(n: int) -> void:
	for i in n:
		await process_frame


func physics(n: int) -> void:
	for i in n:
		await physics_frame


## 以真實時間計算逾時（headless 不等螢幕更新，畫格會跑得很快，但淡入淡出與打字是用秒計算）
func wait_for(cond: Callable, timeout: float) -> void:
	var until := Time.get_ticks_msec() + int(timeout * 1000)
	while not cond.call() and Time.get_ticks_msec() < until:
		await process_frame
