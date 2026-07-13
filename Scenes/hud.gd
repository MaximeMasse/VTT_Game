extends CanvasLayer

var colors := {
	"RED":Color(1,0.04,0.04,1),
	"YELLOW":Color("d9db00ff"),
	"DARK_GREY":Color("33333bff"),
	"GREEN":Color("5c9f47ff"),
	"LIGHT_GREEN":Color(0.2,0.9,0.23,1),
	"ORANGE":Color(0.76,0.37,0,1),
	"LIGHT_BLUE":Color("4a5ef5ff"),
	"VIOLET":Color("ad29ddff")
}

var dico_saut :={
	Vector2(0,10):["Red",load("res://Images/HUD/jump/piston_0.png")],
	Vector2(10,20):["res://Images/HUD/jump/jump_orange.png",load("res://Images/HUD/jump/piston_10.png")],
	Vector2(20,30):["res://Images/HUD/jump/jump_orange.png",load("res://Images/HUD/jump/piston_20.png")],
	Vector2(30,40):["res://Images/HUD/jump/jump_orange.png",load("res://Images/HUD/jump/piston_30.png")],
	Vector2(40,50):["res://Images/HUD/jump/jump_orange.png",load("res://Images/HUD/jump/piston_40.png")],
	Vector2(50,60):["res://Images/HUD/jump/jump_yellow.png",load("res://Images/HUD/jump/piston_50.png")],
	Vector2(60,70):["res://Images/HUD/jump/jump_yellow.png",load("res://Images/HUD/jump/piston_60.png")],
	Vector2(70,80):["res://Images/HUD/jump/jump_yellow.png",load("res://Images/HUD/jump/piston_70.png")],
	Vector2(80,90):["res://Images/HUD/jump/jump_yellow.png",load("res://Images/HUD/jump/piston_80.png")],
	Vector2(90,100):["res://Images/HUD/jump/jump_green.png",load("res://Images/HUD/jump/piston_90.png")]
}
@onready var dico_to_hide :={
		"on_finish":[[%Tricks_label,%Combo_label],false],
		"Intro":[[%Vitesse_label,%Time_label,%Avancement_bar,%Tricks_label,%Combo_label,%Trick_score_label,%Trick_scored_label,%Score_label,%Boost_gauge,%Boost_segment,%HPBar,%Joueur],false],
		"Time_HP":[[%HPBar,%Time_label],true],
		"Speed_Progress":[[%Vitesse_label,%Avancement_bar],true],
		"Next":[[],true],
		"To_start":[[],true],
		"1st_crash":[[%Boost_segment,%Tricks_label,%Combo_label,%Trick_score_label,%Trick_scored_label,%Score_label],false],
		"Jump":[[%Piston],true],
		"Jump2":[[],true],
		"Jump3":[[],true],
		"To_balance":[[],true],
		"Balance":[[%Boost_segment,%Tricks_label,%Combo_label,%Trick_score_label,%Trick_scored_label,%Score_label],false],
		"Brake":[[%Boost_segment,%Tricks_label,%Combo_label,%Trick_score_label,%Trick_scored_label,%Score_label],false],
		"Boost":[[%Boost_segment,%Tricks_label,%Combo_label,%Trick_score_label,%Trick_scored_label,%Score_label],false],
		"Boost2":[[],false],
		"Boost3":[[%Boost_gauge],true],
		"Boost4":[[%Boost_segment],true],
		"End":[[%Boost_segment,%Tricks_label,%Combo_label,%Trick_score_label,%Trick_scored_label,%Score_label],false],
		"End2":[[],true],
	}
var dico_cps_marker : Dictionary

var best_trick_labels:Dictionary
var is_tricking :bool
var label_is_fading :Dictionary
var boost_gauge_size:float
var boost_segment_max_size:float

func _ready():
	reset()
	Global.set_start_values()
	%Trick_scored_label.hide()
	best_trick_labels={"Air":%Air_label,"Wheelie":%Wheelie_label,"Nose Wheelie":%Nose_label}
	label_is_fading = {%Penalty_label:false,%Tricks_label:false,%Trick_scored_label:false}
	for trick in ["Wheelie","Nose Wheelie","Air"]:update_best_tricks(trick,false)

