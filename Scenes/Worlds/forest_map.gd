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
	# Ref names, nodes and zones, create outline.
	# Node init, valid and stars, naming
	for node in %Nodes.get_children():
		world_datas["Nodes"][node] = {"paths_to":[],"paths_from":[]}
		node_by_name[node.name]=node
		if node.name in Global.current_profile["current_run"]["finished_maps"].keys():node.get_child(0).show()
		if node.name in Global.current_day["course"]:node.get_child(0).get_child(0).show()
		if node.get_child_count()>1 and "Boss" not in node.name and\
			node.name in Global.current_profile["current_run"]["finished_maps"].keys():
			node.get_child(1).stars_update(Global.current_profile["current_run"]["finished_maps"][node.name]["objectives"])
	# Zones outline, lock, path ref and nodes in and out ref
	for zone in %Zones.get_children():
		var origin_name : String = zone.name.split("_")[0]
		var destination_name : String = zone.name.split("_")[1]
		world_datas["Zones"][zone] = {}
		# Path
		world_datas["Zones"][zone]["path"] = zone.get_child(1)
		# Lock
		world_datas["Zones"][zone]["locked"] = true if zone.get_child(1).get_child_count()!=0\
		and zone.get_child(1).get_child(0).name == "Lock"\
		and destination_name not in Global.current_profile["current_run"]["unlocks"] else false
		# Outline
		world_datas["Zones"][zone]["outline"] = create_outline(zone)
		# In and out
		for node in %Nodes.get_children():
			if origin_name == node.name:world_datas["Nodes"][node]["paths_from"].append(zone)
			if destination_name == node.name:world_datas["Nodes"][node]["paths_to"].append(zone)
	update_world()
	# Debug print
	print("Nodes :")
	for node in world_datas["Nodes"]:print(node.name," : ",world_datas["Nodes"][node])
	print("\nZones :")
	for zone in world_datas["Zones"]:print(zone.name," : ",world_datas["Zones"][zone])
	print("\nCurrent_day : ",Global.current_day)


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

func update_world():
	# Nodes
	for node in world_datas["Nodes"]:
		var node_datas : Dictionary = world_datas["Nodes"][node]
		var paths_to : Array 
		for zone in node_datas["paths_to"]:paths_to.append(world_datas["Zones"][zone]["path"])
		var paths_from : Array
		for zone in node_datas["paths_from"]:paths_from.append(world_datas["Zones"][zone]["path"])
		# Chairlift
		if "Chairlift" in node.name:if "To" not in node.name or node.name in Global.current_profile["current_run"]["unlocks"]:paths_from[0].unlock()
		# Map node
		# If traveled already
		if node.name in Global.current_day["course"]:
			node.modulate = Color(0.363, 0.622, 0.277, 1.0)
			for path in paths_to:if "Chairlift" not in path.name:path.modulate = Color(0.363, 0.622, 0.277, 1.0)
		# If seen this run
		elif node.name in Global.current_profile["current_run"]["finished_maps"].keys():
			node.modulate = Color(0.502, 0.502, 0.502, 1.0)
			for path in paths_to:if "Chairlift" not in path.name:path.modulate = Color(0.502, 0.502, 0.502, 1.0)
		# If seen
		elif node.name in Global.current_profile["map_record"].keys():
			node.modulate = Color(0.0, 0.0, 0.0, 1.0)
			for path in paths_to:if "Chairlift" not in path.name:path.modulate = Color(0.0, 0.0, 0.0, 1.0)
		# Unknown
		else:
			node.hide()
			for path in paths_to:if "_" in path.name :path.hide()

func on_zone_hover(zone:Area2D):pass
func on_zone_exit(zone:Area2D):pass
func on_zone_click(zone:Area2D):pass

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

func set_up_button(node:BaseButton):
	node.disabled = true
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
