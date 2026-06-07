extends Node2D

# Config
const TIME_SCALE = 1 
var ECHELLE = Global.ECHELLE
#Screen
var RATIO := 0.8
var ASPECT := 16.0 / 9.0

# Tuto
var act : String
var current_act : String
var dico_acts := {
	"Intro":["Well, Here we are.\nLet's see the basics","Time_HP"],
	"Time_HP":["This 2 up here are the [color=white]Timer[/color] and your [color=red]HP Bar[/color].\n"+
			"HP Bar should be your main focus during the game. I think it's pretty clear on what happend when "+
			"it reach [color=red]ZERO[/color] !",
			"Speed_Progress"],
	"Speed_Progress":["You obviously have to finish the Map. Down here, you can see the"+
			" [color=green]Progress Bar[/color].\n"+
			"You also have [color=blue]Checkpoints markers[/color]. In case of trouble, you will be respawned"+
			" at the last [color=blue]Checkpoint[/color] you've reach.\n"+
			"And there's a [color=orange]Speedometer[/color] because why not.",
			"Next"],
	"Next":["That's it for the main informations, let's move to the "+
			"[color=lime][wave]Start Line[/wave][/color]. We'll see how to ride your bike there.",
			"To_start"],
	"To_start":["Okay, let's see basic controls.\n"+
			"Press [img]res://Images/Keys/cursor-up.png[/img] to pedal, release it to stop accelerating.\n"+
			"Just try it now !",
			"To_jump"],
	"1st_crash":["Argh, I don't think you were ready for that first jump. Fyi, in case of crash, you'll receive "+
			"a [color=red][shake]Time and HP penalty[/shake][/color]. You will be respawned at the last "+
			"[color=blue]Checkpoint[/color] reached.",
			"Jump"],
	"Jump":["To avoid this inconvenient, you should [color=silver][pulse]Jump[/pulse][/color] over the next hole ! "+
			"To do so, start loading it by pressing \n\n[img]res://Images/Keys/spacebar.png[/img]",
			"Jump2"],
	"Jump2":["The [color=black][pulse]Jump Gauge[/pulse][/color] will appear :\n"+
			"[img]res://Images/HUD/jump/piston_mini.png[/img]\n"+
			"The [color=red]red[/color] dot will change its color. Try to release the jump key "+
			" when the dot turns [color=green]green[/color]. Releasing too late or too early will make the jump less powerfull.",
			"Jump3"],
	"Jump3":["Try it now, i'll wait for you at the next [color=blue]Checkpoint[/color].Look at the pannels we nicely place, "+
			"they indicate you the proper time to start loading the [color=silver][pulse]Jump[/pulse][/color].\n"+
			"Good luck with this one. Know that you can also choose to respawn at the last [color=blue]Checkpoint[/color] by pressing "+
			"[img]res://Images/Keys/backspace.png[/img]",
			"Jumping"],
	"Balance":["Ouch, are you alright ? That was a tough crash !\n"+
			"I think you should try to lean forward to clear the next jump. Use "+
			"[img]res://Images/Keys/cursor-left.png[/img] and [img]res://Images/Keys/cursor-right.png[/img] "+
			"to adjust your [color=aqua][wave]balance[/wave][/color].\n"+
			"Now, go ahead and try it ! See you at next [color=blue]CP[/color].",
			"Balancing"],
	"Brake":["And again ! Let's add a bit of safety. Sometimes, you'll have to [color=black]brake[/color] "+
			"in order to properly get the next jump. Press [img]res://Images/Keys/ctrl.png[/img] to use rear brake. Press "+
			"[img]res://Images/Keys/cursor-down.png[/img] for front brake. Take care with this one if you don't want to [color=red][shake]OTB[/shake][/color].",
			"Braking"],
	"Boost":["[pulse][wave]Another one bite the dust ![/wave][/pulse]\n"+
			"Okay, I may have forgot to tell you one last thing. Unlike the previous section, what you need this time "+
			"is [color=red]MORE SPEED[/color] and their is actually a way to do so. Since you can handle balance on the ground "+
			"and in the air, you can try to do nice [color=silver][shake]tricks[/shake][/color] such as "+
			"[color=white][i]wheelies[/i][/color] and [color=orange][tornado]flips[/tornado][/color].",
			"Boost2"],
	"Boost2":["When properly landed, tricks will be rewarded with [wave][b]score points[/b][/wave]."+
			"You can chain them to do combos and earn significantly more points. But there is even more !",
			"Boost3"],
	"Boost3":["Now, you can see down here the infamous [color=orange][pulse]Boost Gauge[/pulse][/color]."+
			"Scoring tricks will also get you [shake]energy[/shake] to fill this boost. You can consume it by pressing "+
			"[img]res://Images/Keys/alt.png[/img]. The fun thing is that, unlike basic pedaling, this works in the air too.",
			"Boost4"],
	"Boost4":["While doing tricks, the [color=#4a5ef5ff]blue zone[/color] indicates the maximum boost yon can get in one combo.\n"+
			"Try to [color=red][tornado]Backflip[/tornado][/color] the next big jump,"+
			"This should give you enough boost to clear the last step-up jump.\nGood luck and see you at the [color=red]Finish Line[/color] !",
			"Boosting"],
	"End":["[b][rainbow][wave]YAY, you did it ![/wave][/rainbow][/b]\n"+
			"That's it for the basics mechanics and controls. Now feel free to explore this part of the mountain."+
			"You will have to achieve different objectives in order to unlock maps and many other things such as "+
			"upgrades, new mechanics, etc...",
			"End2"],
	"End2":["You can head back to the [b][color=white]Village[/color][/b] at any time but you will have to restart "+
			"from the top of the [b][color=white]Chairlift[/color][/b] and redo maps starting from zero. Next time we "+
			"met, i'll present you to the band. See ya !",
			"Nothing"],
}
var dico_crash_act := {
	"To_jump":"1st_crash",
	"To_balance":"Balance",
	"To_brake":"Brake",
	"To_boost":"Boost",
	"Jumping":"To_balance",
	"Balancing":"To_brake",
	"Braking":"To_boost"
}

