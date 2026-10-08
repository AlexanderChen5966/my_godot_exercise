## A1.5 自動測試：上下左右移動（縱深帶）、影子、頭上的互動提示、互動要走到物件前面、前後排序、spawns 的 [x, y]。
## 共用操作在 play_base.gd。執行：zsh tests/run_tests.sh test_a15
extends "res://tests/play_base.gd"

const TOP := 650.0
const BOTTOM := 735.0


func run_tests() -> void:
	await run_movement()
	await back_to_title()
	await run_prompt_and_depth()
	await back_to_title()
	await run_sorting_and_spawn()
	await back_to_title()
	run_spawn_validation()


## 按住方向鍵：上下停在縱深帶邊緣，上下速度約為左右的 0.6 倍
func run_movement() -> void:
	print("\n== 上下左右移動")
	await start_game()
	ok(area() == "parking_lot" and main.state == EXPLORE, "開始遊戲 → 停車場可以走動")
	ok(is_equal_approx(player().position.y, (TOP + BOTTOM) / 2.0), "進入區域時站在縱深帶中間")
	await hold("move_up", 120)
	ok(is_equal_approx(player().position.y, TOP), "按住上：停在縱深帶上緣 %d" % TOP)
	await hold("move_down", 200)
	ok(is_equal_approx(player().position.y, BOTTOM), "按住下：停在縱深帶下緣 %d" % BOTTOM)
	var y0 := player().position.y
	await hold("move_up", 30)
	var dy := y0 - player().position.y
	var x0 := player().position.x
	await hold("move_right", 30)
	var dx := player().position.x - x0
	ok(dy > 0.0 and absf(dy / dx - 0.6) < 0.05, "上下速度約為左右的 0.6 倍（%.1f / %.1f）" % [dy, dx])
	var shadow := player().get_node_or_null("Shadow")
	ok(shadow != null and shadow.get_index() < player().get_node("Sprite").get_index(), "主角腳下有影子，畫在角色下面")


## 互動提示：要靠近物件、站在物件前面的地面才出現；提示浮在主角頭上
func run_prompt_and_depth() -> void:
	print("\n== 提示與互動深度")
	await start_game()
	await walk_xy(1100, 680)
	ok(prompt() == "", "離地面殘骸 100：還沒有提示")
	await walk_xy(1060, 680)
	ok(prompt().contains("地面殘骸"), "離地面殘骸 60：出現提示")
	await frames(2)
	var head_y: float = player().get_global_transform_with_canvas().origin.y - 96.0
	var label: Label = main.prompt_label
	ok(label.position.y + label.size.y <= head_y and label.position.y > head_y - 80.0, "提示浮在主角頭上")
	await walk_xy(1000, 712)
	ok(prompt() == "", "站在縱深帶外側（y 712）：不會觸發地面殘骸")
	await walk_xy(1000, 660)
	await interact()
	ok(main.state in [TYPING, AREA_TEXT], "站到殘骸前面按互動鍵：可以調查")
	await read()
	# 人物事件（靠近觸發）涵蓋整個縱深帶：從最外側走過去也會遇到
	await walk_xy(1480, BOTTOM)
	await wait_for(func(): return main.state in [TYPING, AREA_TEXT], 3.0)
	ok(main.state in [TYPING, AREA_TEXT], "從縱深帶最外側走向婦人：照樣觸發事件")


## 前後排序（y_sort）與 spawns 的 y
func run_sorting_and_spawn() -> void:
	print("\n== 前後排序與出生點")
	await start_game()
	var a: Node2D = main.get("_area")
	ok(a.y_sort_enabled and a.get_node("Points").y_sort_enabled and a.get_node("Near").y_sort_enabled, "區域、互動點、近景都依 y 排序")
	ok((a.get_node("FrontLayer") as CanvasItem).z_index > 0, "前景層永遠畫在最前面")
	var woman_y: float = a.get_node("Points/Woman").position.y
	ok(woman_y > TOP and woman_y < BOTTOM, "婦人站在路中間（y %d）" % woman_y)
	a.call("place_player", 500.0, 720.0)
	ok(is_equal_approx(player().position.y, 720.0), "place_player(x, y)：放到指定的 y")
	a.call("place_player", 500.0, 900.0)
	ok(is_equal_approx(player().position.y, BOTTOM), "place_player 的 y 超出縱深帶：限制在邊緣")
	a.call("place_player", 600.0)
	ok(is_equal_approx(player().position.y, BOTTOM) and is_equal_approx(player().position.x, 600.0), "place_player 只給 x：y 不變")


## 劇本檢查認得 spawns 的 [x, y]，故意寫錯會報錯
func run_spawn_validation() -> void:
	print("\n== spawns 格式檢查")
	var areas: AreaData = main.get("areas")
	var story: StoryData = main.get("story")
	var spawns: Dictionary = areas.get_area("parking_lot")["spawns"]
	var backup := spawns.duplicate()
	spawns["street"] = [2150, 700]
	ok(not has_spawn_error(areas.validate(story)), "spawns 寫 [x, y]：通過檢查")
	spawns["street"] = [2150]
	ok(has_spawn_error(areas.validate(story)), "spawns 只有一個數字的陣列：報錯")
	spawns["street"] = "2150"
	ok(has_spawn_error(areas.validate(story)), "spawns 寫成字串：報錯")
	spawns.clear()
	spawns.merge(backup)


# ---- 這個測試專用的操作 ----

func hold(action: String, physics_frames: int) -> void:
	Input.action_press(action)
	await physics(physics_frames)
	Input.action_release(action)
	await physics(2)


func walk_xy(x: float, y: float) -> void:
	player().position = Vector2(x, y)
	await physics(4)
	await wait_for(func(): return main.state != TRANSITION, 3.0)


func has_spawn_error(errors: Array[String]) -> bool:
	for e in errors:
		if e.contains("spawns.street 格式不對"):
			return true
	return false
