## Lv4-7 自動測試：載入真正的 Main.tscn，用和玩家一樣的輸入（互動鍵、按選項）跑三輪。
## 不要直接對專案執行：用 tests/run_tests.sh（會先建立拿掉外掛的副本，再在副本上執行）。
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


func _initialize() -> void:
	main = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await frames(5)
	await run_a()
	await run_b()
	await run_c()
	print("\n共 %d 項檢查，失敗 %d 項" % [checks, fails])
	main.queue_free()
	await frames(3)
	quit(1 if fails > 0 else 0)


# ---- 三輪 ----

## A：不拿錄音筆，診療椅只有描述
func run_a() -> void:
	print("\n== A：不拿錄音筆")
	await start_game()
	ok(area() == "parking_lot" and gs().stats == { "memory": 0, "humanity": 3 }, "從停車場開始，數值是初始值")
	await walk_to(300); await interact(); await read()
	ok(gs().stats["memory"] == 1, "醒來的地方：記憶 +1")
	await walk_to(300); await interact(); await read()
	ok(gs().stats["memory"] == 1, "同一處再調查：記憶不再增加")
	await walk_to(1460)                       # 婦人：走近自動觸發
	await choose(0)                           # 強行壓制自己
	ok(gs().stats["humanity"] == 4, "婦人選「強行壓制自己」：人性 +1")
	ok(not figure_visible("Woman"), "婦人事件後消失")
	await go_exit(2150, "street")
	ok(player().position.x == 220, "進街道出現在 x=220")
	await walk_to(1450); await interact(); await read()
	ok(gs().stats["memory"] == 2, "尋人啟事：記憶 +1")
	await go_exit(2150, "clinic")
	await walk_to(1750); await interact(); await read()
	ok(gs().has_flag("clinic.chair") and not gs().has_flag("clinic.chair#0"), "沒錄音筆時坐診療椅：只有描述")
	await go_exit(70, "street")
	ok(player().position.x == 2100 and player().facing == -1, "回街道出現在右邊（x=2100）、面向左")
	await go_exit(2150, "clinic")
	ok(main.get("_closing_point") == "" and main.state == EXPLORE, "第二次進診所：不再顯示開場")
	await walk_to(2150); await interact(); await read(); await wait_for(func(): return main.current_id == 6, 6.0)
	ok(main.current_id == 6 and area() == "", "離開診所：接到場景 6（搜捕隊）")
	ok(gs().stats == { "memory": 2, "humanity": 4 } and gs().items.is_empty(), "A 結束：記憶 2、人性 4、沒有物品")


## B：拿錄音筆再坐診療椅
func run_b() -> void:
	print("\n== B：拿錄音筆")
	await back_to_title()
	await start_game()
	await walk_to(1460); await choose(1)      # 撲上去
	ok(gs().stats["humanity"] == 2, "婦人選「撲上去」：人性 −1")
	await go_exit(2150, "street")
	await go_exit(2150, "clinic")
	await walk_to(1750); await interact(); await read()       # 先坐（還沒錄音筆）
	await walk_to(600); await interact(); await read()
	ok(gs().has_item("recorder") and not figure_visible("Cabinet"), "藥櫃：得到錄音筆、櫃上的錄音筆消失")
	await walk_to(1750)
	ok(prompt() == "E　坐下", "有錄音筆後，診療椅的提示變成「坐下」")
	await interact(); await choose(0)         # 反覆播放
	ok(gs().stats["memory"] == 1, "坐下聽錄音（反覆播放）：記憶 +1")
	await walk_to(1300); await walk_to(1750)
	ok(not main.prompt_label.visible, "聽過錄音後，診療椅不再反應")
	await walk_to(1300); await interact(); await read()
	ok(gs().stats["memory"] == 2, "治療室：記憶 +1")
	ok(gs().stats == { "memory": 2, "humanity": 2 }, "B 結束：記憶 2、人性 2")


## C：回標題再玩一輪，狀態全部重設
func run_c() -> void:
	print("\n== C：回標題再玩一輪")
	await back_to_title()
	ok(main.state == TITLE, "回到標題畫面")
	await start_game(false)
	ok(main.state == AREA_TEXT or main.state == TYPING, "新的一輪：停車場開場再次顯示")
	await read()
	ok(gs().stats == { "memory": 0, "humanity": 3 } and gs().items.is_empty() and gs().flags.is_empty(), "數值、物品、旗標都重設")
	ok(figure_visible("Woman"), "婦人重新出現")
	await walk_to(300); await interact(); await read()
	ok(gs().stats["memory"] == 1, "重設後同一處可以再加記憶")


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


func choose(index: int) -> void:
	await wait_for(func(): return main.state in [TYPING, CHOOSING], 5.0)
	if main.state == TYPING:
		await key("interact")
	await wait_for(func(): return main.state == CHOOSING, 3.0)
	(main.choices_box.get_child(index) as Button).pressed.emit()
	await read()


## 走到出口、按互動鍵、讀完出口文字，等新區域的開場（第一次）並讀完
func go_exit(x: float, next_area: String) -> void:
	await walk_to(x)
	await interact()
	if main.state in [TYPING, AREA_TEXT]:
		await read()
	await wait_for(func(): return area() == next_area and main.state != TRANSITION, 5.0)
	if main.state in [TYPING, AREA_TEXT]:
		await read()


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
		print("    狀態 state=%d area=%s scene=%d stats=%s flags=%s" % [main.state, area(), main.current_id, gs().stats, gs().flags.keys()])


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
