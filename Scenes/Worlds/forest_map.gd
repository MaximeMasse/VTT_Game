extends Node2D

# Datas
var world_datas : Dictionary = {"Nodes":{},"Zones":{}}
var player_datas : Dictionary

# State
var hovered_zone : Area2D
var active_zones : Dictionary
var running

func _ready():
	get_tree().debug_collisions_hint = false
	running = false
	# Change scene buttons
	set_up_button(%ToVillageButton)
	set_up_button(%Desert)
	%Desert.hide()
	# Travel update
	if Global.current_node_is_map():Global.append_course()
	# Ref names, nodes and zones, create outline.
	# Node init, valid and stars, naming
	for node in %Nodes.get_children():
		var node_data : Dictionary = {"node":node,"zone_out":[]}
		# Maps
		if node is TextureButton:
			set_up_button(node)
			node.disabled = true
			node_data["done"] = node.get_child(0)
			node_data["valid"] = node.get_child(1)
			# Stars for regular map
			if "Boss" not in node.name:node_data["stars"] = node.get_child(2)
		world_datas["Nodes"][node.name] = node_data.duplicate()
	# Zones outline, lock, path ref and nodes in and out ref
	for zone in %Zones.get_children():
		var origin_name : String = zone.name.split("_")[0]
		var destination_name : String = zone.name.split("_")[1]
		world_datas["Zones"][zone] = {}
		# Path
		world_datas["Zones"][zone]["path"] = zone.get_child(1)
		# Has Lock
		world_datas["Zones"][zone]["has_lock"] = true if zone.get_child_count() == 3 else false
		# Outline
		world_datas["Zones"][zone]["outline"] = create_outline(zone)
		# In and out
		for node in world_datas["Nodes"]:
			if origin_name == node:world_datas["Nodes"][node]["zone_out"].append(zone)
			if destination_name == node:world_datas["Nodes"][node]["zone_in"]=zone
	# Player_data
	set_player_datas()
	# Update world
	update_world()
	# Current node new paths and active zone
	draw_new_paths()
	# Active zones
	set_active_zones()
	# Debug print
	print("Nodes :")
	for node in world_datas["Nodes"]:print(node," : ",world_datas["Nodes"][node])
	print("\nZones :")
	for zone in world_datas["Zones"]:print(zone," : ",world_datas["Zones"][zone])
	print("\nPlayer datas : ",player_datas)
	print("\nActives zones : ",active_zones)
	running = true

func set_player_datas():
	player_datas["finished_maps"] = []
	for map in Global.current_profile["map_records"].keys():player_datas["finished_maps"].append(map)
	player_datas["run_finished_maps"] = []
	player_datas["run_seen_maps"] = []
	for map in Global.current_profile["current_run"]["maps"]:
		player_datas["run_seen_maps"].append(map)
		if Global.current_profile["current_run"]["maps"][map]["finished"]:player_datas["run_finished_maps"].append(map)
	player_datas["world"] = Global.current_profile["current_run"]["current_day"]["world"]
	player_datas["node"] = Global.current_profile["current_run"]["current_day"]["node"]
	player_datas["course"] = Global.current_profile["current_run"]["current_day"]["course"]
	player_datas["unlocks"] = Global.current_profile["current_run"]["unlocks"]

func update_world():
	for node in world_datas["Nodes"]:
		var node_datas : Dictionary = world_datas["Nodes"][node]
		var path_in = world_datas["Zones"][node_datas["zone_in"]]["path"]
		# Unknow
		if node not in player_datas["finished_maps"]:
			for thing in ["done","valid"]: if node_datas.has(thing):node_datas[thing].hide()
			node_datas["node"].hide()
			if path_in is Line2D:
				path_in.hide()
		# Finished on previous run
		elif node not in player_datas["run_seen_maps"]:
			for thing in ["done","valid"]:node_datas[thing].hide()
			node_datas["node"].modulate = Color(0.0, 0.0, 0.0, 1.0)
			if path_in is Line2D:
				path_in.get_child(0).hide()
				path_in.modulate = Color(0.0, 0.0, 0.0, 1.0)
		# Seen this run
		elif node not in player_datas["run_finished_maps"]:
			for thing in ["done","valid"]:node_datas[thing].hide()
			node_datas["node"].modulate = Color(0.5, 0.5, 0.5, 1.0)
			if "Boss" not in node:node_datas["stars"].hide()
			if path_in is Line2D:
				path_in.get_child(0).hide()
				path_in.modulate = Color(0.5, 0.5, 0.5, 1.0)
		# Finished this run
		elif node not in player_datas["course"]:
			node_datas["done"].hide()
			node_datas["node"].modulate = Color(0.5, 0.5, 0.5, 1.0)
			if "Boss" not in node:node_datas["stars"].stars_update(Global.current_profile["current_run"]["maps"][node]["objectives"])
			if path_in is Line2D:
				path_in.get_child(0).hide()
				path_in.modulate = Color(0.5, 0.5, 0.5, 1.0)
		# Traveled
		else:
			if "Boss" not in node:node_datas["stars"].stars_update(Global.current_profile["current_run"]["maps"][node]["objectives"])
		# Chairlifts specifics
		if "Chairlift" in node:
			# Anim
			if "To" not in node or node in player_datas["unlocks"]:world_datas["Zones"][node_datas["zone_out"][0]]["path"].unlock()
			# Path to final chairlift to see if previous map done
			if "To" in node:
				# Previous map finished this run
				if path_in.name.split("_")[0] in player_datas["run_finished_maps"]:
					path_in.show()
					path_in.get_child(0).hide()
					path_in.modulate = Color(0.5, 0.5, 0.5, 1.0)
				# Previous map finished on previous run
				elif path_in.name.split("_")[0] in player_datas["finished_maps"]:
					path_in.show()
					path_in.get_child(0).hide()
					path_in.modulate = Color(0.0, 0.0, 0.0, 1.0)
				# Hide lock if path hiden
				else:path_in.get_parent().get_child(2).hide()