# Variables
@export var camera_offset := Vector2(300,-50)
@export var ymin_offset :float= -100
@export var ymax_offset :float= 300
@export var xspeed_offset_ratio := 15
@export var yspeed_offset_ratio := 15
@export var camera_smooth := 2.0
@export var no_zoom_speed := 30
@export var min_zoom := 0.8
@export var max_zoom := 1.1
var camera_target: Node2D = null
var map_courante :Node2D
var velo_courant :Node2D
var map_data := {}
var race_started := false
var distance_restante := 0.0
var avancement := 0
var is_paused := false
var is_finished :=false
var is_learning : bool
var can_jump : bool
var can_balance : bool
var can_boost : bool

func _ready():
	Engine.time_scale = TIME_SCALE
	var cursor = load("res://Images/Menus/Controls/cursor.png")
	Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, Vector2(0, 0))
	%Pause_Menu.hide()
	%Finish_Menu.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	# Screen size
	var screen_rect = DisplayServer.screen_get_usable_rect()
	var screen_width = int(screen_rect.size.x * RATIO)
	var screen_height = int(screen_width / ASPECT)
	var new_size = Vector2i(screen_width,screen_height)
	DisplayServer.window_set_size(Vector2i(screen_width,screen_height))
	DisplayServer.window_set_position(screen_rect.position + (screen_rect.size - new_size) / 2)
	# Buttons
	set_up_buttons(self)
	# Connections
	Global.hud_new_best.connect(%HUD.update_best_tricks)
	Global.hud_trick_activate.connect(%HUD.trick_activate)
	Global.hud_trick_reset.connect(%HUD.trick_reset)
	Global.hud_combo_update.connect(%HUD.update_combo)
	Global.hud_score_update.connect(%HUD.update_score)
	# Chargements
	load_map()
	# Tuto specifics
	AudioManager.play_music("Tuto")
	is_learning = true
	%Ingame_Label.hide()
	%AvatarBike.texture = load(Global.get_sprites_path() + "Avatar_bike.png")
	current_act = "Intro"
	_on_tuto_next_button_pressed()

