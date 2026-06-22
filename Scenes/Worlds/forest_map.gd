extends Node2D

# Anim times
var path_drawing_time : float = 3.0 if not Global.debug else 0.0
var path_riding_time : float = 5.0 if not Global.debug else 0.0
var to_chairlift_time : float = 1.5 if not Global.debug else 0.0
var to_chairlift_scale_factor : float = 0.7

# Datas
var world_datas : Dictionary = {"Nodes":{},"Zones":{},"start":"Chairlift"}
var player_datas : Dictionary

# State
var hovered_zone : Area2D
var active_zones : Dictionary
var running : bool

# Unlocks
var unlocks : Dictionary = {
	"Chairlift To Desert" : {
		"map_finished":"Boss 1 Map",
		"stars":5,
		"cam_position":"Map 1_Chairlift To Desert"
		}
}

func _ready():
	get_tree().debug_collisions_hint = false
	running = false
	# Change scene buttons
	set_up_button(%ToVillageButton)
	set_up_button(%Desert)
	%Desert.hide()
	# Reset cam
	%WorldCam.position_cam("reset",true)
	%WorldCam.position_cam("full_screen")
	# Travel update
	if Global.current_node_is_map():Global.append_course()
	# Ref names, nodes and zones, create outline.
	# Node init, valid and stars, naming
	for node in %Nodes.get_children():
		var node_data : Dictionary = {"node":node,"zone_out":[]}
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	# New unlocks
	check_unlocks()
	# Current node new paths and active zone
	await draw_new_paths()
	# Debug print
	#print("Nodes :")
	#for node in world_datas["Nodes"]:print(node," : ",world_datas["Nodes"][node])
	#print("\nZones :")
	#for zone in world_datas["Zones"]:print(zone," : ",world_datas["Zones"][zone])
	#print("\nPlayer datas : ",player_datas)
	#print("\nActives zones : ",active_zones)
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
	# Boss done = start
	if "Boss" in Global.current_profile["current_run"]["current_day"]["node"]:
		Global.current_profile["current_run"]["current_day"]["node"] = world_datas["start"]
	player_datas["node"] = Global.current_profile["current_run"]["current_day"]["node"]
	player_datas["course"] = Global.current_profile["current_run"]["current_day"]["course"]
	player_datas["unlocks"] = Global.current_profile["current_run"]["unlocks"]

func update_world():
	# Avatar position and skin
	position_avatar_on_node(world_datas["Nodes"][player_datas["node"]]["node"])
	# Nodes
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
				#path_in.get_child(0).hide()
				path_in.modulate = Color(0.0, 0.0, 0.0, 1.0)
		# Seen this run
		elif node not in player_datas["run_finished_maps"]:
			for thing in ["done","valid"]:node_datas[thing].hide()
			node_datas["node"].modulate = Color(0.5, 0.5, 0.5, 1.0)
			if "Boss" not in node:node_datas["stars"].hide()
			if path_in is Line2D:
				#path_in.get_child(0).hide()
				path_in.modulate = Color(0.5, 0.5, 0.5, 1.0)
		# Finished this run
		elif node not in player_datas["course"]:
			node_datas["done"].hide()
			node_datas["node"].modulate = Color(0.5, 0.5, 0.5, 1.0)
			if "Boss" not in node:node_datas["stars"].stars_update(Global.current_profile["current_run"]["maps"][node]["objectives"])
			if path_in is Line2D:
				#path_in.get_child(0).hide()
				path_in.modulate = Color(0.5, 0.5, 0.5, 1.0)
		# Traveled
		else:
			node_datas["node"].modulate = Color(0.5, 0.5, 0.5, 1.0)
			if path_in is Line2D:
				var overpath : Line2D =  await draw_path(path_in,0,true)
				overpath.modulate = Color(0.5, 0.5, 0.5, 1.0)
				path_in.modulate = Color(0.5, 0.5, 0.5, 1.0)
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
					#path_in.get_child(0).hide()
					path_in.modulate = Color(0.5, 0.5, 0.5, 1.0)
				# Previous map finished on previous run
				elif path_in.name.split("_")[0] in player_datas["finished_maps"]:
					path_in.show()
					#path_in.get_child(0).hide()
					path_in.modulate = Color(0.0, 0.0, 0.0, 1.0)
				# Hide lock if path hiden
				else:path_in.get_parent().get_child(2).hide()

