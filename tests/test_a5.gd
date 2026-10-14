## A5 自動測試：手勢（G 鍵比出「我——在——這——裡」）、人物的反應文字、沒有對象時的獨白、只反應一次、事件發生後不再反應、
## 比手勢時不能移動也不接受其他按鍵、對話中按 G 沒有作用、按鍵提示、數值不變（方案 A）、劇本檢查。
## 記憶閃回：調查關鍵物品時先閃回原插畫再顯示文字、可以跳過、一輪一次、診療椅沒有錄音筆時不閃回、劇本檢查。
## 共用操作在 play_base.gd。執行：zsh tests/run_tests.sh test_a5
extends "res://tests/play_base.gd"

const GESTURE := 7  # main.gd 的 State.GESTURE
const FLASHBACK := 8


func run_tests() -> void:
	await run_gesture_alone()
	await run_gesture_woman()
	await back_to_title()
	await run_flashback()
	await back_to_title()
	run_validation()


func gesture() -> void:
	await press_key(KEY_G)


## 等手勢播完（約 2 秒）
func wait_gesture_done() -> void:
	await wait_for(func(): return main.state != GESTURE, 4.0)


func run_gesture_alone() -> void:
	print("\n== 沒有對象")
	await start_game()
	ok(main.get("_gesture_hint").visible, "第一次可以走動：畫面下方顯示「G　比出手勢」")
	var stats: Dictionary = gs().stats.duplicate()
	var x := player().position.x
	await gesture()
	ok(main.state == GESTURE and String(player().get_node("Sprite").animation).begins_with("gesture_"), "按 G：主角比出手勢")
	ok(main.sound_log.back() == "inspect_4.ogg", "比手勢時有布料聲")
	Input.action_press("move_right")
	await physics(30)
	Input.action_release("move_right")
	ok(is_equal_approx(player().position.x, x), "比手勢時不能移動")
	await press_key(KEY_SPACE)
	ok(main.state == GESTURE, "比手勢時按互動鍵沒有作用")
	await wait_gesture_done()
	ok(main.state in [TYPING, AREA_TEXT] and main.body.text.contains("含糊"), "附近沒有人、第一次：比完顯示獨白")
	await read()
	ok(main.state == EXPLORE, "讀完獨白：可以繼續走動")
	await gesture()
	await wait_gesture_done()
	ok(main.state == EXPLORE, "第二次（沒有對象）：只有動畫，沒有文字")
	ok(gs().stats == stats, "比手勢不改變數值（方案 A）")


func run_gesture_woman() -> void:
	print("\n== 對婦人比手勢")
	await walk_to(1250)
	ok(main.state == EXPLORE and main.gesture_target() == "woman", "離婦人 250 px：事件還沒觸發，手勢的對象是婦人")
	player().face(-1)
	await gesture()
	ok(player().facing == 1, "比手勢時先轉向婦人")
	await wait_gesture_done()
	ok(main.state in [TYPING, AREA_TEXT] and main.body.text.contains("婦人僵在原地") and main.scene_title.text == "婦人", "比完：顯示婦人的反應")
	ok(gs().has_flag("parking_lot.woman.gesture"), "設定旗標 parking_lot.woman.gesture（之後的事件可以用）")
	await read()
	await gesture()
	await wait_gesture_done()
	ok(main.state == EXPLORE, "再對婦人比一次：不再反應（每人一輪一次）")

	# 對話中按 G 沒有作用
	await walk_to(1000); await interact()
	await gesture()
	ok(main.state in [TYPING, AREA_TEXT] and not String(player().get_node("Sprite").animation).begins_with("gesture_"), "調查文字打開時按 G：沒有作用")
	await read()

	# 婦人的事件發生後（逃走），不再是手勢的對象
	await walk_to(1460)
	await choose(0)
	await wait_for(func(): return main.state == EXPLORE, 3.0)
	gs().flags.erase("parking_lot.woman.gesture")
	await walk_to(1250)
	ok(main.gesture_target() == "", "婦人逃走後：不再是手勢的對象")


