extends Node2D

# State
var hovered_zone : Area2D
var zones : Dictionary
var running : bool
# Computer
var computer_datas : Dictionary
# Utilities
var hp_after_rest : float
var buy_datas : Dictionary
var bought_pass : String

func _ready():
	# Buttons
	set_up_buttons(self)
	# Bed
	var bed_healing : float = UpgradesManager.get_bed_data("healing")
	var current_day : Dictionary = Global.current_profile["current_run"]["current_day"]
	hp_after_rest = min(100,Global.current_profile["current_run"]["hp"] + bed_healing)
	%Background.texture = load(UpgradesManager.get_bed_data("texture"))
	zones[%Bed] = create_outline(%Bed)
	%DayNumber.text = "Day " + str(int(Global.current_profile["current_run"]["days"]))
	%DayDatas.text = "+ " + Global.format_number(current_day["money"]) + " \n\n" +\
					"+ " + str(int(current_day["stars"])) + " \n\n" +\
					"+ " + str(int(current_day["crowns"])) + " "
	%Healing.text = "HP after rest : " + str(int(hp_after_rest)) + " %"
	%Day.hide()
	# Computer
	zones[%Computer] = create_outline(%Computer)
	%BuyConfirm.hide()
	bought_pass = "None"
	%ComputerScreen.hide()
	# Ref computer nodes
	for node:Control in %ComputerScreen.get_children():
		if node.name == "Home": 
			node.show()
			for app_icon:Control in node.get_children():
				if app_icon.name != "ComputerExit":computer_datas[app_icon.name] = {"icon":app_icon}
		elif node.name == "Apps":
			node.hide()
			for app:Control in node.get_children():
				computer_datas[app.name]["app"] = app
				computer_datas[app.name]["exit_button"] = app.get_child(0).get_child(1)
	# Config apps
	app_config()
	# Computer Debug print
	for app in computer_datas:print(app,computer_datas[app])
	# Shelf
	for map in %Shelf.get_children():map.visible = map.name in Global.current_profile["map_records"].keys() and\
			Global.current_profile["map_records"][map.name]["collectible_stored"]
	# Exit
	%Exit.visible = Global.current_profile["state"] != "EndDay"
	%Windows.visible = Global.current_profile["state"] == "EndDay"
	# Start
	running = true

func _process(_delta):
	if not running : return
	var mouse_pos := get_global_mouse_position()
	var new_hovered_zone: Area2D = null
	for zone in zones.keys():
		var collision : CollisionPolygon2D = zone.get_child(0)
		var local_mouse := collision.to_local(mouse_pos)
		if Geometry2D.is_point_in_polygon(local_mouse, collision.polygon):
			new_hovered_zone = zone
			break
	if new_hovered_zone != hovered_zone:
		if hovered_zone != null:on_zone_exit(hovered_zone)
		hovered_zone = new_hovered_zone
		if hovered_zone != null:on_zone_hover(hovered_zone)

func app_config():
	for app in computer_datas:
		computer_datas[app]["icon"].set_meta("app",computer_datas[app]["app"])
		computer_datas[app]["icon"].pressed.connect(func(): on_icon_pressed(computer_datas[app]["icon"]))
		computer_datas[app]["exit_button"].pressed.connect(func(): on_exit_app_pressed())
	amazing_config()
	passes_config()
	achievements_config()
	bank_config()

func amazing_config():pass

func passes_config():
	var main : Panel = computer_datas["Passes"]["app"].get_child(1)
	var current_pass : String = Global.current_profile["current_run"]["current_day"]["pass"]
	for node:Control in main.get_children():
		if node.name == "Money":
			node.text = "Money :   " + Global.format_number(Global.current_profile["current_run"]["money"]) +\
			 "  [img]res://Images/HUD/Player/BucksLogo_mini.png"
		elif node.name == "Pass":node.text = "Current pass : " + current_pass
		elif node.name == "Tiles":
			for tile in node.get_children():
				var button : TextureButton = tile.get_child(0)
				var label : RichTextLabel = tile.get_child(1).get_child(2)
				var locked : bool = tile.name != "Forest"
				if locked:for unlock in Global.current_profile["current_run"]["unlocks"]:
					if tile.name in unlock:locked = false
				var owned : bool = false
				if not locked:owned = UpgradesManager.pass_grants_acces_to(tile.name)
				var price : float
				if not owned:price = UpgradesManager.datas["Passes"][tile.name]["price"]
				if locked:label.text = "LOCKED"
				elif owned:label.text = "OWNED"
				else:label.text = "Cost :   " + Global.format_number(price) +\
				 "  [img]res://Images/HUD/Player/BucksLogo_mini.png"
				button.set_meta("type","pass")
				button.set_meta("description",tile.name + " Pass")
				button.set_meta("price",price)
				button.set_meta("value",tile.name)
				button.pressed.connect(func(): on_pass_button_pressed(button))
				button.disabled = owned or locked

