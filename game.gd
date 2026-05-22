extends Node2D

# Config
const TIME_SCALE = 1 
var ECHELLE = Global.ECHELLE
#Screen
var RATIO := 0.8
var ASPECT := 16.0 / 9.0

# Variables
@export var camera_offset := Vector2(300,0)
@export var ymin_offset :float= -100
@export var ymax_offset :float= 1000
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
	load_bike()

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
	map_courante.queue_free()
	await get_tree().process_frame
	%HUD.reset()
	load_map()
	load_bike()
	%HUD.update_score(Global.current_score)
	is_finished = false

func load_map():
	var path : String = Global.get_current_map()
	var map_scene := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	map_courante = map_scene.instantiate()
	%MapContainer.add_child(map_courante)
	map_courante.finish.connect(map_finished)
	map_courante.out_of_bounds.connect(respawn_bike)
	map_data = map_courante.get_level_data()

func map_finished():
	camera_target = map_data["finish"]
	is_finished = true
	Global.end_map()
	AudioManager.stop_music()
	AudioManager.play_sfx("fireworks")
	AudioManager.play_music("Victory")
	%Finish_Menu.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	%Time_label.text = Global.format_time(Global.race_time)
	%PreviousTime_label.text = "-" if str(Global.previous_best["time"]) == "-" else Global.format_time(Global.previous_best["time"])
	%NewBestTime_label.visible = Global.new_best_time
	%Score_label.text = str(int(Global.current_score))
	%PreviousScore_label.text = "-" if str(Global.previous_best["score"]) == "-" else str(int(Global.previous_best["score"]))
	%NewBestScore_label.visible = Global.new_best_score

func load_bike():
	race_started = false
	velo_courant = load(Global.get_profile_bike()).instantiate()
	%BikeContainer.add_child(velo_courant)
	camera_target = velo_courant.cadre
	velo_courant.crashed.connect(respawn_bike)
	velo_courant.boost_consumed.connect(%HUD.set_boost_segment_geometry)
	Global.race_time = 0.0
	Global.current_cp = "start"
	Global.cp_player_speed = Vector2.ZERO
	Global.cp_player_pos = Vector2.ZERO
	Global.cp_player_score = 0
	Global.cp_player_boost = 0
	Global.current_score = 0
	Global.current_boost = 0
	start_countdown()

func respawn_bike():
	%Camera.global_position = camera_target.global_position
	velo_courant.queue_free()
	if is_finished:return
	await get_tree().process_frame
	velo_courant = load(Global.get_profile_bike()).instantiate()
	%BikeContainer.add_child(velo_courant)
	disable_inputs_for_x_second(0.5)
	velo_courant.can_drive = true
	camera_target = velo_courant.cadre
	velo_courant.crashed.connect(respawn_bike)
	velo_courant.boost_consumed.connect(%HUD.set_boost_segment_geometry)
	Global.penalty_to_show = true
	Global.race_time += Global.current_profile["upgrades"]["RESPAWN_PENALTY"]
	velo_courant.global_position = Global.cp_player_pos
	velo_courant.cadre.linear_velocity = Global.cp_player_speed / (ECHELLE * 3.6)
	Global.current_score = Global.cp_player_score
	Global.current_boost = Global.cp_player_boost
	%HUD.update_score(Global.current_score)

func start_countdown():
	race_started = false
	%Ingame_Label.show()
	for i in [3, 2, 1]:
		%Ingame_Label.text = str(i)
		AudioManager.play_sfx(str(i))
		await get_tree().create_timer(0).timeout
	%Ingame_Label.text = "GO !"
	AudioManager.play_sfx("Go")
	AudioManager.play_sfx("horn")
	velo_courant.can_drive = true
	race_started = true
	await get_tree().create_timer(1).timeout
	%Ingame_Label.hide()
	AudioManager.play_music("Map_" + str(Global.current_map))

func disable_inputs_for_x_second(x:float):
	velo_courant.input_enabled = false
	await get_tree().create_timer(x).timeout
	velo_courant.input_enabled = true

func _process(delta):
	if is_instance_valid(camera_target) and not is_finished and velo_courant.input_enabled and race_started:
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

func _physics_process(delta):
	# Tracking
	if not race_started or is_paused or is_finished:return
	# Temps
	Global.race_time += delta
	# Avancement
	if is_instance_valid(velo_courant):
		if velo_courant.cadre.global_position.x < map_data["start"].global_position.x:
			Global.avancement = 0
		elif velo_courant.cadre.global_position.x >= map_data["finish"].global_position.x:
			Global.avancement = 100
		else:
			Global.avancement = (
				1-(map_data["finish"].global_position.x - velo_courant.cadre.global_position.x)/map_data["finish"].global_position.x)*100
	
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
	get_tree().change_scene_to_file("res://menus.tscn")

func _on_retry_button_pressed():
	%Finish_Menu.hide()
	restart()

func _on_continue_pressed():
	Global.menu_to_show = "Carrière"
	get_tree().change_scene_to_file("res://menus.tscn")

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