func run_flashback() -> void:
	print("\n== 記憶閃回")
	await start_game()
	await walk_to(300)
	var started := Time.get_ticks_msec()
	await interact()
	ok(main.state == FLASHBACK, "調查「醒來的地方」：進入記憶閃回")
	ok(main.sound_log.back() == "flashback", "閃回音")
	await wait_for(func(): return main.flashback.visible, 1.0)
	ok(main.flashback.visible and main.flashback.texture.resource_path.ends_with("scene_19.webp"), "白光之後出現插畫 scene_19（加上閃回 shader）")
	await wait_for(func(): return main.state in [TYPING, AREA_TEXT], 5.0)
	var took := (Time.get_ticks_msec() - started) / 1000.0
	ok(main.state in [TYPING, AREA_TEXT] and main.body.text.contains("照片") and not main.flashback.visible, "閃回結束（%.1f 秒）：回到區域，顯示原本的調查文字" % took)
	ok(took >= 2.5 and took <= 4.0, "閃回約 3 秒")
	await read()
	# 再調查一次（清掉「已調查」，保留「已閃回」）：不再閃回
	gs().flags.erase("parking_lot.wake")
	await interact()
	ok(main.state in [TYPING, AREA_TEXT], "同一輪再調查：不再閃回，直接顯示文字")
	await read()
	# 跳過：清掉兩個旗標再調查，閃回中按互動鍵
	gs().flags.erase("parking_lot.wake")
	gs().flags.erase("parking_lot.wake.flashback")
	await interact()
	await frames(10)
	started = Time.get_ticks_msec()
	await press_key(KEY_SPACE)
	await wait_for(func(): return main.state in [TYPING, AREA_TEXT], 3.0)
	ok(main.state in [TYPING, AREA_TEXT] and (Time.get_ticks_msec() - started) < 1200, "閃回中按互動鍵：跳過，馬上回到區域")
	await read()
	# 診療椅：只有拿到錄音筆的 variant 才閃回
	var chair: Dictionary = main.areas.get_area("clinic")["points"]["chair"]
	ok(not AreaData.view(chair, gs()).has("flashback"), "診療椅（沒有錄音筆）：不閃回")
	gs().add_item("recorder")
	ok(AreaData.view(chair, gs()).get("flashback", "") == "scene_05.webp", "診療椅（有錄音筆）：閃回 scene_05")


func run_validation() -> void:
	print("\n== 劇本檢查")
	var story: StoryData = main.story
	ok(AreaData.gesture_errors(story, { "gesture": { "text": "有反應", "range": 300, "effects": { "memory": 1 } } }, "x").is_empty(), "正確的 gesture：通過")
	ok(AreaData.gesture_errors(story, { "gesture": "文字" }, "x").size() == 1, "gesture 不是物件：報錯")
	ok(AreaData.gesture_errors(story, { "gesture": { "text": "  " } }, "x").size() == 1, "gesture 沒有 text：報錯")
	ok(AreaData.gesture_errors(story, { "gesture": { "text": "a", "range": -5 } }, "x").size() == 1, "gesture.range 不是正數：報錯")
	ok(AreaData.gesture_errors(story, { "gesture": { "text": "a", "effects": { "courage": 1 } } }, "x").size() == 1, "gesture.effects 用到不存在的數值：報錯")
	var with_gesture := 0
	for area_id in main.areas.area_ids():
		for point in main.areas.get_area(area_id).get("points", {}).values():
			if point.has("gesture"):
				with_gesture += 1
	ok(with_gesture == 7 and not story.gesture_alone.is_empty(), "資料：7 個互動點有手勢反應，另有沒有對象時的獨白")
	ok(AreaData.flashback_errors({ "type": "inspect", "flashback": "scene_10.webp" }, "x").is_empty(), "正確的 flashback：通過")
	ok(AreaData.flashback_errors({ "type": "inspect", "flashback": "scene_99.webp" }, "x").size() == 1, "flashback 插畫不存在：報錯")
	ok(AreaData.flashback_errors({ "type": "exit", "flashback": "scene_10.webp" }, "x").size() == 1, "出口有 flashback：報錯")
