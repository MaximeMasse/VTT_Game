extends Node2D

# Datas
var world_datas : Dictionary = {"Nodes":{},"Zones":{}}
var node_by_name : Dictionary

# State
var hovered_zone : Area2D
var active_zones : Dictionary
var running

func _ready():
	get_tree().debug_collisions_hint = false
	running = false
	# Nodes de-activation and actives zones array init
	for node in %Nodes.get_children():
		if node is TextureButton:set_up_button(node)
		world_datas["Nodes"][node] = []
	# Creating outlines, referencing
	for zone in %Zones.get_children():
		var zone_datas : Dictionary
		# Nodes
		var origin_name = zone.name.split("_")[0]
		var destination_name = zone.name.split("_")[1]
		for node in %Nodes.get_children():
			# Stars and valid
			if node.name in World.current("run_finished_maps"):
				node.get_child(0).show()
				node.get_child(1).stars_update(
					Global.current_profile["current_run"]["finished_maps"][node.name]["objectives"])
			# Naming refs
			node_by_name[node.name]=node
			if node.name == origin_name:
				zone_datas["origin"] = node
				world_datas["Nodes"][node].append(zone)
			elif node.name == destination_name:zone_datas["destination"] = node
		# Paths
		if zone.get_child_count() > 1 : zone_datas["path"] = zone.get_child(1)
		# Lock
		zone_datas["lock"] = true if zone.get_child_count() > 2 else false
		# Outline
		zone_datas["outline"] = create_outline(zone)
		world_datas["Zones"][zone] = zone_datas.duplicate()
	# Current states
	set_world_state()
	running = true

func create_outline(zone:Area2D) -> Line2D :
	var zone_points : PackedVector2Array = zone.get_child(0).polygon 
	var outline := Line2D.new()
	zone.add_child(outline)
	# Style
	outline.width = 8
	outline.closed = true
	outline.visible = false
	# Copying
	var index : int = 0
	while index < zone_points.size():
		outline.add_point(zone_points[index])
		index += 1
	return outline

func set_world_state():
	# Debug print
	print("Nodes :")
	for node in world_datas["Nodes"]:print(node," : ",world_datas["Nodes"][node])
	print("\nZones :")
	for zone in world_datas["Zones"]:print(zone," : ",world_datas["Zones"][zone])
	print("\nCurrent_day : ",Global.current_day)
	print("\nWorld data : ",World.current_world_datas)
	# Static
	for zone in world_datas["Zones"]:
		var zone_datas : Dictionary = world_datas["Zones"][zone]
		var origin : Node = zone_datas["origin"]
		var destination : Node = zone_datas["destination"]
		# Never seen
		if "Chairlift" not in origin.name and destination.name not in World.current("finished_maps"):
			zone.hide()
			destination.hide()
		# Never seen this run
		elif "Chairlift" not in origin.name and destination.name not in World.current("run_finished_maps"):
			zone.modulate = Color(0.0, 0.0, 0.0, 1.0)
			destination.modulate = Color(0.0, 0.0, 0.0, 1.0)
		# Traveled
		elif origin.name in World.current("course"):
			zone.modulate = Color(0.208, 0.91, 0.235, 1.0)
			origin.modulate = Color(0.208, 0.91, 0.235, 1.0)
		# Seen this run
		else :
			zone.modulate = Color(0.5, 0.5, 0.5, 1.0)
			origin.modulate = Color(0.5, 0.5, 0.5, 1.0)
		# Chairlifts
		if "Chairlift" in origin.name:
			origin.show()
			if "To" not in origin.name or origin.name in World.current("unlocks"):origin.unlock()
	# Active
	var current_node : Node = node_by_name[World.current("node")]
	current_node.modulate = Color(1.0, 1.0, 1.0, 1.0)
	current_node.show()
	for zone in world_datas["Nodes"][current_node]:
		var zone_datas : Dictionary = world_datas["Zones"][zone]
		if zone_datas["lock"] and zone_datas["destination"] not in World.current("unlocks"):
			active_zones[zone] = "locked"
		else:active_zones[zone] = "unlocked"
		zone_datas["destination"].modulate = Color(0.5, 0.5, 0.5, 1.0)
		zone_datas["destination"].show()
		zone.show()

func on_zone_hover(zone: Area2D):
	AudioManager.play_ui("map_hover")
	zone.modulate = Color(1,1,1,1)
	world_datas["Zones"][zone]["destination"].modulate = Color(1,1,1,1)
	world_datas["Zones"][zone]["outline"].show()
func on_zone_exit(zone: Area2D):
	zone.modulate = Color(0.5, 0.5, 0.5, 1.0) if active_zones[zone] == "locked" else Color(1,1,1,1)
	world_datas["Zones"][zone]["destination"].modulate = Color(0.5, 0.5, 0.5, 1.0)
	world_datas["Zones"][zone]["outline"].hide()
func on_zone_click(zone: Area2D):
	# Locked zone
	if active_zones[zone] == "locked":AudioManager.play_ui("lock") 
	else:
		running = false
		AudioManager.play_ui("click")
		# Reset zones
		on_zone_exit(zone)
		active_zones = {}
		# Update
		var zone_datas : Dictionary = world_datas["Zones"][zone]
		var origin : Node = zone_datas["origin"]
		var destination : Node = zone_datas["destination"]
		if "Chairlift" in origin.name:
			AudioManager.play_sfx("chairlift")
			origin.play()
			await get_tree().create_timer(3).timeout
		var new_course : Array = World.current("course")
		new_course.append(origin.name)
		World.change("course",new_course.duplicate())
		World.change("node",destination.name)
		World.profile_update()
		# If destination is button
		if destination is TextureButton:
			destination.modulate = Color(1.0, 1.0, 1.0, 1.0)
			destination.disabled = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if hovered_zone != null:on_zone_click(hovered_zone)

func _process(_delta):
	if not running : return
	var mouse_pos := get_global_mouse_position()
	var new_hovered_zone: Area2D = null
	for zone in active_zones.keys():
		var collision : CollisionPolygon2D = zone.get_child(0)
		var local_mouse := collision.to_local(mouse_pos)
		if Geometry2D.is_point_in_polygon(local_mouse, collision.polygon):
			new_hovered_zone = zone
			break
	if new_hovered_zone != hovered_zone:
		if hovered_zone != null:on_zone_exit(hovered_zone)
		hovered_zone = new_hovered_zone
		if hovered_zone != null:on_zone_hover(hovered_zone)

func set_up_button(node:BaseButton):
	node.disabled = true
	node.mouse_entered.connect(func(): on_button_hover(node))
	node.mouse_exited.connect(func(): on_button_hover_exit(node))
	node.pressed.connect(func():on_button_pressed(node))
func on_button_hover(button:BaseButton):if not button.disabled:AudioManager.play_ui("hover")
func on_button_hover_exit(_button:BaseButton):get_viewport().gui_release_focus()
func on_button_pressed(_button:BaseButton):AudioManager.play_ui("click")

func _on_0_pressed():
	if Global.get_profile_data("state") == "tuto":Global.start_mod("Tuto_Game")
	else:
		Global.current_map = "0"
		Global.start_mod("Main_Game")

func _on_1_pressed():
	Global.current_map = "1"
	Global.start_mod("Main_Game")