func check_unlocks():
	for node in unlocks:
		# Not unlocked already
		if node not in player_datas["unlocks"]:
			var unlocked : bool = true
			for condition_value in unlocks[node]:
				if condition_value == "map_finished" :
					unlocked = unlocked and\
						Global.current_profile["current_run"]["maps"].\
							get(unlocks[node]["map_finished"],{"finished":false})["finished"]
				elif condition_value == "stars" :
					unlocked = unlocked and\
						Global.current_profile["current_run"]["stars"] >= unlocks[node]["stars"]
			if unlocked:
				Global.current_profile["current_run"]["unlocks"].append(node)
				%WorldCam.position_cam(unlocks[node]["cam_position"])
				%AnimationPlayer.play("Desert_Unlock")

func draw_new_paths():
	world_datas["Nodes"][player_datas["node"]]["node"].modulate = Color(1.0, 1.0, 1.0, 1.0)
	# Out path of current node
	for zone in world_datas["Nodes"][player_datas["node"]]["zone_out"]:
		var destination : String = zone.name.split("_")[1] 
		# Origin or destination not chairlift
		if "Chairlift" not in zone.name:
			# Destination never seen
			if destination not in player_datas["finished_maps"] or destination not in player_datas["run_seen_maps"]:
				await draw_path(world_datas["Zones"][zone]["path"],path_drawing_time)
		# Map enlightment if hiden or black
		if not world_datas["Nodes"][destination]["node"].visible or\
			world_datas["Nodes"][destination]["node"].modulate == Color(0.0, 0.0, 0.0, 1.0):
				for child in world_datas["Nodes"][destination]["node"].get_children():child.hide()
				world_datas["Nodes"][destination]["node"].modulate = Color(0.5, 0.5, 0.5, 1.0)
				world_datas["Nodes"][destination]["node"].show()
		# Active zones
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
func on_zone_exit(zone:Area2D,path_light:bool=false):
		world_datas["Nodes"][zone.name.split("_")[1]]["node"].modulate = Color(0.5, 0.5, 0.5, 1.0)
		if not path_light:
			world_datas["Zones"][zone].modulate = Color(0.5, 0.5, 0.5, 1.0)
			if "Chairlift" not in zone.name.split("_")[0]:world_datas["Zones"][zone]["path"].modulate = Color(0.5, 0.5, 0.5, 1.0)
		world_datas["Zones"][zone]["outline"].hide()
func on_zone_click(zone:Area2D):
	if active_zones[zone] :
		AudioManager.play_ui("click")
		# Reset zone
		running = false
		hovered_zone = null
		active_zones = {}
		on_zone_exit(zone,true)
		var origin : String = zone.name.split("_")[0] 
		var destination : String = zone.name.split("_")[1]
		Global.current_profile["current_run"]["current_day"]["node"] = destination
		%WorldCam.position_cam(zone.name)
		if "Chairlift" in origin:
			AudioManager.play_sfx("chairlift")
			# Base Chairlift -> restart course
			if "To" not in origin:
				Global.current_profile["current_run"]["current_day"]["course"] = []
				# Overpath delete
				for tree_zone in world_datas["Zones"]:for node in tree_zone.get_children():
					if node.name == "overpath":node.queue_free()
				# Done hide
				for tree_node in world_datas["Nodes"]:for node in world_datas["Nodes"][tree_node]["node"].get_children():
					if node.name == "Done":node.hide()
			move_avatar_to_chairlift(world_datas["Nodes"][origin]["node"])
			await world_datas["Zones"][zone]["path"].play()
			# Chairlift to next world
			if "To" in origin:%Desert.show()
			else:position_avatar_on_node(world_datas["Nodes"][destination]["node"])
		else:
			%Avatar.hide()
			world_datas["Nodes"][origin]["node"].modulate = Color(0.5, 0.5, 0.5, 1.0) 
			await draw_path(world_datas["Zones"][zone]["path"],path_riding_time,true,true)
			position_avatar_on_node(world_datas["Nodes"][destination]["node"])
		world_datas["Nodes"][destination]["node"].disabled = false
		world_datas["Nodes"][destination]["node"].mouse_filter = Control.MOUSE_FILTER_STOP
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

func position_avatar_on_node(node:Control):
	%Avatar.texture = load(Global.get_sprites_path() + "Avatar.png")
	%Avatar.global_position = node.global_position + Vector2(40,25)
	%Avatar.scale = Vector2(0.1,0.1) * node.scale.x
	%Avatar.show()