func _on_tuto_next_button_pressed():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	if current_act == "To_jump" :
		for node in [%AvatarBike,%Char1Pannel,%TutoNextButton]:node.hide()
		is_learning = false
		can_jump = false
		can_balance = false
		can_boost = false
		load_bike()
	elif current_act == "Jumping" :
		%AnimationPlayer.play("To_balance")
		is_learning = false
		can_jump = true
		load_bike()
	elif current_act == "Balancing" :
		%AnimationPlayer.play("To_brake")
		is_learning = false
		can_balance = true
		respawn_bike()
	elif current_act == "Braking" :
		%AnimationPlayer.play("To_boost")
		is_learning = false
		respawn_bike()
	elif current_act == "Boosting" :
		%AnimationPlayer.play("To_end")
		is_learning = false
		respawn_bike()
	else:
		if current_act == "Boost4":can_boost = true
		%HUD.set_visibility(current_act)
		%AnimationPlayer.play(current_act)
		%Char1Text.text = ""
		await %AnimationPlayer.animation_finished
		%Char1Text.text = dico_acts[current_act][0]
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		current_act = dico_acts[current_act][1]

func _on_end_tuto_button_pressed():
	AudioManager.stop_ground_sfx()
	AudioManager.stop_music()
	AudioManager.stop_sfx()
	Global.menu_to_show = "Chairlift"
	Global.start_mod("Menus")

func _input(event):
	if race_started and not is_finished:
		if event.is_action_pressed("Pause"):toggle_pause()
		if Input.is_action_just_pressed("Restart"):restart()
		if Input.is_action_just_pressed("Respawn"):respawn_bike()

func restart():
	%Camera.global_position = camera_target.global_position
	if not is_finished:velo_courant.queue_free()
	SaveManager.load_config()
	SaveManager.set_current_profile(SaveManager.load_profile(Global.config.get("profil_en_cours")))
	AudioManager.stop_music()
	AudioManager.stop_sfx()
	#map_courante.queue_free()
	await get_tree().process_frame
	%HUD.reset()
	#load_map()
	load_bike()
	%HUD.update_score(Global.current_score)
	is_finished = false

func load_map():
	map_courante = %Map
	map_courante.finish.connect(map_finished)
	map_courante.out_of_bounds.connect(respawn_bike)
	map_courante.act_done.connect(change_act)
	map_data = map_courante.get_level_data()

func change_act():current_act = dico_crash_act[current_act]

func map_finished():
	if not is_finished:
		camera_target = map_data["finish"]
		is_finished = true
		Global.avancement = 100
		Global.current_profile["current_run"]["finished_maps"]["0"] = {"objectives":[],"bills":[]}
		Global.current_profile["state"] = "tuto2"
		SaveManager.save_profile(Global.current_profile)
		AudioManager.stop_music()
		#AudioManager.play_sfx("fireworks")
		AudioManager.play_music("Victory")
		current_act = "End"
		_on_tuto_next_button_pressed()
	#%Finish_Menu.show()
	#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#%Time_label.text = Global.format_time(Global.race_time)
	#%PreviousTime_label.text = "-" if str(Global.previous_best["time"]) == "-" else Global.format_time(Global.previous_best["time"])
	#%NewBestTime_label.visible = Global.new_best_time
	#%Score_label.text = str(int(Global.current_score))
	#%PreviousScore_label.text = "-" if str(Global.previous_best["score"]) == "-" else str(int(Global.previous_best["score"]))
	#%NewBestScore_label.visible = Global.new_best_score

func load_bike():
	race_started = false
	velo_courant = load(Global.get_profile_bike()).instantiate()
	%BikeContainer.add_child(velo_courant)
	camera_target = velo_courant.cadre
	velo_courant.crashed.connect(respawn_bike)
	velo_courant.boost_consumed.connect(%HUD.set_boost_segment_geometry)
	velo_courant.input_enabled = false
	Global.set_start_values()
	start_countdown()

