extends Node2D

func _ready():
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
	var next_tier_value : float = UpgradesManager.get_upgrade_tier_data(upgrade,current_tier+1,"values")
	var next_tier_lvl_unlock : int = UpgradesManager.get_upgrade_tier_data(upgrade,current_tier+1,"unlock_lvl") if not maxed else 21
	maxed = Global.current_profile["lvl"] < next_tier_lvl_unlock
	var next_tier_cost : float = UpgradesManager.get_upgrade_tier_data(upgrade,current_tier+1,"unlock_cost")
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
				control.mouse_entered.connect(func(): on_button_hover(control))
				control.mouse_exited.connect(func(): on_button_hover_exit())
				control.focus_entered.connect(func(): on_button_focus())
				control.pressed.connect(func(): on_button_pressed(upgrade,next_tier_cost,next_tier_value))

func mouse_filter_disable(node:Control):
	for child:Control in node.get_children():
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mouse_filter_disable(child)

func on_button_hover(button:BaseButton):if not button.disabled:button.grab_focus()
func on_button_hover_exit():get_viewport().gui_release_focus()
func on_button_focus():AudioManager.play_ui("hover")
func on_button_pressed(upgrade,cost,value):
	if Global.current_profile["current_run"]["money"] < cost:AudioManager.play_ui("lock")
	else:
		print(upgrade,cost,value)
		Global.current_profile["current_run"]["money"] -= cost
		set_run_shop()

func _on_exit_pressed():Global.start_mod("Career")

func _on_run_shop_mouse_entered():%RunShop.modulate = Color(1.0, 1.0, 1.0, 1.0)
func _on_run_shop_mouse_exited():%RunShop.modulate = Color(1.0, 1.0, 1.0, 0.251)
func _on_crown_shop_mouse_entered():%CrownShop.modulate = Color(1.0, 1.0, 1.0, 1.0)
func _on_crown_shop_mouse_exited():%CrownShop.modulate = Color(1.0, 1.0, 1.0, 0.251)
