extends Control

# Character
var choix_perso :int= 1

@onready var dico_menus := {
		"MainMenu":%MainMenu,
		"NewPlayer":%NewPlayer,
		"ChangeProfile":%ChangeProfile,
	}

func _ready():
	#print(ProjectSettings.globalize_path("user://"))
	#Config
	get_tree().debug_collisions_hint = false
	SaveManager.load_config()
	apply_audio_config()
	AudioManager.play_music("MainMenu")
	# Profile
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
	# Menu
	show_menu()

func set_up_buttons(node):
	for child in node.get_children():
		if child is BaseButton:
			child.mouse_entered.connect(func(): on_button_hover(child))
			child.mouse_exited.connect(func(): on_button_hover_exit(child))
			child.focus_entered.connect(func(): on_button_focus(child))
			child.pressed.connect(func():on_button_pressed(child))
		set_up_buttons(child)

func show_menu():
	if Global.menu_to_show == "Chairlift":
		Global.start_mod(Global.current_profile["current_run"]["current_day"]["world"])
	elif Global.menu_to_show in ["Career","tuto"]:Global.start_mod("Career")
	else:
		for men in dico_menus:dico_menus[men].hide()
		dico_menus[Global.menu_to_show].show()

func on_button_hover(button:BaseButton):if not button.disabled:button.grab_focus()
func on_button_hover_exit(_button:BaseButton):get_viewport().gui_release_focus()
func on_button_focus(_button:BaseButton):AudioManager.play_ui("hover")
func on_button_pressed(_button:BaseButton):AudioManager.play_ui("click")

func apply_audio_config():
	AudioManager.set_bus_volume("Music", Global.config.get("music_volume", 0.8))
	AudioManager.set_bus_volume("SFX", Global.config.get("sfx_volume", 0.8))
	AudioManager.set_bus_volume("GROUND_SFX", Global.config.get("sfx_volume", 0.8))
	AudioManager.set_bus_volume("UI", Global.config.get("ui_volume", 0.8))

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_down"):%ContinueButton.grab_focus()
	elif Input.is_action_just_pressed("ui_up"):%ProfileButton.grab_focus()

func _on_continue_button_pressed():
	Global.menu_to_show = Global.current_profile["state"]
	AudioManager.stop_music()
	Global.set_run()
	Global.set_day()
	show_menu()

func _on_new_player_button_pressed():
	Global.menu_to_show = "NewPlayer"
	show_menu()
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
	Global.current_profile["bike_model"] = 2 if choix_perso in [3,4] else 1
	Global.menu_to_show = "Career"
	Global.set_run()
	Global.set_day()
	SaveManager.save_profile(Global.current_profile)
	show_menu()

func _on_chairlift_pressed() -> void:
	AudioManager.stop_music()
	Global.menu_to_show = "Chairlift"
	show_menu()

func _on_map_0_button_pressed():
	if Global.get_profile_data("state") == "tuto":Global.start_mod("Tuto_Game")
	else:
		Global.current_map = "0"
		Global.start_mod("Main_Game")