func respawn_bike():
	if current_act in ["To_jump","To_balance","To_brake","To_boost"]:
		velo_courant.queue_free()
		await get_tree().process_frame
		is_learning = true
		current_act = dico_crash_act[current_act]
		_on_tuto_next_button_pressed()
	else:
		if is_instance_valid(velo_courant):
			%Camera.global_position = camera_target.global_position
			velo_courant.queue_free()
			if is_finished:
				%HUD.set_visibility("End")
				return
			await get_tree().process_frame
		velo_courant = load(Global.get_profile_bike()).instantiate()
		%BikeContainer.add_child(velo_courant)
		disable_inputs_for_x_second(0.5)
		velo_courant.can_drive = true
		camera_target = velo_courant.cadre
		velo_courant.crashed.connect(respawn_bike)
		velo_courant.boost_consumed.connect(%HUD.set_boost_segment_geometry)
		Global.handle_crash()
		%HUD.update_HP_Bar()
		%HUD.update_score(Global.current_score)
		if Global.debug :
			velo_courant.global_position = Vector2(30000,5500)
			velo_courant.cadre.linear_velocity = Vector2(10,0)
		else :
			velo_courant.global_position = Global.cp_player_pos
			velo_courant.cadre.linear_velocity = Global.cp_player_speed / (ECHELLE * 3.6)

func start_countdown():
	#race_started = false
	#%Ingame_Label.show()
	#for i in [3, 2, 1]:
		#%Ingame_Label.text = str(i)
		#AudioManager.play_sfx(str(i))
		#await get_tree().create_timer(0).timeout
	#%Ingame_Label.text = "GO !"
	#AudioManager.play_sfx("Go")
	#AudioManager.play_sfx("horn")
	velo_courant.can_drive = true
	race_started = true
	#await get_tree().create_timer(1).timeout
	#%Ingame_Label.hide()
	#AudioManager.play_music("Map_" + str(Global.current_map))

func disable_inputs_for_x_second(x:float):
	velo_courant.input_enabled = false
	await get_tree().create_timer(x).timeout
	velo_courant.input_enabled = can_balance

func _process(delta):
	if is_learning:return
	if is_instance_valid(camera_target) and not is_finished and race_started and velo_courant.input_enabled:
		var xoffset :float= Global.vitesse.x * xspeed_offset_ratio
		var yoffset :float= clamp(Global.vitesse.y * yspeed_offset_ratio + Global.ground_distance,ymin_offset,ymax_offset)
		var speed_offset := Vector2(xoffset,yoffset)
		%Camera.global_position = %Camera.global_position.lerp(
			camera_target.global_position + camera_offset + speed_offset,
			camera_smooth * delta
		)
		var zoom_factor := clampf(no_zoom_speed/Global.vitesse.length(),min_zoom,max_zoom)
		%Camera.zoom = %Camera.zoom.lerp(Vector2(zoom_factor,zoom_factor),camera_smooth * delta)
	else:
		%Camera.global_position = camera_target.global_position + camera_offset
		%Camera.zoom = Vector2.ONE

func _physics_process(_delta):
	# Tracking
	if not race_started or is_paused or is_finished:return
	# Temps
	#Global.race_time += delta
	# Jump block
	if not can_jump: Global.taux_compression = 0
	# Trick block
	if not can_boost : Global.reset_tricks()
	# Avancement
	if is_instance_valid(velo_courant):
		Global.avancement = clampi(100 * (
				1-(map_data["finish"].global_position.x - velo_courant.cadre.global_position.x)
				/map_data["finish"].global_position.x),
				0,100)
	
func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	if is_paused:
		%Pause_Menu.show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		%Pause_Menu.hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_resume_button_pressed():toggle_pause()

func _on_abandon_button_pressed():
	toggle_pause()
	Global.menu_to_show = "Carrière"
	Global.start_mod("Menus")

func _on_retry_button_pressed():
	%Finish_Menu.hide()
	restart()

func _on_continue_pressed():
	Global.menu_to_show = "Carrière"
	Global.start_mod("Menus")

func set_up_buttons(node):
	for child in node.get_children():
		if child is BaseButton:
			child.mouse_entered.connect(func(): on_button_hover(child))
			child.mouse_exited.connect(func(): on_button_hover_exit(child))
			child.focus_entered.connect(func(): on_button_focus(child))
			child.pressed.connect(func():on_button_pressed(child))
		set_up_buttons(child)

func on_button_hover(button:BaseButton):button.grab_focus()
func on_button_hover_exit(_button:BaseButton):get_viewport().gui_release_focus()
func on_button_focus(_button:BaseButton):AudioManager.play_ui("hover")
func on_button_pressed(_button:BaseButton):AudioManager.play_ui("click")
