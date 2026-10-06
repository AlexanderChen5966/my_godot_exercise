## Lv6-1 自動測試：只用鍵盤操作選項，一次按鍵只處理一件事。
## 共用操作在 play_base.gd（選選項用方向鍵＋Enter，互動鍵用真正的空白鍵）。執行：zsh tests/run_tests.sh test_lv6
extends "res://tests/play_base.gd"


func run_tests() -> void:
	await run_scene_keys()
	await back_to_title()
	await run_locked_focus()
	await back_to_title()
	await run_title_key()


## 過場的選項：自動聚焦、方向鍵移動、Enter 選擇後只開始打回應，不會同時跳過
func run_scene_keys() -> void:
	print("\n== 過場的選項")
	await start_game()
	main.call("_go_to", { "scene": 6 })
	await to_scene(6)
	await wait_choices()
	ok(focused() == 0, "搜捕隊：選項出現時聚焦第一個")
	await press_key(KEY_DOWN)
	ok(focused() == 1, "方向鍵下：移到第二個")
	await press_key(KEY_UP)
	ok(focused() == 0, "方向鍵上：回到第一個")
	await press_key(KEY_ENTER)
	ok(main.state == TYPING, "Enter 選擇：開始打回應文字（沒有同時跳過打字）")
	await press_key(KEY_SPACE)
	ok(main.state == RESPONSE, "空白鍵一次：只顯示全部文字，還停在回應")
	await press_key(KEY_SPACE)
	await to_scene(7)
	ok(main.current_id == 7, "空白鍵再一次：前往手術台")
	await choose(2); await enter("lab")
	ok(area() == "lab", "手術台用鍵盤選完 → 設施走廊")


## 鎖住的選項不能聚焦；結局的「重新開始」可以用鍵盤
func run_locked_focus() -> void:
	print("\n== 鎖住的選項與結局")
	await start_game()
	main.call("_switch_area", "wall")
	await enter("wall")
	await walk_to(1500); await interact(); await wait_choices()
	ok(locked(0) and locked(1) and focused() == 2, "牆前（記憶 0）：聚焦唯一能選的「永遠遊走」")
	await press_key(KEY_UP)
	ok(focused() == 2, "方向鍵上：不會移到鎖住的選項")
	await choose(2); await to_scene(20)
	await wait_choices()
	ok(focused() == 0, "結局 C：聚焦「重新開始」")
	await press_key(KEY_ENTER)
	await read()
	await wait_for(func(): return main.state == TITLE, 6.0)
	ok(main.state == TITLE, "結局用 Enter 重新開始 → 標題畫面")


## 標題畫面按一次空白鍵：開始遊戲，不會同時關掉停車場的開場
func run_title_key() -> void:
	print("\n== 標題畫面")
	ok(main.state == TITLE, "在標題畫面")
	await press_key(KEY_SPACE)
	await wait_for(func(): return main.state in [TYPING, AREA_TEXT], 5.0)
	ok(area() == "parking_lot" and main.state in [TYPING, AREA_TEXT], "空白鍵一次：開始遊戲，停車場開場正常顯示")


func focused() -> int:
	var owner := main.get_viewport().gui_get_focus_owner()
	return owner.get_index() if owner != null and owner.get_parent() == main.choices_box else -1