func achievements_config():
	var main : Panel = computer_datas["Achievements"]["app"].get_child(1)
	for node:Control in main.get_children():
		if node.name == "Level":node.text = "Current Level : " + str(int(Global.current_profile["lvl"]))
		elif node.name == "XP":node.text = "Current XP : " + str(int(Global.current_profile["xp"]))
		elif node.name == "ToNextLvl":
			var xp_obj : float = UpgradesManager.XP_LEVELS[int(Global.current_profile["lvl"])]
			var xp_left : float = xp_obj - Global.current_profile["xp"]
			node.text = "XP left to Level Up : " + str(int(xp_left))
		elif node.name == "Tiles":
			var ach_index : int = 0
			var current_values : Dictionary = UpgradesManager.get_map_datas()
			for ach in ["days","stars"]:current_values[ach]=Global.current_profile["current_run"][ach]
			for ach in ["played_day","money_gained"]:current_values[ach]=Global.current_profile[ach]
			for achievement in UpgradesManager.ACHIEVEMENTS:
				var datas : Dictionary = UpgradesManager.ACHIEVEMENTS[achievement]
				var current_tier := int(Global.current_profile["achievements"][achievement])
				var base : int = 0 if current_tier == 0 else int(datas["levels"][current_tier-1])
				var maximum := int(datas["levels"][current_tier])
				var current_value := int(current_values[achievement])
				var to_next := int(maximum-current_value)
				var tile : Panel = node.get_child(ach_index)
				for tile_node : Control in tile.get_children():
					if tile_node.name == "Name":tile_node.text = " " + datas["name"] + " :"
					if tile_node.name == "Description":tile_node.text = datas["description"]
					if tile_node.name == "ProgressBar":
						tile_node.min_value = base
						tile_node.max_value = maximum
						tile_node.value = current_value
					if tile_node.name == "Tier":tile_node.text = "Tier " + str(current_tier)
					if tile_node.name == "Current":tile_node.text = str(current_value)
					if tile_node.name == "ToNext":tile_node.text =  str(to_next) + " more for next Tier"
				ach_index += 1
		elif node.name == "Completion":
			var completed : float = 0
			for ach in Global.current_profile["achievements"]:
				completed += int(Global.current_profile["achievements"][ach])
			node.text = "Completion : " + str(int(100*completed/50)) + " %"

func bank_config():pass

func on_zone_hover(zone:Area2D):
	AudioManager.play_ui("map_hover")
	zones[zone].show()
func on_zone_exit(zone:Area2D):zones[zone].hide()
func on_zone_click(zone:Area2D):
	AudioManager.play_ui("click")
	# Reset zone
	running = false
	hovered_zone = null
	on_zone_exit(zone)
	# Day
	if zone == %Bed:%Day.show()
	# Computer
	elif zone == %Computer:%ComputerScreen.show()

func create_outline(zone:Area2D) -> Line2D :
	var zone_points : PackedVector2Array = zone.get_child(0).polygon 
	var outline := Line2D.new()
	zone.add_child(outline)
	# Style
	outline.width = 8
	outline.closed = true
	outline.joint_mode = Line2D.LINE_JOINT_ROUND
	outline.visible = false
	# Copying
	var index : int = 0
	while index < zone_points.size():
		outline.add_point(zone_points[index])
		index += 1
	return outline

func set_up_buttons(node):
	for child in node.get_children():
		if child is BaseButton:
			child.mouse_entered.connect(func(): on_button_hover(child))
			child.mouse_exited.connect(func(): on_button_hover_exit(child))
			child.focus_entered.connect(func(): on_button_focus(child))
			child.pressed.connect(func():on_button_pressed(child))
		set_up_buttons(child)
func on_button_hover(button:BaseButton):if not button.disabled:button.grab_focus()
func on_button_hover_exit(_button:BaseButton):get_viewport().gui_release_focus()
func on_button_focus(button:BaseButton):
	if button.disabled:return
	AudioManager.play_ui("hover")
func on_button_pressed(button:BaseButton):if button.get_meta("price",0) == 0:AudioManager.play_ui("click")

func on_icon_pressed(button:BaseButton):
	%Home.hide()
	%Apps.show()
	for app in %Apps.get_children():app.hide()
	button.get_meta("app").show()

func on_pass_button_pressed(button:BaseButton):
	if  Global.current_profile["current_run"]["money"] >= button.get_meta("price"):
		AudioManager.play_ui("click")
		for data in ["type","description","price","value"]:buy_datas[data] = button.get_meta(data)
		%BuyInfos.text = "\n" + buy_datas["description"] + "\n" +"Cost :  " + Global.format_number(buy_datas["price"])
		%BuyInfos.get_child(0).texture = load("res://Images/HUD/Player/BucksLogo_mini.png")
		%Apps.hide()
		%BuyConfirm.show()
	else:AudioManager.play_ui("lock")

func on_exit_app_pressed():
	%Home.show()
	%Apps.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if hovered_zone != null:on_zone_click(hovered_zone)

func _on_exit_pressed():Global.start_mod("Career")

func _on_end_day_pressed():
	Global.set_day(true,bought_pass)
	Global.current_profile["state"] = "Career"
	Global.start_mod("Career")
	SaveManager.save_profile(Global.current_profile)

func _on_close_day_pressed():
	running = true
	%Day.hide()

func _on_computer_exit_pressed():
	running = true
	%ComputerScreen.hide()

func _on_no_pressed():
	%BuyConfirm.hide()
	%Apps.show()

func _on_confirm_buy_button_pressed():
	if buy_datas["type"] == "pass":
		Global.current_profile["current_run"]["money"] -= buy_datas["price"]
		bought_pass = buy_datas["value"]
		Global.current_profile["current_run"]["current_day"]["pass"] = buy_datas["value"]
		passes_config()
		%BuyConfirm.hide()
		%Apps.show()
