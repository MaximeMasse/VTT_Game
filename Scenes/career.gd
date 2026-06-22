extends Node2D

func _ready():
	%Tuto.hide()
	set_up_buttons(self)
	if Global.get_profile_data("state") == "tuto":
		%StartTutoPanel.hide()
		%Tuto.show()
		for button in %Spots.get_children():button.disabled = true
		%DialogTuto.play_scene("tuto")

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


func _on_world_pressed():
	Global.current_profile["state"] = "Chairlift"
	Global.start_mod("Forest")
	SaveManager.save_profile(Global.current_profile)

func _on_dialog_tuto_scene_ended(scene_name):
	if scene_name == "tuto":
		%StartTutoPanel.show()
	elif scene_name == "tuto_start":%World.disabled = false
	elif scene_name == "tuto_skip":
		%Tuto.hide()
		Global.current_profile["state"] = "Career"
		for button in %Spots.get_children():button.disabled = false

func _on_tuto_yes_button_pressed():
	%StartTutoPanel.hide()
	%DialogTuto.play_scene("tuto_start")

func _on_tuto_no_button_pressed():
	%TutoPanels.hide()
	%DialogTuto.play_scene("tuto_skip")

func _on_dialog_chairlift_scene_ended(_scene_name):%Map_0_Button.show()