func reset():
	%GameOver.hide()
	%Penalty_label.text = "+ " + str(int(Global.current_profile["upgrades"]["RESPAWN_TIME_PENALTY"])) + " sec"
	%Penalty_label.hide()
	%Piston.hide()
	%Tricks_label.hide()
	is_tricking = false
	%Combo_label.text = ""
	%Trick_score_label.hide()
	%Score_label.text = "Score : " + str(int(Global.current_score)) + " Points"
	%Landing_label.text = ""
	%Boost_gauge.value = 0
	%Boss.hide()
	set_boost_geometry()
	update_money()

func set_visibility(moment:String):for node in dico_to_hide[moment][0]:node.visible = dico_to_hide[moment][1]

func update_HP_Bar():
	%HPBar.value = Global.current_hp
	%HPBar.set_fillshader_param("life",Global.current_hp)

func update_money():
	var total_money : String = Global.format_number(Global.current_profile["current_run"]["money"]+Global.money_catched)
	%Money.text = "[img]res://Images/HUD/Player/BucksLogo_mini.png[/img]  "+ total_money

func update_boss_gauge(gap_score:float):
	if gap_score >= 0.0:
		%RightScore.value = gap_score
		%LeftScore.value = 0
	else:
		%RightScore.value = 0
		%LeftScore.value = -gap_score
	%Boss.show()

func set_boost_geometry():
	%Boost_gauge.max_value = Global.BOOST_MAX_QUANTITY
	boost_gauge_size = %Boost_gauge.size.x * Global.BOOST_MAX_QUANTITY/10000
	%Boost_gauge.scale.x = (Global.BOOST_MAX_QUANTITY/10000)
	boost_segment_max_size = boost_gauge_size/Global.ONE_TIME_RATIO

func set_boost_segment_geometry():
	%Boost_segment.position.x = %Boost_gauge.position.x + Global.current_boost * boost_gauge_size / Global.BOOST_MAX_QUANTITY
	%Boost_segment.size.x = clampf(boost_segment_max_size,0,boost_gauge_size+%Boost_gauge.position.x-%Boost_segment.position.x)

func set_cp_markers():
	dico_cps_marker = Global.get_cp_names_and_ratio()
	var progress_bar_size : float = %Avancement_bar.size.x
	for marker in dico_cps_marker:
		var sprite := Sprite2D.new()
		%Avancement_bar.add_child(sprite)
		sprite.scale = Vector2(0.1,0.1)
		sprite.texture = preload("res://Images/HUD/CPs/Light_off.png")
		sprite.position = Vector2(dico_cps_marker[marker] * progress_bar_size,14)
		dico_cps_marker[marker] = {"node":sprite,"activated":false}

func update_cp(cp : String):
	for marker in dico_cps_marker:
		if marker == cp : 
			dico_cps_marker[marker]["node"].texture = preload("res://Images/HUD/CPs/Light_focus.png")
			dico_cps_marker[marker]["activated"] = true
		elif dico_cps_marker[marker]["activated"] : dico_cps_marker[marker]["node"].texture = preload("res://Images/HUD/CPs/Light_on.png")

func update_score(points):
	%Trick_scored_label.text = "+ " + str(int(points)) + " Points" 
	%Landing_label.text = Global.landing_frame
	%Trick_scored_label.show()
	%Score_label.add_theme_color_override("font_color", colors["ORANGE"])
	%Score_label.text = "Score : " + str(int(Global.current_score)) + " Points"
	await fade_out_label(%Trick_scored_label,Vector2(2,2),Vector2(100,80),1)
	%Score_label.add_theme_color_override("font_color", colors["YELLOW"])

