extends Control

var dico_dialogs : Dictionary

var talking_panel : PanelContainer
var talking_label : RichTextLabel
var full_text := ""
var char_index := 0
var next_act := false
var typing := false
@export var typing_speed := 0.03

func _ready():%ToHide.visible = false

func dico_update():
	dico_dialogs = {
		"tuto":{
			"Char1":"res://Avatar/Players/Biqueen/Avatar.png",
			"Char2":Global.get_sprites_path() + "Avatar.png",
			"acts":[
				"Char2_arrive",
				"dialog_char2_Wow, that's nice here !",
				"Char1_arrive",
				"dialog_char1_Hey, You !! It's your first time right ? I've never seen you around before.\n
				Would you like to learn more about the place ?",
			]
		}
	}

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if char_index < full_text.length():
			char_index = full_text.length()
			talking_label.visible_characters = char_index
		else:
			talking_panel.hide()
			next_act = true

func play_scene(scene:String)->void:
	dico_update()
	%ToHide.visible = true
	%Char1.texture = load(dico_dialogs[scene]["Char1"])
	%Char2.texture = load(dico_dialogs[scene]["Char2"])
	for anim in dico_dialogs[scene]["acts"]:
		if anim.split("_")[0]=="dialog":
			talking_panel = %Char1Pannel if anim.split("_")[1] == "char1" else %Char2Pannel
			talking_label = %Char1Text if anim.split("_")[1] == "char1" else %Char2Text
			next_act = false
			show_dialog(anim.split("_")[2])
			while not next_act: await get_tree().process_frame
			%NextButton.hide()
		else:
			%AnimationPlayer.play(anim)
			await %AnimationPlayer.animation_finished
		
func show_dialog(text: String):
	full_text = text
	char_index = 0
	talking_label.text = full_text
	talking_label.visible_characters = 0
	talking_panel.show()
	talk()
	
func talk():
	while char_index < full_text.length():
		char_index += 1
		talking_label.visible_characters = char_index
		await get_tree().create_timer(typing_speed).timeout
	%NextButton.show()

func _on_next_button_pressed():
	talking_panel.hide()
	next_act = true
