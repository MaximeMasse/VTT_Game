extends CanvasLayer

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

func _ready():
	reset()
	update_best_tricks()

func reset():
	%Penalty_label.text = "+ " + str(int(Global.current_profile["upgrades"]["RESPAWN_PENALTY"])) + " sec"
	%Penalty_label.hide()
	%Piston.hide()
	%Tricks_label.hide()

func update_best_tricks():
	%Air_label.text = str(round_to(Global.current_profile["best_tricks"]["Air"]["length"],1)) + " m | "\
		+ str(round_to(Global.current_profile["best_tricks"]["Air"]["duration"],1)) + " sec"
	%Wheelie_label.text = str(round_to(Global.current_profile["best_tricks"]["Wheelie"]["length"],1)) + " m | "\
		+ str(round_to(Global.current_profile["best_tricks"]["Wheelie"]["duration"],1)) + " sec"
	%Nose_label.text = str(round_to(Global.current_profile["best_tricks"]["Nose Wheelie"]["length"],1)) + " m | "\
		+ str(round_to(Global.current_profile["best_tricks"]["Nose Wheelie"]["duration"],1)) + " sec"

func _physics_process(delta):
	%Time_label.text = format_time(Global.race_time)
	if Global.penalty_to_show and %Show_penalty_timer.is_stopped():
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
	#if Global.current_trick != "":
		#%Tricks_label.text = Global.current_trick + "\n" + str(round_to(Global.trick_datas.x,1)) + " m | " + str(round_to(Global.trick_datas.y,1)) + " sec"
		#%Tricks_label.show()
	#else: %Tricks_label.hide()

func format_time(t: float) -> String:
	var minutes := int(t) / 60
	var seconds := int(t) % 60
	var ms := int((t - int(t)) * 1000)
	return "%02d:%02d.%03d" % [minutes, seconds, ms]

func round_to(value: float, decimals: int) -> float:
	var factor = pow(10, decimals)
	return round(value * factor) / factor

func fade_out_label(label: Label):
	var initial_scale = label.scale
	var initial_position = label.position
	var initial_transparency = label.modulate.a
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 1.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "scale", Vector2(1.5, 1.5), 1.0)
	tween.parallel().tween_property(label, "position:y", label.position.y - 50, 1.0)
	await tween.finished
	label.hide()
	label.scale = initial_scale
	label.position = initial_position
	label.modulate.a = initial_transparency

func _on_show_penalty_timer_timeout():
	fade_out_label(%Penalty_label)
