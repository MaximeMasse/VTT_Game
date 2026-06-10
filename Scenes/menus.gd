extends Control

var choix_perso :int= 1

@onready var dico_menus := {
		"MainMenu":%MainMenu,
		"NewPlayer":%NewPlayer,
		"ChangeProfile":%ChangeProfile,
		"Carrière":%Carriere,
		"Chairlift":%ChairliftMenu
	}
@onready var dico_links := {
		"BaseChairlift" : %Map0_Button
	}
@onready var worlds := [%ForestMap]
var worlds_tree : Dictionary

func _ready():
	#print(ProjectSettings.globalize_path("user://"))
	#Config
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
	for world in worlds:worlds_tree[world] = {"nodes":{},"paths":{},"zones":{}}
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
	if menu == "Chairlift":map_progress_update()
	dico_menus[menu].show()
	
func map_progress_update():
	for world in worlds :
		for child in world.get_children():
			if child.name == "Nodes":
				for node in child.get_children():node_activation(node)
			elif child.name == "Paths":pass
			elif child.name == "Zones":
				for zone in child.get_children():
					create_linked_zone(zone)
	print("Worlds tree : ",worlds_tree)

func node_activation(node:Control):
	if node.name == "BaseChairlift":node.play()

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
	worlds_tree[zone.get_parent().get_parent()]["zones"][zone] = {}
	worlds_tree[zone.get_parent().get_parent()]["zones"][zone]["outline"] = outline 
	worlds_tree[zone.get_parent().get_parent()]["zones"][zone]["destination"] = dico_links[zone.name] 
	# Link
	zone.mouse_entered.connect(func():on_zone_hover(zone))
	zone.mouse_exited.connect(func():on_zone_exit(zone))

func on_zone_hover(zone:Area2D):
	AudioManager.play_ui("hover")
	worlds_tree[zone.get_parent().get_parent()]["zones"][zone]["outline"].show()
	worlds_tree[zone.get_parent().get_parent()]["zones"][zone]["destination"].modulate = Color(1,1,1,1)

func on_zone_exit(zone:Area2D):
	worlds_tree[zone.get_parent().get_parent()]["zones"][zone]["outline"].hide()
	worlds_tree[zone.get_parent().get_parent()]["zones"][zone]["destination"].modulate = Color(0.5,0.5,0.5,1)

func on_button_hover(button:BaseButton):if not button.disabled:button.grab_focus()
func on_button_hover_exit(_button:BaseButton):get_viewport().gui_release_focus()
func on_button_focus(_button:BaseButton):AudioManager.play_ui("hover")
func on_button_pressed(_button:BaseButton):AudioManager.play_ui("click")

func apply_audio_config():
	AudioManager.set_bus_volume("Music", Global.config.get("music_volume", 0.8))
	AudioManager.set_bus_volume("SFX", Global.config.get("sfx_volume", 0.8))
	AudioManager.set_bus_volume("GROUND_SFX", Global.config.get("sfx_volume", 0.8))
	AudioManager.set_bus_volume("UI", Global.config.get("ui_volume", 0.8))

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_down"):%ContinueButton.grab_focus()
	elif Input.is_action_just_pressed("ui_up"):%ProfileButton.grab_focus()

func _on_continue_button_pressed():
	AudioManager.stop_music()
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

func _on_dialog_chairlift_scene_ended(_scene_name):%Map0_Button.show()

func _on_map_0_button_pressed():
	if Global.get_profile_data("state") == "tuto":Global.start_mod("Tuto_Game")
	else:
		Global.current_map = "0"
		Global.start_mod("Main_Game")
