extends Node2D

# State
var hovered_zone : Area2D
var zones : Dictionary
var running : bool

var hp_after_rest : float

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
	%ComputerScreen.hide()
	# Shelf
	for map in %Shelf.get_children():map.visible = map.name in Global.current_profile["map_records"].keys() and\
			Global.current_profile["map_records"][map.name]["collectible_stored"]
	# Exit
	%Exit.visible = Global.current_profile["state"] != "EndDay"
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
func on_button_focus(_button:BaseButton):AudioManager.play_ui("hover")
func on_button_pressed(_button:BaseButton):AudioManager.play_ui("click")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if hovered_zone != null:on_zone_click(hovered_zone)

func _on_exit_pressed():Global.start_mod("Career")

func _on_end_day_pressed():
	Global.set_day(true)
	Global.current_profile["state"] = "Career"
	Global.start_mod("Career")
	SaveManager.save_profile(Global.current_profile)

func _on_close_day_pressed():
	running = true
	%Day.hide()

func _on_computer_exit_pressed():
	running = true
	%ComputerScreen.hide()
