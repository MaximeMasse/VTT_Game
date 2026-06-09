extends Control

var choix_perso :int= 1

@onready var dico_menus := {
		"MainMenu":%MainMenu,
		"NewPlayer":%NewPlayer,
		"ChangeProfile":%ChangeProfile,
		"Carrière":%Carriere,
		"Chairlift":%ChairliftMenu
	}
@onready var dico_map_buttons := {
		"0" : [%Map0_Button,["1"]],
		"1" : [%Map1_Button,["2"]],
		"2" : [%Map2_Button,["3"]],
		"3" : [%Boss1_Button,[]],
	}

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
	show_menu(Global.menu_to_show)

func set_up_buttons(node):
	for child in node.get_children():
		if child is BaseButton:
			child.mouse_entered.connect(func(): on_button_hover(child))
			child.mouse_exited.connect(func(): on_button_hover_exit(child))
			child.focus_entered.connect(func(): on_button_focus(child))
			child.pressed.connect(func():on_button_pressed(child))
		set_up_buttons(child)

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_down"):%ContinueButton.grab_focus()
	elif Input.is_action_just_pressed("ui_up"):%ProfileButton.grab_focus()

func show_menu(menu:String):
	for men in dico_menus:dico_menus[men].hide()
	if menu == "Chairlift":map_progress_update()
	dico_menus[menu].show()
	
func map_progress_update():
	for map in dico_map_buttons: 
		dico_map_buttons[map][0].hide()
		for child in dico_map_buttons[map][0].get_children():child.hide()
	if Global.get_profile_data("state") == "tuto":%DialogChairlift.play_scene("tuto")
	else:
		var node_to_check :Array = ["0"]
		var tree_done := false
		while not tree_done:
			if node_to_check.size() > 0 :
				var current_map : String = node_to_check.pop_front()
				dico_map_buttons[current_map][0].show()
				if current_map in Global.current_profile["current_run"]["finished_maps"].keys():
					var stars : Array = Global.current_profile["current_run"]["finished_maps"][current_map]["objectives"]
					dico_map_buttons[current_map][0].get_child(0).show()
					dico_map_buttons[current_map][0].get_child(1).stars_update(stars)
					dico_map_buttons[current_map][0].get_child(1).show()
					node_to_check.append_array(dico_map_buttons[current_map][1])
			else:tree_done=true


func apply_audio_config():
	AudioManager.set_bus_volume("Music", Global.config.get("music_volume", 0.8))
	AudioManager.set_bus_volume("SFX", Global.config.get("sfx_volume", 0.8))
	AudioManager.set_bus_volume("GROUND_SFX", Global.config.get("sfx_volume", 0.8))
	AudioManager.set_bus_volume("UI", Global.config.get("ui_volume", 0.8))

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
	elif scene_name == "tuto_start":%Chairlift.disabled = false
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
		for button in %Maps.get_children():button.hide()
		%DialogChairlift.play_scene("tuto")

func _on_dialog_chairlift_scene_ended(_scene_name):%Map0_Button.show()

func _on_map_0_button_pressed():
	if Global.get_profile_data("state") == "tuto":Global.start_mod("Tuto_Game")
	else:
		Global.current_map = "0"
		Global.start_mod("Main_Game")

func on_button_hover(button:BaseButton):if not button.disabled:button.grab_focus()
func on_button_hover_exit(_button:BaseButton):get_viewport().gui_release_focus()
func on_button_focus(_button:BaseButton):AudioManager.play_ui("hover")
func on_button_pressed(_button:BaseButton):AudioManager.play_ui("click")
