extends Node2D

# Config
const TIME_SCALE = 1 
var ECHELLE = Global.ECHELLE
#Screen
var RATIO := 0.8
var ASPECT := 16.0 / 9.0

# Variables
var camera_offset := Vector2(400,0)
var camera_target: Node2D = null
var camera_smooth := 5.0
var map_courante :Node2D
var velo_courant :Node2D
var map_data := {}
var race_started := false
var distance_restante := 0.0
var avancement := 0
var is_paused := false

func _ready():
	Engine.time_scale = TIME_SCALE
	var cursor = load("res://Images/Menus/Controls/cursor.png")
	Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, Vector2(0, 0))
	%MenuPause.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	# Screen size
	var screen_rect = DisplayServer.screen_get_usable_rect()
	var screen_width = int(screen_rect.size.x * RATIO)
	var screen_height = int(screen_width / ASPECT)
	var new_size = Vector2i(screen_width,screen_height)
	DisplayServer.window_set_size(Vector2i(screen_width,screen_height))
	DisplayServer.window_set_position(screen_rect.position + (screen_rect.size - new_size) / 2)
	
	# Connections
	Global.new_best.connect(%HUD.update_best_tricks)
	
	# Chargements
	load_map()
	load_bike()

func _input(event):
	
	#Debug
	if event.is_action_pressed("Map1"):
		Global.current_map = 1
	if event.is_action_pressed("Map2"):
		Global.current_map = 2
	if event.is_action_pressed("Map3"):
		Global.current_map = 3
	if event.is_action_pressed("Map4"):
		Global.current_map = 4
	if event.is_action_pressed("Map5"):
		Global.current_map = 5
	
	# InGame
	if race_started:
		if event.is_action_pressed("Pause"):
			toggle_pause()
		if Input.is_action_just_pressed("Restart"):
			SaveManager.load_config()
			SaveManager.set_current_profile(SaveManager.load_profile(Global.config.get("profil_en_cours")))
			%HUD.reset()
			AudioManager.stop_music()
			AudioManager.stop_sfx()
			velo_courant.queue_free()
			map_courante.queue_free()
			load_map()
			load_bike()
		if Input.is_action_just_pressed("Respawn"):
			velo_courant.queue_free()
			respawn_bike()

func load_map():
	map_courante = Global.get_current_map().instantiate()
	%MapContainer.add_child(map_courante)
	map_courante.finish.connect(map_finished)
	map_data = map_courante.get_level_data()

func map_finished():
	AudioManager.play_sfx("fireworks")
	camera_target = map_data["finish"]

func load_bike():
	race_started = false
	velo_courant = Global.get_profile_bike().instantiate()
	%BikeContainer.add_child(velo_courant)
	camera_target = velo_courant.cadre
	velo_courant.crashed.connect(respawn_bike)
	Global.race_time = 0.0
	Global.current_cp = "start"
	Global.cp_player_speed = Vector2.ZERO
	Global.cp_player_pos = Vector2.ZERO
	start_countdown()

func respawn_bike():
	velo_courant = Global.get_profile_bike().instantiate()
	%BikeContainer.add_child(velo_courant)
	velo_courant.can_drive = true
	camera_target = velo_courant.cadre
	velo_courant.crashed.connect(respawn_bike)
	Global.penalty_to_show = true
	Global.race_time += Global.current_profile["upgrades"]["RESPAWN_PENALTY"]
	velo_courant.global_position = Global.cp_player_pos
	velo_courant.cadre.linear_velocity = Global.cp_player_speed / (ECHELLE * 3.6)

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
	

func _process(delta):
	if is_instance_valid(camera_target):
		%Camera.global_position = %Camera.global_position.lerp(
			camera_target.global_position + camera_offset,
			camera_smooth * delta
		)

func _physics_process(delta):
	# Tracking
	# Temps
	if race_started:
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
		%MenuPause.show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		%MenuPause.hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_resume_button_pressed():
	toggle_pause()

func _on_abandon_button_pressed():
	toggle_pause()
	get_tree().change_scene_to_file("res://menus.tscn")
