extends Control

var dico_dialogs : Dictionary

var current_scene : String
var talking_panel : PanelContainer = null
var talking_label : RichTextLabel
var full_text := ""
var char_index := 0
var next_act := false
var is_typing := false
@export var typing_speed := 0.01

func _ready():%ToHide.visible = false

func dico_update():
	dico_dialogs = {
		"tuto":{
			"Char1":"res://Avatar/Players/Biqueen/Avatar.png",
			"Char2":Global.get_sprites_path() + "Avatar.png",
			"acts":[
				"anim_Char2_arrive",
				"dialog_char2_Wow, that's nice here !",
				"anim_Char1_arrive",
				"final_char1_Hey, You !! It's your first time right ? I've never seen you around before.\n\n" +
				"Would you like to learn more about the place ?",
			],
		},
		"tuto_start":{
			"Char1":"res://Avatar/Players/Biqueen/Avatar.png",
			"Char2":Global.get_sprites_path() + "Avatar.png",
			"acts":[
				"dialog_char2_Sure, tell me everything.",
				"dialog_char1_Ok, let me show you how things work.\n\n" +
				"First, meet me by the chairlift when you're ready.",
				"anim_Char1_to_lift",
				"dialog_char2_Well.....       \n\n" +
				"Ok, I guess",
				"anim-final_Char2_fade"
			]
		},
		"tuto_skip":{
			"Char1":"res://Avatar/Players/Biqueen/Avatar.png",
			"Char2":Global.get_sprites_path() + "Avatar.png",
			"acts":[
				"dialog_char2_Nahh, I'm fine.",
				"dialog_char1_My bad Mr. Know-it-all ! I'll stop bothering you.",
				"anim_Char1_leave",
				"dialog_char2_Yes, do that, thank you !",
				"anim-final_Char2_fade"
			]
		}
	}

signal scene_ended(scene_name:String)

func _input(event):
	if is_typing \
	and event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		if char_index < full_text.length():
			char_index = full_text.length()
			talking_label.visible_characters = char_index

func play_scene(scene:String)->void:
	current_scene = scene
	dico_update()
	%ToHide.visible = true
	%Char1.texture = load(dico_dialogs[scene]["Char1"])
	%Char2.texture = load(dico_dialogs[scene]["Char2"])
	for anim in dico_dialogs[scene]["acts"]:
		if anim.split("_")[0] in ["dialog","final"]:
			if talking_panel != null:talking_panel.hide()
			talking_panel = %Char1Pannel if anim.split("_")[1] == "char1" else %Char2Pannel
			talking_label = %Char1Text if anim.split("_")[1] == "char1" else %Char2Text
			next_act = false
			show_dialog(anim.split("_")[2],anim.split("_")[0])
			while not next_act: await get_tree().process_frame
			%NextButton.hide()
		else:
			if talking_panel != null:talking_panel.hide()
			%AnimationPlayer.play(anim.split("_",true,1)[1])
			await %AnimationPlayer.animation_finished
			if anim.split("_",true,1)[0] == "anim-final":scene_ended.emit(current_scene)
			
		
func show_dialog(text: String,final: String):
	is_typing = true
	full_text = text
	char_index = 0
	talking_label.text = full_text
	talking_label.visible_characters = 0
	talking_panel.show()
	talk(final)
	
func talk(final :String):
	while char_index < full_text.length():
		char_index += 1
		talking_label.visible_characters = char_index
		await get_tree().create_timer(typing_speed).timeout
	is_typing = false
	if not final == "final":%NextButton.show()
	else: scene_ended.emit(current_scene)

func _on_next_button_pressed():
	next_act = true
