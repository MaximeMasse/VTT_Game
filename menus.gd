extends Control

var choix_perso := 1

var dico_menus := {}

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
	#Menuing
	dico_menus = {
		"MainMenu":%MainMenu,
		"NewPlayer":%NewPlayer,
		"ChangeProfile":%ChangeProfile,
		"Carrière":%Carriere,
		"Upgrades":%Upgrades,
		"ChoixMap":%ChoixMap
	}
	show_menu(dico_menus[Global.menu_to_show])

func set_up_buttons(node):
	for child in node.get_children():
		if child is BaseButton:
			child.mouse_entered.connect(func(): on_button_hover(child))
			child.mouse_exited.connect(func(): on_button_hover_exit(child))
			child.focus_entered.connect(func(): on_button_focus(child))
			child.pressed.connect(func():on_button_pressed(child))
		set_up_buttons(child)

func _unhandled_input(event):
	if Input.is_action_just_pressed("ui_down"):
		%ContinueButton.grab_focus()
	elif Input.is_action_just_pressed("ui_up"):
		%ProfileButton.grab_focus()

func show_menu(menu):
	for men in dico_menus:
		dico_menus[men].hide()
	menu.show()

func apply_audio_config():
	AudioManager.set_bus_volume("Music", Global.config.get("music_volume", 0.8))
	AudioManager.set_bus_volume("SFX", Global.config.get("sfx_volume", 0.8))
	AudioManager.set_bus_volume("GROUND_SFX", Global.config.get("sfx_volume", 0.8))
	AudioManager.set_bus_volume("UI", Global.config.get("ui_volume", 0.8))

func _on_continue_button_pressed():
	AudioManager.play_ui("click")
	AudioManager.stop_music()
	Global.start_mod("Main_Game")

func _on_new_player_button_pressed():
	AudioManager.play_ui("click")
	show_menu(%NewPlayer)
	%Choix.texture = Global.dico_avatars[choix_perso]
	
func _on_bouton_gauche_pressed():
	AudioManager.play_ui("click")
	if choix_perso > 1:
		choix_perso -= 1
	%Choix.texture = Global.dico_avatars[choix_perso]

func _on_bouton_droite_pressed():
	AudioManager.play_ui("click")
	if choix_perso < Global.dico_avatars.size():
		choix_perso += 1
	%Choix.texture = Global.dico_avatars[choix_perso]

func _on_ok_pressed():
	AudioManager.play_ui("click")
	var pseudo = %NameLineEdit.text
	var avatar_id = choix_perso
	var profile = SaveManager.create_profile(pseudo, avatar_id)
	show_menu(%Carriere)

func on_button_hover(button:BaseButton):button.grab_focus()
func on_button_hover_exit(button:BaseButton):get_viewport().gui_release_focus()
func on_button_focus(button:BaseButton):AudioManager.play_ui("hover")
func on_button_pressed(button:BaseButton):AudioManager.play_ui("click")

func _on_bouton_choix_map_pressed():
	AudioManager.play_ui("click")
	show_menu(%ChoixMap)
	
