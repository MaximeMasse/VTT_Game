extends CanvasLayer

var colors := {
	"RED":Color(1,0.04,0.04,1),
	"YELLOW":Color(0.85,0.86,0,1),
	"DARK_GREY":Color(0.2,0.2,0.23,1),
	"LIGHT_GREEN":Color(0.2,0.9,0.23,1),
	"ORANGE":Color(0.76,0.37,0,1)
}

var best_trick_labels:Dictionary

var dico_saut :={
	Vector2(0,10):["Red",load("res://Images/HUD/piston_0.png")],
	Vector2(10,20):["res://Images/HUD/jump_orange.png",load("res://Images/HUD/piston_10.png")],
	Vector2(20,30):["res://Images/HUD/jump_orange.png",load("res://Images/HUD/piston_20.png")],
	Vector2(30,40):["res://Images/HUD/jump_orange.png",load("res://Images/HUD/piston_30.png")],
	Vector2(40,50):["res://Images/HUD/jump_orange.png",load("res://Images/HUD/piston_40.png")],
	Vector2(50,60):["res://Images/HUD/jump_yellow.png",load("res://Images/HUD/piston_50.png")],
	Vector2(60,70):["res://Images/HUD/jump_yellow.png",load("res://Images/HUD/piston_60.png")],
	Vector2(70,80):["res://Images/HUD/jump_yellow.png",load("res://Images/HUD/piston_70.png")],
	Vector2(80,90):["res://Images/HUD/jump_yellow.png",load("res://Images/HUD/piston_80.png")],
	Vector2(90,100):["res://Images/HUD/jump_green.png",load("res://Images/HUD/piston_90.png")]
}

var is_tricking :bool

func _ready():
	reset()
	best_trick_labels={"Air":%Air_label,"Wheelie":%Wheelie_label,"Nose Wheelie":%Nose_label}
	for trick in ["Wheelie","Nose Wheelie","Air"]:update_best_tricks(trick,false)

func reset():
	%Penalty_label.text = "+ " + str(int(Global.current_profile["upgrades"]["RESPAWN_PENALTY"])) + " sec"
	%Penalty_label.hide()
	%Piston.hide()
	%Tricks_label.hide()
	is_tricking = false
	%Combo_label.text = ""
	%Trick_score_label.hide()
	%Score_label.text = "Score : " + str(int(Global.current_score)) + " Points"
	
func update_score(points):
	%Trick_score_label.text = "+ " + str(int(points)) + " Points" 
	%Trick_score_label.show()
	%Score_label.add_theme_color_override("font_color", colors["ORANGE"])
	%Score_label.text = "Score : " + str(int(Global.current_score)) + " Points"
	fade_out_label(%Trick_score_label,1)
	await get_tree().create_timer(1).timeout
	%Score_label.add_theme_color_override("font_color", colors["YELLOW"])

func update_best_tricks(trick_name,effect=true):
	best_trick_labels[trick_name].text = str(round_to(Global.current_profile["best_tricks"][trick_name]["length"],1)) + " m | "\
		+ str(round_to(Global.current_profile["best_tricks"][trick_name]["duration"],1)) + " sec"
	if effect :
		best_trick_labels[trick_name].add_theme_color_override("font_color", colors["LIGHT_GREEN"])
		await get_tree().create_timer(1).timeout
		best_trick_labels[trick_name].add_theme_color_override("font_color", colors["DARK_GREY"])

func _physics_process(delta):
	%Time_label.text = format_time(Global.race_time)
	if Global.penalty_to_show and %Show_penalty_timer.is_stopped():
		%Tricks_label.add_theme_color_override("font_color", colors["RED"])
		%Penalty_label.show()
		Global.penalty_to_show = false
		%Show_penalty_timer.start()
	%Vitesse_label.text = "Speed : " + str(int(Global.vitesse.length())) + " km/h"
	%Avancement_bar.value = Global.avancement
	%ContactRed.visible = !Global.contact_sol
	if Global.taux_compression > 0.0:
		%Piston.show()
		for seuils in dico_saut:
			if Global.taux_compression >= seuils.x and Global.taux_compression < seuils.y:
				%Piston.texture = dico_saut[seuils][1]
				if dico_saut[seuils][0] == "Red": %JumpSignal.hide()
				else:
					%JumpSignal.show()
					%JumpSignal.texture = load(dico_saut[seuils][0])
	else : %Piston.hide()
	if is_tricking:
		%Tricks_label.text = Global.current_trick["trick"] + "\n"\
	 		+ str(round_to(Global.current_trick["length"],1)) + " m | "\
	 		+ str(round_to(Global.current_trick["duration"],1)) + " sec"
		%Trick_score_label.text = str(int(Global.potential_combo_score+Global.potential_trick_score)) + " Points"

func trick_reset():
	is_tricking = false
	#fade_out_label(%Tricks_label,0.5)
	#%Trick_score_label.hide()
	%Tricks_label.hide()
	%Combo_label.text = ""
	
func trick_activate():
	is_tricking = true
	%Tricks_label.show()
	%Trick_score_label.show()

func update_combo(text):
	%Combo_label.text += text + " + "

func format_time(t: float) -> String:
	var minutes := int(t) / 60
	var seconds := int(t) % 60
	var ms := int((t - int(t)) * 1000)
	return "%02d:%02d.%03d" % [minutes, seconds, ms]

func round_to(value: float, decimals: int) -> float:
	var factor = pow(10, decimals)
	return round(value * factor) / factor

func fade_out_label(label: Label,effect_duration: float):
	var initial_scale = label.scale
	var initial_position = label.position
	var initial_transparency = label.modulate.a
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, effect_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "scale", Vector2(1.5, 1.5), effect_duration)
	tween.parallel().tween_property(label, "position:y", label.position.y - 50, effect_duration)
	await tween.finished
	label.hide()
	label.scale = initial_scale
	label.position = initial_position
	label.modulate.a = initial_transparency

func _on_show_penalty_timer_timeout():
	fade_out_label(%Penalty_label,1)
	%Tricks_label.add_theme_color_override("font_color", colors["YELLOW"])
