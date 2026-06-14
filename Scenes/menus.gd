extends Control

# Activation
var running : bool

# Character
var choix_perso :int= 1

# Mouse collision
var active_zones : Array
var hovered_zone: Area2D = null

# Player position
var current_world : Node2D
var current_node : Control

@onready var dico_menus := {
		"MainMenu":%MainMenu,
		"NewPlayer":%NewPlayer,
		"ChangeProfile":%ChangeProfile,
		"Carrière":%Carriere,
		"Chairlift":%ChairliftMenu,
	}
@onready var dico_zone_links := {
		"_ForestChairlift" : {"activation_node":%_ForestChairlift,"destination_node":%Map_0_Button},
		"0_1" : {"activation_node":%Map_0_Button,"destination_node":%Map_1_Button},
		"1_2" : {"activation_node":%Map_1_Button,"destination_node":%Map_2_Button},
		"2_ForestBoss" : {"activation_node":%Map_2_Button,"destination_node":%Map_ForestBoss_Button},
		"1_ChairliftToDesert" : {"activation_node":%Map_1_Button,"destination_node":%_ChairliftToDesert},
		"_ChairliftToDesert" : {"activation_node":%_ChairliftToDesert,"destination_node":%ToDesert},
	}
@onready var dico_worlds_names := {
		"Forest":%ForestMap,
		"Desert":%DesertMap,
		"Icy":%IcyMap,
		"Tropical":%TropicalMap
	}
var dico_nodes_names : Dictionary
var worlds_tree : Dictionary


func _ready():
	#print(ProjectSettings.globalize_path("user://"))
	#Config
	get_tree().debug_collisions_hint = false
	SaveManager.load_config()
	apply_audio_config()
	AudioManager.play_music("MainMenu")
	var last_id:int = Global.config.get("profil_en_cours")
	if last_id != 0:
		var profile = SaveManager.load_profile(last_id)
		if not profile.is_empty():
			SaveManager.set_current_profile(profile)
			%ContinueButton.show()
		else:
			%ContinueButton.hide()
	else:
		%ContinueButton.hide()
	#Mouse
	var cursor = load("res://Images/Menus/Controls/cursor.png")
	Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, Vector2(0, 0))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Buttons
	set_up_buttons(self)
	# World referencing
	for world_name in dico_worlds_names:
		# Node2D World
		var world : Node2D = dico_worlds_names[world_name]
		# World init
		worlds_tree[world] = {"Nodes":{},"Paths":{},"Zones":{}}
		# Nodes, paths and zones init
		for node in world.get_children():if node.name != "Background":
			for child in node.get_children():
				worlds_tree[world][node.name][child]={}
	# Activation
	running = false
	# Menu
	show_menu(Global.menu_to_show)

func set_up_buttons(node):
	for child in node.get_children():
		if child is BaseButton:
			child.mouse_entered.connect(func(): on_button_hover(child))
			child.mouse_exited.connect(func(): on_button_hover_exit(child))
			child.focus_entered.connect(func(): on_button_focus(child))
			child.pressed.connect(func():on_button_pressed(child))
		set_up_buttons(child)

func show_menu(menu:String):
	for men in dico_menus:dico_menus[men].hide()
	if menu == "Chairlift":Global.start_mod("Forest_Map")
	dico_menus[menu].show()
	
func map_progress_update():
	current_world = dico_worlds_names[World.current("current_world")]
	for world in dico_worlds_names:dico_worlds_names[world].hide()
	current_world.show()
	# Nodes
	for node in worlds_tree[current_world]["Nodes"]:node_init(node)
	# Paths
	for path in worlds_tree[current_world]["Paths"]:path_init(path)
	# Zones
	for zone in worlds_tree[current_world]["Zones"]:
		create_linked_zone(zone)
		zone_path_ref(zone)
	# Positioning 
	current_node = dico_nodes_names[World.current("current_node")]
	# Debug print
	print("Nodes :")
	for node in worlds_tree[current_world]["Nodes"]:print(node,worlds_tree[current_world]["Nodes"][node])
	print("Paths :")
	for node in worlds_tree[current_world]["Paths"]:print(node,worlds_tree[current_world]["Paths"][node])
	print("Zones :")
	for node in worlds_tree[current_world]["Zones"]:print(node,worlds_tree[current_world]["Zones"][node])
	print("Dico node names : ",dico_nodes_names)
	print("Current_day : ",Global.current_day)
	print("World data : ",World.current_world_datas)
	# Positioning style
	apply_world_style()
	# Activation
	active_zones = worlds_tree[current_world]["Nodes"][current_node]["active_zones"]
	
	running = true

func node_init(node:Control):
	# Ref
	dico_nodes_names[node.name] = node
	worlds_tree[current_world]["Nodes"][node]["active_zones"] = []