func move_avatar_to_chairlift(node:Control):
	var frame_rate : float = 60 # FPS
	var frame_distance:float= (node.global_position - %Avatar.global_position).length() / (frame_rate * to_chairlift_time)
	var final_scale : Vector2 = to_chairlift_scale_factor * %Avatar.scale
	var frame_scaling:float= (%Avatar.scale - final_scale).length() / (frame_rate * to_chairlift_time)
	%Avatar.texture = load(Global.get_sprites_path() + "Avatar_back.png")
	while %Avatar.global_position != node.global_position:
		%Avatar.global_position = %Avatar.global_position.move_toward(node.global_position,frame_distance)
		%Avatar.scale = %Avatar.scale.move_toward(final_scale,frame_scaling)
		await get_tree().create_timer(1/frame_rate).timeout
	%Avatar.hide()

func draw_path(path:Line2D,duration:float,dashed: bool = false,bike: bool = false)->Line2D:
	var path_points : PackedVector2Array = path.points
	var copy_line := Line2D.new()
	var biker : Sprite2D
	var previous_point : Vector2
	var path_direction : Vector2
	if bike:
		biker = Sprite2D.new()
		biker.texture = load(Global.get_sprites_path()+"Avatar_bike.png")
		path.get_parent().add_child(biker)
	path.get_parent().add_child(copy_line)
	var drawing_frequency : float = duration/path_points.size()
	# Style copy
	if dashed :
		# Name overpath
		copy_line.name = "overpath"
		copy_line.texture = load("res://Images/Menus/Maps/DashLines/textured_dashed_line_backless.png")
	else:copy_line.texture = path.texture
	copy_line.texture_mode = path.texture_mode
	copy_line.texture_repeat = path.texture_repeat
	copy_line.position = path.position
	copy_line.z_index = path.z_index
	copy_line.z_as_relative = path.z_as_relative
	copy_line.width = path.width
	# Drawing
	if drawing_frequency == 0.0:copy_line.points = path.points
	else:
		var index : int = 0
		# First point for bike position
		if bike:previous_point = path_points[index]
		copy_line.add_point(path_points[index])
		index += 1
		await get_tree().create_timer(drawing_frequency).timeout
		while index < path_points.size():
			copy_line.add_point(path_points[index])
			if bike:
				path_direction = path_points[index] - previous_point
				previous_point = path_points[index]
				# Going right
				biker.scale = Vector2(0.1,0.1) if -PI/2<path_direction.angle() and path_direction.angle()<PI/2 else Vector2(-0.1,0.1)
				biker.rotation = clampf(path_direction.angle(),-PI/2,PI/4) if -PI/2<path_direction.angle() and\
					path_direction.angle()<PI/2 else clampf(path_direction.rotated(PI).angle(),-PI/4,PI/2)
				biker.position = path.position + previous_point + Vector2(0,-10)
			index += 1
			await get_tree().create_timer(drawing_frequency).timeout
		if bike:biker.queue_free()
	return copy_line

func set_up_button(node:BaseButton):
	node.mouse_entered.connect(func(): on_button_hover(node))
	node.mouse_exited.connect(func(): on_button_hover_exit(node))
	node.pressed.connect(func():on_button_pressed(node))
func on_button_hover(button:BaseButton):if not button.disabled:AudioManager.play_ui("hover")
func on_button_hover_exit(_button:BaseButton):get_viewport().gui_release_focus()
func on_button_pressed(_button:BaseButton):AudioManager.play_ui("click")

func play_sfx(sfx:String):AudioManager.play_sfx(sfx)

func start_map(map_name:String):
		Global.current_map = map_name
		Global.start_mod("Main_Game")
func _on_0_pressed():
	if Global.get_profile_data("state") == "tuto":Global.start_mod("Tuto_Game")
	else:start_map("Map 0")
func _on_1_pressed():start_map("Map 1")
func _on_2_pressed():start_map("Map 2")
func _on_forest_boss_pressed():
		Global.current_map = "Boss 1 Map"
		Global.current_boss = "Adriano"
		Global.start_mod("Boss_Game")


func _on_to_village_button_pressed():
	Global.current_profile["state"] = "Career"
	Global.start_mod("Career")
	SaveManager.save_profile(Global.current_profile)
