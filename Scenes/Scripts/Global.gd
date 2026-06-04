extends Node

# Config
var debug : bool = true
const ECHELLE = 1.7/152
var current_profile := {}
var config := {}

# Sélections
var current_map := "0"
var map_data : Dictionary

# HUD
var race_time : float
var penalty_to_show := false
var current_hp : float
var contact_sol := true
var vitesse := Vector2.ZERO
var player_position := Vector2.ZERO
var player_rotation := 0.0
var avancement := 0
var taux_compression :float= 0
var current_score :float

# Floors
var floor_is : int
var ground_distance : float

#Tricks
var current_trick := {}
var potential_trick_score :int
var potential_combo_score :int
var potential_trick := {}
var current_combo :Array[Dictionary]= []
# Gap
var is_gapping : String
var is_in_gap : bool
var gap_combo : Array[String]
var special_trick_done : bool

# Boost
var BOOST_MAX_QUANTITY :float
var ONE_TIME_RATIO :int
var BOOST_CONSUMPTION :float
var ONE_TIME_QUANTITY :float
var current_boost:float

# CP datas
var current_cp : String
var cp_player_speed : Vector2
var cp_player_pos : Vector2
var cp_player_score : float
var cp_player_boost : float

# Collectible
var is_grabbed : bool
var is_stored : bool
signal return_collectible
signal store_collectible

# End map
var new_best_time :bool
var new_best_score :bool
var previous_best :Dictionary
var objectives_completed : Array
var objectives_text : String

#Menus
var menu_to_show := "MainMenu"

var rotation_name_and_point := {1:["",1.0],2:["Double",2.0],3:["Triple",3.0],
							4:["Quadruple",4.0],5:["Quintuple",5.0],6:["Sextuple",6.0],7:["Septuple",7.0]}
var tricks_values : Dictionary = {
	"":0,
	"length_to_double":10,
	"duration_to_double":2,
	"Air":50,
	"Wheelie":100,
	"Nose Wheelie":150,
	"Backflip":100,
	"Frontflip":150
}

# Dicos
var dico_maps := {
	"0":"res://Maps/map_0.tscn",
	"1":"res://Maps/map_1.tscn"
}
var dico_vélo := {
	0:"res://Bikes/bike_0.tscn",
	1:"res://Bikes/bike_1.tscn",
	2:"res://Bikes/bike_2.tscn",
}
var dico_avatars := {
	1:"Woman",
	2:"Man",
	3:"Girl",
	4:"Boy",
	5:"Cat"
}
var dico_scenes :={
	"Menus":"res://Scenes/menus.tscn",
	"Main_Game":"res://Scenes/Games/game.tscn",
	"Tuto_Game":"res://Scenes/Games/tuto_game.tscn"
}

signal hud_trick_reset
signal hud_trick_activate
signal hud_combo_update
signal hud_score_update
signal hud_new_best

func start_mod(scene_name:String):
	# Boost
	BOOST_MAX_QUANTITY = current_profile["boost"]["BOOST_MAX_QUANTITY"]
	ONE_TIME_RATIO = current_profile["boost"]["ONE_TIME_RATIO"]
	BOOST_CONSUMPTION = current_profile["boost"]["BOOST_CONSUMPTION"]
	ONE_TIME_QUANTITY = BOOST_MAX_QUANTITY/ONE_TIME_RATIO
	get_tree().change_scene_to_file(dico_scenes[scene_name])

func get_current_map():return dico_maps[current_map]
func get_sprites_path()->String:
	if current_profile != {}:return "res://Avatar/Players/" + dico_avatars[int(current_profile["avatar"])] + "/"
	else:return ""
func get_profile_bike()->String:return dico_vélo[int(current_profile["bike_model"])]
func get_profile_data(data:String)->String:return current_profile[data]

func set_start_values():
	is_grabbed = false
	is_stored = false
	is_gapping = ""
	is_in_gap = false
	special_trick_done = false
	objectives_completed = []
	objectives_text = ""
	race_time = 0.0
	current_hp = 100
	current_cp = "start"
	cp_player_speed = Vector2.ZERO
	cp_player_pos = Vector2.ZERO
	cp_player_score = 0
	cp_player_boost = 0
	current_score = 0
	current_boost = 0

func handle_crash():
	# Penaltys
	penalty_to_show = true
	race_time += current_profile["upgrades"]["RESPAWN_TIME_PENALTY"]
	current_hp -= current_profile["upgrades"]["RESPAWN_HP_PENALTY"]
	# Score and boost reset
	current_score = cp_player_score
	current_boost = cp_player_boost
	# Collectible
	if not is_stored and is_grabbed: 
		is_grabbed = false
		return_collectible.emit()
	# Gap
	is_gapping = ""
	is_in_gap = false