func draw_new_paths():
	print("\nDraw_new_paths :\nCurrent node : ",player_datas["node"])
	# Out path of current node
	for zone in world_datas["Nodes"][player_datas["node"]]["zone_out"]:
		var destination : String = zone.name.split("_")[1] 
		# Origin or destination not chairlift
		if "Chairlift" not in zone.name:
			# Destination never seen
			if destination not in player_datas["finished_maps"]:print("draw never seen path to : ",destination)
			# Destination never seen this run
			elif destination not in player_datas["run_seen_maps"]: print("draw never seen this run path to : ",destination)
		# Map0 enlightment if hiden or black
		elif not world_datas["Nodes"][destination]["node"].visible or\
			world_datas["Nodes"][destination]["node"].modulate == Color(0.0, 0.0, 0.0, 1.0):
				for child in world_datas["Nodes"][destination]["node"].get_children():child.hide()
				world_datas["Nodes"][destination]["node"].modulate = Color(0.5, 0.5, 0.5, 1.0)
				world_datas["Nodes"][destination]["node"].show()

func set_active_zones():
	world_datas["Nodes"][player_datas["node"]]["node"].modulate = Color(1.0, 1.0, 1.0, 1.0)
	for zone in world_datas["Nodes"][player_datas["node"]]["zone_out"]:
		active_zones[zone] = false if world_datas["Zones"][zone]["has_lock"] and\
					zone.name.split("_")[1] not in player_datas["unlocks"] else true

func on_zone_hover(zone:Area2D):
	AudioManager.play_ui("map_hover")
	# Regular zone
	if active_zones[zone] :
		world_datas["Nodes"][zone.name.split("_")[1]]["node"].modulate = Color(1.0, 1.0, 1.0, 1.0)
		world_datas["Zones"][zone].modulate = Color(1.0, 1.0, 1.0, 1.0)
		world_datas["Zones"][zone]["path"].modulate = Color(1.0, 1.0, 1.0, 1.0)
		world_datas["Zones"][zone]["outline"].show()
	# Locked zone
	else :
		world_datas["Zones"][zone].modulate = Color(0.5, 0.5, 0.5, 1.0)
		world_datas["Zones"][zone]["outline"].modulate = Color(0.5, 0.5, 0.5, 1.0)
		world_datas["Zones"][zone]["outline"].show()
func on_zone_exit(zone:Area2D):
		world_datas["Nodes"][zone.name.split("_")[1]]["node"].modulate = Color(0.5, 0.5, 0.5, 1.0)
		world_datas["Zones"][zone].modulate = Color(0.5, 0.5, 0.5, 1.0)
		if "Chairlift" not in zone.name.split("_")[0]:world_datas["Zones"][zone]["path"].modulate = Color(0.5, 0.5, 0.5, 1.0)
		world_datas["Zones"][zone]["outline"].hide()
func on_zone_click(zone:Area2D):
	if active_zones[zone] :
		AudioManager.play_ui("click")
		active_zones = {}
		running = false
		on_zone_exit(zone)
		var origin : String = zone.name.split("_")[0] 
		var destination : String = zone.name.split("_")[1]
		Global.current_profile["current_run"]["current_day"]["node"] = destination
		if "Chairlift" in origin:
			AudioManager.play_sfx("chairlift")
			world_datas["Zones"][zone]["path"].play()
			if "To" in origin:%Desert.show()
			else:world_datas["Nodes"][destination]["node"].disabled = false
		else:
			print("travel anim")
		await get_tree().create_timer(3).timeout
		world_datas["Nodes"][destination]["node"].disabled = false
		world_datas["Zones"][zone]["path"].modulate = Color(1.0, 1.0, 1.0, 1.0)
		world_datas["Nodes"][destination]["node"].modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:AudioManager.play_ui("lock")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
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

func draw_path(path:Line2D,duration:float):
	var path_points : PackedVector2Array = path.points
	var copy_line := Line2D.new()
	path.get_parent().add_child(copy_line)
	var drawing_frequency : float = duration/path_points.size()
	# Style copy
	copy_line.position = path.position
	copy_line.z_index = path.z_index
	copy_line.z_as_relative = path.z_as_relative
	copy_line.width = path.width
	# Drawing
	var index : int = 0
	while index < path_points.size():
		copy_line.add_point(path_points[index])
		index += 1
		await get_tree().create_timer(drawing_frequency).timeout

func set_up_button(node:BaseButton):
	node.mouse_entered.connect(func(): on_button_hover(node))
	node.mouse_exited.connect(func(): on_button_hover_exit(node))
	node.pressed.connect(func():on_button_pressed(node))
func on_button_hover(button:BaseButton):if not button.disabled:AudioManager.play_ui("hover")
func on_button_hover_exit(_button:BaseButton):get_viewport().gui_release_focus()
func on_button_pressed(_button:BaseButton):AudioManager.play_ui("click")

func start_map(map_name:String):
		Global.current_map = map_name
		Global.start_mod("Main_Game")
func _on_0_pressed():
	if Global.get_profile_data("state") == "tuto":Global.start_mod("Tuto_Game")
	else:start_map("0")
func _on_1_pressed():start_map("1")
func _on_2_pressed():start_map("2")
func _on_forest_boss_pressed():start_map("ForestBoss")