func path_init(path:Line2D):
	# Ref
	var from : String = path.name.split("_")[0]
	var to : String = path.name.split("_")[1]
	worlds_tree[current_world]["Paths"][path]["from"] = from
	worlds_tree[current_world]["Paths"][path]["to"] = to
	for node in worlds_tree[current_world]["Nodes"]:
		if "_" in node.name and node.name.split("_")[1] == to:worlds_tree[current_world]["Nodes"][node]["paths"] = path

func zone_path_ref(zone:Area2D):
	worlds_tree[current_world]["Nodes"][dico_zone_links[zone.name]["activation_node"]]["active_zones"].append(zone)
	worlds_tree[current_world]["Zones"][zone]["destination_node"] = dico_zone_links[zone.name]["destination_node"]
	for path in worlds_tree[current_world]["Paths"]: if path.name == zone.name :
		worlds_tree[current_world]["Zones"][zone]["path"] = path

func create_linked_zone(zone:Area2D):
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
	# Reference
	worlds_tree[current_world]["Zones"][zone]["outline"] = outline

func apply_world_style():
	var reachable_nodes : Array = []
	for zone in worlds_tree[current_world]["Nodes"][current_node]["active_zones"]:
		reachable_nodes.append(worlds_tree[current_world]["Zones"][zone]["destination_node"])
	print("reachable nodes : ",reachable_nodes)
	
	# Nodes
	#for node in worlds_tree[current_world]["Nodes"]:
		## Regular map buttons
		#if "Map" in node.name:
			#var map_name :String= node.name.split("_")[1]
			#var is_valided : bool = false
			#var style : Dictionary = {
			#"disabled":true,"modulate":Color(0.0, 0.0, 0.0, 1.0),
			#"visible":false,"mouse_filter":Control.MOUSE_FILTER_IGNORE
			#}
			## Already traveled today
			#if node.name in World.current("day_travel"):
				#style["modulate"] = Color(0.208, 0.91, 0.235, 1.0)
				#style["visible"] = true
				#is_valided = true
			## Already done this run
			#elif map_name in World.current("run_finished_maps"):
				#style["modulate"] = Color(0.5, 0.5, 0.5, 1.0)
				#style["visible"] = true
				#is_valided = true
				## Stars
				#node.get_child(1).stars_update(
					#Global.current_profile["current_run"]["finished_maps"][map_name].get("objectives",[]))
			## Reachable
			#elif node in reachable_nodes :
				#style["modulate"] = Color(0.5, 0.5, 0.5, 1.0)
				#style["visible"] = true
			## Already seen on previous run
			#elif map_name in World.current("finished_maps"):style["visible"] = true
			## Apply style
			#node.disabled = style["disabled"]
			#node.modulate = style["modulate"]
			#node.visible = style["visible"]
			#node.mouse_filter = style["mouse_filter"]
			#node.get_child(0).visible = is_valided
			## Paths
			#if "paths" in worlds_tree[current_world]["Nodes"][node].keys():
				#worlds_tree[current_world]["Nodes"][node]["paths"].modulate = style["modulate"]
				#worlds_tree[current_world]["Nodes"][node]["paths"].visible = style["visible"]
		## Chairlifts
		#elif "Chairlift" in node.name:
			#node.visible = true
			## Unlockable Chairlift
			#if "paths" in worlds_tree[current_world]["Nodes"][node].keys():
				#var path : Line2D = worlds_tree[current_world]["Nodes"][node]["paths"]
				#var path_origin : String = worlds_tree[current_world]["Paths"][path]["from"]
				#var path_style : Dictionary = {"modulate":Color(0.0, 0.0, 0.0, 1.0),"visible":false}
				## If unlocked
				#if node.name in World.current("worlds_unlocks"):
					#node.unlock()
					## Already traveled today
					#if path.name in World.current("day_travel"):
						#path_style["modulate"] = Color(0.208, 0.91, 0.235, 1.0)
						#path_style["visible"] = true
					## Already done this run
					#elif path_origin in World.current("run_finished_maps"):
						#path_style["modulate"] = Color(0.5, 0.5, 0.5, 1.0)
						#path_style["visible"] = true
					## Already seen on previous run
					#elif path_origin in World.current("finished_maps"):path_style["visible"] = true
				## If locked
				#else:pass
				## Apply style
				#path.modulate = path_style["modulate"]
				#path.visible = path_style["visible"]
			## BaseChairlift
			#else : node.unlock()

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

func on_zone_hover(zone:Area2D):
	AudioManager.play_ui("map_hover")
	worlds_tree[current_world]["Zones"][zone]["outline"].show()
	worlds_tree[current_world]["Zones"][zone]["destination_node"].modulate = Color(1,1,1,1)
func on_zone_exit(zone:Area2D):
	worlds_tree[current_world]["Zones"][zone]["outline"].hide()
	worlds_tree[current_world]["Zones"][zone]["destination_node"].modulate = Color(0.5,0.5,0.5,1)