func checkpoint_update(cp : String,min_speed : float = 0):
	if current_cp != cp:
		current_cp = cp
		cp_player_speed =  min_speed * vitesse.normalized() if vitesse.length() < min_speed else vitesse
		cp_player_pos = player_position
		cp_player_score = current_score
		cp_player_boost = current_boost

func gap_entry(gap_name : String):
	if current_trick["trick"] != "" or not contact_sol:
		print("good entry ",gap_name)
		is_gapping = gap_name
		is_in_gap = true
		gap_combo = []
	else:print("bad entry ",gap_name)

func gap_exit(gap_name : String):
	print("out ",gap_name)
	if is_gapping == gap_name: 
		gap_combo.append(current_trick["trick"])
		combo_update(gap_name)
	is_in_gap = false

func reset_tricks():
	current_trick = {"trick":"","length":0.0,"duration":0.0,"rotation":0.0}
	potential_trick_score = 0
	potential_combo_score = 0
	potential_trick = {"trick":"","length":0.0,"duration":0.0,"rotation":0.0}
	current_combo = []
	hud_trick_reset.emit()

func new_trick(trick_name:String):
	current_trick = potential_trick.duplicate()
	current_trick["trick"] = trick_name
	hud_trick_activate.emit()

func trick_update(distance,time,angle,potential:bool=false):
	if potential:
		potential_trick["length"] += distance
		potential_trick["duration"] += time
		potential_trick["rotation"] += angle
	else:
		current_trick["length"] += distance
		current_trick["duration"] += time
		current_trick["rotation"] += angle
		if current_trick["trick"] not in ["","Wheelie","Nose Wheelie"]:check_air_rotation()
		potential_trick_score = trick_score(current_trick) * 2 ** current_combo.size()

func combo_update(gap=null):
	var score_to_add : float = potential_trick_score if gap == null else 100
	var trick_to_add : Dictionary = current_trick.duplicate() if gap == null else \
						{"trick":"[color=4a5ef5ff]" + gap + "[/color]","length":0.0,"duration":0.0,"rotation":0.0}
	potential_combo_score += score_to_add
	current_combo.append(trick_to_add)
	if is_in_gap : gap_combo.append(current_trick["trick"])
	hud_combo_update.emit(trick_to_add["trick"])

func check_air_rotation():
	var angle :float = current_trick["rotation"]
	var rotation_name : String
	var name_changed := false
	if angle > PI :
		rotation_name = name_rotation(1+int((angle-PI)/(2*PI))) + "Backflip"
		name_changed = true
	if angle < -PI :
		rotation_name = name_rotation(1+int(-(PI+angle)/(2*PI))) + "Frontflip"
		name_changed = true
	if name_changed and rotation_name != current_trick["trick"]:current_trick["trick"]=rotation_name

func valid_combo():
	for trick_datas in current_combo:
		var trick_to_check :String
		if trick_datas["trick"] not in ["Air","Wheelie","Nose Wheelie"]:trick_to_check = "Air"
		# If wheelie ou air
		else:trick_to_check = trick_datas["trick"]
		check_best_tricks(trick_to_check,trick_datas["length"],trick_datas["duration"])
	current_score += potential_combo_score
	current_boost = clampf(current_boost+min(potential_combo_score,ONE_TIME_QUANTITY),0,BOOST_MAX_QUANTITY)  
	hud_score_update.emit(potential_combo_score)
	# Collectible
	if not is_stored and is_grabbed :
		is_stored = true
		store_collectible.emit()
	# Gap
	if is_gapping == map_data["special_trick"]["spot"]:
		for trick in gap_combo: if map_data["special_trick"]["trick"] in trick : special_trick_done = true
		if special_trick_done:print("Yay")
	is_gapping = ""

func combo_score()-> int:
	var score :int = 0
	var combo_multiplier :int = 0
	for trick_datas in current_combo:
		score += trick_score(trick_datas) * 2 ** combo_multiplier
		combo_multiplier += 1
	return score

func trick_score(trick_datas:Dictionary)->int:
		var trick_base_score :float
		var length_modifier :float = (trick_datas["length"]/tricks_values["length_to_double"])+1
		var duration_modifier :float = (trick_datas["duration"]/tricks_values["duration_to_double"])+1
		# If front ou Back
		if trick_datas["trick"] not in ["Air","Wheelie","Nose Wheelie"]:
			var rotation_modifier :float= points_rotation(1+int((abs(trick_datas["rotation"])-PI)/(2*PI)))
			trick_base_score = tricks_values[trick_datas["trick"].split(" ")[-1]] * rotation_modifier
		# If wheelie ou air
		else:
			trick_base_score = tricks_values[trick_datas["trick"]] 
		return int(trick_base_score * length_modifier * duration_modifier)

