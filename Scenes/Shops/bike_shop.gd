extends Node2D

var buy_datas : Dictionary

func _ready():
	# Buttons
	set_up_buttons(self)
	# Shops
	%BuyConfirm.hide()
	for node:Control in [%RunShop,%CrownShop]:
		node.modulate = Color(1.0, 1.0, 1.0, 0.251)
		mouse_filter_disable(node)
	set_run_shop()

func set_run_shop():
	for node:Control in %RunShop.get_children():
		if node.name == "Money":node.text = "[img]res://Images/HUD/Player/BucksLogo_mini.png[/img] : " +\
			Global.format_number(Global.current_profile["current_run"]["money"])
		elif node.name == "Level":node.text = "CURRENT LEVEL : " + Global.format_number(Global.current_profile["lvl"])
		elif node.name == "Tiles":for tile in node.get_children():set_run_tile(tile)

func set_run_tile(tile:Panel):
	var upgrade : String = tile.name
	var current_tier : int = UpgradesManager.get_upgrade_tier(upgrade,Global.current_profile["stats"][upgrade])
	var maxed : bool = not current_tier < 5
	var next_tier_value : float = UpgradesManager.get_upgrade_tier_data(upgrade,current_tier+1,"values") if not maxed else 21
	var next_tier_lvl_unlock : int = UpgradesManager.get_upgrade_tier_data(upgrade,current_tier+1,"unlock_lvl") if not maxed else 21
	maxed = Global.current_profile["lvl"] < next_tier_lvl_unlock
	var next_tier_cost : float = UpgradesManager.get_upgrade_tier_data(upgrade,current_tier+1,"unlock_cost") if not maxed else 21
	# Tile Color
	var color: Color
	if maxed:color = Color(0.298, 0.373, 0.969, 1.0)
	elif Global.current_profile["current_run"]["money"] < next_tier_cost:color = Color(0.886, 0.643, 0.0, 1.0)
	else:color = Color(0.361, 0.624, 0.278)
	tile.get_theme_stylebox("panel").bg_color = color
	# Inner controls setup
	for control:Control in tile.get_children():
		if control.name == "CurrentLvl":control.text =  "Current Upgrade :\nTier  " + str(current_tier)
		elif control.name == "NextLvl":
			if maxed:
				control.text = "Next Upgrade :\nMaxed Out" if current_tier == 5 else "Next Upgrade :\n"+\
				"Unlock At LVL " + str(next_tier_lvl_unlock)
				control.get_child(0).hide()
			else:
				control.text = "Next Upgrade :\n" + Global.format_number(next_tier_cost)
				control.get_child(0).show()
		elif control.name == "Buy":
			if maxed:control.hide()
			else:
				control.show()
				control.mouse_filter = Control.MOUSE_FILTER_PASS
				control.set_meta("upgrade",upgrade)
				control.set_meta("current_tier",current_tier)
				control.set_meta("cost",next_tier_cost)
				control.set_meta("value",next_tier_value)

func set_up_buttons(node):
	for child in node.get_children():
		if child is BaseButton:
			child.mouse_entered.connect(func(): on_button_hover(child))
			child.mouse_exited.connect(func(): on_button_hover_exit())
			child.focus_entered.connect(func(): on_button_focus())
			if child.name == "Buy":child.pressed.connect(func():on_run_button_pressed(child))
			elif child.name == "Unlock":child.pressed.connect(func():on_permanent_button_pressed(child))
			else :child.pressed.connect(func():on_button_pressed())
		set_up_buttons(child)

func mouse_filter_disable(node:Control):
	for child:Control in node.get_children():
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mouse_filter_disable(child)

func on_button_hover(button:BaseButton):if not button.disabled:button.grab_focus()
func on_button_hover_exit():get_viewport().gui_release_focus()
func on_button_focus():AudioManager.play_ui("hover")
func on_button_pressed():AudioManager.play_ui("click")

func on_run_button_pressed(button:BaseButton):
	for data in ["upgrade","current_tier","cost","value"]:buy_datas[data] = button.get_meta(data)
	if Global.current_profile["current_run"]["money"] < buy_datas["cost"]:AudioManager.play_ui("lock")
	else:
		AudioManager.play_ui("click")
		# Hide other panels
		for node:Control in [%RunShop,%CrownShop]:node.hide()
		# Set up confirm panel
		%BuyInfos.text = buy_datas["upgrade"] + "\n" +\
			"Tier " + str(buy_datas["current_tier"]) + " -> Tier " + str(buy_datas["current_tier"] + 1) + "\n" +\
			Global.format_number(buy_datas["cost"])
		%BuyConfirm.show()

func on_permanent_button_pressed(button:BaseButton):pass

func _on_confirm_buy_button_pressed() -> void:
	Global.current_profile["current_run"]["money"] -= buy_datas["cost"]
	Global.current_profile["stats"][buy_datas["upgrade"]] = buy_datas["value"]
	SaveManager.save_profile(Global.current_profile)
	set_run_shop()
	_on_no_pressed()

func _on_no_pressed() -> void:
	%BuyConfirm.hide()
	for node:Control in [%RunShop,%CrownShop]:node.show()
	
func _on_exit_pressed():Global.start_mod("Career")

func _on_run_shop_mouse_entered():%RunShop.modulate = Color(1.0, 1.0, 1.0, 1.0)
func _on_run_shop_mouse_exited():%RunShop.modulate = Color(1.0, 1.0, 1.0, 0.251)
func _on_crown_shop_mouse_entered():%CrownShop.modulate = Color(1.0, 1.0, 1.0, 1.0)
func _on_crown_shop_mouse_exited():%CrownShop.modulate = Color(1.0, 1.0, 1.0, 0.251)