func click_zone(zone:Area2D):
	# Reset zone
	active_zones = []
	# From
	if "Chairlift" in zone.name:
		AudioManager.play_sfx("chairlift")
		dico_nodes_names[zone.name].play()
		await get_tree().create_timer(3).timeout
	# To
	current_node = worlds_tree[current_world]["Zones"][zone]["destination_node"]
	if "Map" in current_node.name:
			current_node.disabled = false
			current_node.modulate = Color(1.0, 1.0, 1.0, 1.0)
			current_node.mouse_filter = Control.MOUSE_FILTER_PASS
			World.change("node_done",false)

func _process(_delta):
	if not running : return
	var mouse_pos := get_global_mouse_position()
	var new_hovered_zone: Area2D = null
	for zone in active_zones:
		var collision : CollisionPolygon2D = zone.get_child(0)
		var local_mouse := collision.to_local(mouse_pos)
		if Geometry2D.is_point_in_polygon(local_mouse, collision.polygon):
			new_hovered_zone = zone
			break
	if new_hovered_zone != hovered_zone:
		if hovered_zone != null:on_zone_exit(hovered_zone)
		hovered_zone = new_hovered_zone
		if hovered_zone != null:on_zone_hover(hovered_zone)

func on_button_hover(button:BaseButton):if not button.disabled:button.grab_focus()
func on_button_hover_exit(_button:BaseButton):get_viewport().gui_release_focus()
func on_button_focus(_button:BaseButton):AudioManager.play_ui("hover")
func on_button_pressed(_button:BaseButton):AudioManager.play_ui("click")

func apply_audio_config():
	AudioManager.set_bus_volume("Music", Global.config.get("music_volume", 0.8))
	AudioManager.set_bus_volume("SFX", Global.config.get("sfx_volume", 0.8))
	AudioManager.set_bus_volume("GROUND_SFX", Global.config.get("sfx_volume", 0.8))
	AudioManager.set_bus_volume("UI", Global.config.get("ui_volume", 0.8))

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_down"):%ContinueButton.grab_focus()
	elif Input.is_action_just_pressed("ui_up"):%ProfileButton.grab_focus()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:if hovered_zone != null:click_zone(hovered_zone)

func _on_continue_button_pressed():
	AudioManager.stop_music()
	Global.new_day()
	World.set_world_values()
	show_menu("Chairlift")
	#Global.start_mod("Tuto_Game")

func _on_new_player_button_pressed():
	show_menu("NewPlayer")
	%Choix.texture = load("res://Avatar/Players/" + Global.dico_avatars[choix_perso] + "/Avatar.png")
	
func _on_bouton_gauche_pressed():
	if choix_perso > 1:choix_perso -= 1
	%Choix.texture = load("res://Avatar/Players/" + Global.dico_avatars[choix_perso] + "/Avatar.png")

func _on_bouton_droite_pressed():
	if choix_perso < Global.dico_avatars.size():choix_perso += 1
	%Choix.texture = load("res://Avatar/Players/" + Global.dico_avatars[choix_perso] + "/Avatar.png")

func _on_ok_pressed():
	var pseudo = %NameLineEdit.text
	var avatar_id = choix_perso
	SaveManager.create_profile(pseudo, avatar_id)
	if choix_perso in [3,4]:Global.current_profile["bike_model"] = 2
	SaveManager.save_profile(Global.current_profile)
	show_menu("Carrière")
	if Global.get_profile_data("state") == "tuto":
		%StartTutoPanel.hide()
		%Tuto.show()
		for button in %Spots.get_children():button.disabled = true
		%DialogTuto.play_scene("tuto")

func _on_dialog_tuto_scene_ended(scene_name):
	if scene_name == "tuto":
		%StartTutoPanel.show()
	elif scene_name == "tuto_start":%World.disabled = false
	elif scene_name == "tuto_skip":
		%Tuto.hide()
		Global.current_profile["state"] = "other"
		for button in %Spots.get_children():button.disabled = false

func _on_tuto_yes_button_pressed():
	%StartTutoPanel.hide()
	%DialogTuto.play_scene("tuto_start")

func _on_tuto_no_button_pressed():
	%TutoPanels.hide()
	%DialogTuto.play_scene("tuto_skip")

func _on_chairlift_pressed() -> void:
	AudioManager.stop_music()
	show_menu("Chairlift")
	if Global.get_profile_data("state") == "tuto":
		for button in %Nodes.get_children():button.hide()
		%DialogChairlift.play_scene("tuto")

func _on_dialog_chairlift_scene_ended(_scene_name):%Map_0_Button.show()

func _on_map_0_button_pressed():
	if Global.get_profile_data("state") == "tuto":Global.start_mod("Tuto_Game")
	else:
		Global.current_map = "0"
		Global.start_mod("Main_Game")