func check_best_tricks(trick_name:String,length,duration):
	var is_new_best := false
	if current_profile["best_tricks"][trick_name]["length"] < length:
		current_profile["best_tricks"][trick_name]["length"] = length
		is_new_best = true
	if current_profile["best_tricks"][trick_name]["duration"] < duration:
		current_profile["best_tricks"][trick_name]["duration"] = duration
		is_new_best = true
	if is_new_best:hud_new_best.emit(trick_name)

func end_map():
	avancement = 100
	AudioManager.stop_music()
	AudioManager.play_sfx("fireworks")
	AudioManager.play_music("Victory")
	check_map_objectives()
	check_map_record()
	SaveManager.save_profile(current_profile)

func check_map_objectives():
	var previous_stars : Array = current_profile["current_run"]["finished_maps"].get(current_map,[])
	if 1.0 not in previous_stars and current_score >= map_data["target_score"] : objectives_completed.append(1.0)
	if 2.0 not in previous_stars and race_time < map_data["target_time"] : objectives_completed.append(2.0)
	if 3.0 not in previous_stars and current_score >= map_data["target_score_and_time"][0]\
		and  race_time < map_data["target_score_and_time"][1] : objectives_completed.append(3.0)
	if 4.0 not in previous_stars and is_stored : objectives_completed.append(4.0)
	if 5.0 not in previous_stars and special_trick_done : objectives_completed.append(5.0)
	if 1.0 in previous_stars : objectives_text += " [color=d9db00ff]Beat 10.000 points[/color]\n\n"
	elif 1.0 in objectives_completed : objectives_text += " [rainbow][wave]Beat 10.000 points[/wave][/rainbow]\n\n"
	else : objectives_text += " [color=33333bff]Beat 10.000 points[/color]\n\n"
	if 2.0 in previous_stars : objectives_text += " [color=d9db00ff]Finish under 1:00.000[/color]\n\n"
	elif 2.0 in objectives_completed : objectives_text += " [rainbow][wave]Finish under 1:00.000[/wave][/rainbow]\n\n"
	else : objectives_text += " [color=33333bff]Finish under 1:00.000[/color]\n\n"
	if 3.0 in previous_stars : objectives_text += " [color=d9db00ff]Beat 5.000 point under 1:00.000[/color]\n\n"
	elif 3.0 in objectives_completed : objectives_text += " [rainbow][wave]Beat 5.000 point under 1:00.000[/wave][/rainbow]\n\n"
	else : objectives_text += " [color=33333bff]Beat 5.000 point under 1:00.000[/color]\n\n"
	if 4.0 in previous_stars : objectives_text += " [color=d9db00ff]Collect the Golden Banana[/color]\n\n"
	elif 4.0 in objectives_completed : objectives_text += " [rainbow][wave]Collect the Golden Banana[/wave][/rainbow]\n\n"
	else : objectives_text += " [color=33333bff]Collect the Golden Banana[/color]\n\n"
	if 5.0 in previous_stars : objectives_text += " [color=d9db00ff]Frontflip over the Volcano[/color]\n\n"
	elif 5.0 in objectives_completed : objectives_text += " [rainbow][wave]Frontflip over the Volcano[/wave][/rainbow]\n\n"
	else : objectives_text += " [color=33333bff]Frontflip over the Volcano[/color]\n\n"

func check_map_record():
	new_best_score = false
	new_best_time = false
	previous_best = {"time":"-","score":"-"}
	if current_map in current_profile["map_record"]:
		previous_best = current_profile["map_record"][current_map].duplicate()
		if previous_best["time"] > race_time:
			new_best_time = true
			current_profile["map_record"][current_map]["time"]=race_time
		if previous_best["score"] < current_score:
			new_best_score = true
			current_profile["map_record"][current_map]["score"]=current_score
	else:
		current_profile["map_record"][current_map] = {}
		new_best_time = true
		current_profile["map_record"][current_map]["time"]=race_time
		new_best_score = true
		current_profile["map_record"][current_map]["score"]=current_score

func format_time(t: float) -> String:
	var minutes := int(t/60)
	var seconds := int(t) % 60
	var ms := int((t - int(t)) * 1000)
	return "%02d:%02d.%03d" % [minutes, seconds, ms]

func name_rotation(number_of_rotation:int)->String:
	return rotation_name_and_point[number_of_rotation][0] + " " if number_of_rotation in rotation_name_and_point else "Wow, too much "

func points_rotation(number_of_rotation:int)->float:
	return rotation_name_and_point[number_of_rotation][1] if number_of_rotation in rotation_name_and_point else 10.0