func update_best_tricks(trick_name,effect=true):
	best_trick_labels[trick_name].text = str(round_to(Global.current_profile["best_tricks"][trick_name]["length"],1)) + " m | "\
		+ str(round_to(Global.current_profile["best_tricks"][trick_name]["duration"],1)) + " sec"
	if effect :
		best_trick_labels[trick_name].add_theme_color_override("font_color", colors["LIGHT_GREEN"])
		await get_tree().create_timer(1).timeout
		best_trick_labels[trick_name].add_theme_color_override("font_color", colors["DARK_GREY"])

func trick_reset(display_time:float=0):
	is_tricking = false
	%Trick_score_label.hide()
	fade_out_label(%Tricks_label,Vector2(1,1),Vector2(0,50),1)
	%Boost_segment.hide()
	await get_tree().create_timer(display_time).timeout
	%Combo_label.text = ""
	%Landing_label.text = ""

func trick_activate():
	is_tricking = true
	%Tricks_label.show()
	%Trick_score_label.show()
	set_boost_segment_geometry()
	%Boost_segment.show()

func update_combo(text,clear:bool=false):%Combo_label.text = "" if clear else %Combo_label.text + text

func injury_update(state:String):
	if state =="safe":
		%Injury.hide()
		AudioManager.stop_sfx("heartbeat")
		AudioManager.set_bus_volume("Music", Global.config.get("music_volume", 0.8))
	elif state == "wounded":
		%Injury.show()
		%InjuryCover.show()
		%InjuryCover2.hide()
		AudioManager.stop_sfx("heartbeat")
		AudioManager.set_bus_volume("Music", Global.config.get("music_volume", 0.8))
	elif state == "critical":
		%Injury.show()
		%InjuryCover.hide()
		%InjuryCover2.show()
		AudioManager.set_bus_volume("Music", Global.config.get("music_volume", 0.8) * 0.3)
		AudioManager.play_sfx("heartbeat")

func game_over():
	AudioManager.sfx_muted = true
	AudioManager.stop_all()
	AudioManager.set_bus_volume("Music", Global.config.get("music_volume", 0.8))
	AudioManager.play_music("Game_over")
	%AnimationPlayer.play("game_over")

func round_to(value: float, decimals: int) -> float:
	var factor = pow(10, decimals)
	return round(value * factor) / factor

func fade_out_label(label: Control,scaling: Vector2,offseting: Vector2,effect_duration: float):
	if not label_is_fading[label]:
		label_is_fading[label] = true
		var initial_scale = label.scale
		var initial_position = label.position
		var initial_transparency = label.modulate.a
		var tween = create_tween()
		tween.tween_property(label, "modulate:a", 0.0, effect_duration)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(label, "scale", scaling, effect_duration)
		tween.parallel().tween_property(label, "position", label.position - offseting, effect_duration)
		await tween.finished
		label_is_fading[label] = false
		label.hide()
		label.scale = initial_scale
		label.position = initial_position
		label.modulate.a = initial_transparency

func _on_show_penalty_timer_timeout():
	fade_out_label(%Penalty_label,Vector2(1.5,1.5),Vector2(0,50),1)
	%Tricks_label.add_theme_color_override("default_color", colors["YELLOW"])

func _process(_delta):
	%Time_label.text = Global.format_time(Global.race_time+Global.penalty_time)
	if Global.penalty_to_show and %Show_penalty_timer.is_stopped():
		%Tricks_label.add_theme_color_override("default_color", colors["RED"])
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
		%Tricks_label.show()
		%Tricks_label.text = Global.current_trick["trick"] + "\n"\
	 		+ str(round_to(Global.current_trick["length"],1)) + " m | "\
	 		+ str(round_to(Global.current_trick["duration"],1)) + " sec"
		%Trick_score_label.text = str(int(Global.potential_combo_score+Global.potential_trick_score)) + " Points"
	%Boost_gauge.value = Global.current_boost + min(Global.potential_combo_score + Global.potential_trick_score,Global.ONE_TIME_QUANTITY)

func _on_new_run_pressed():
	AudioManager.stop_all()
	AudioManager.sfx_muted = false
	Global.current_profile["state"] = "Career"
	Global.set_run(true)
	Global.start_mod("Career")
	SaveManager.save_profile(Global.current_profile)
