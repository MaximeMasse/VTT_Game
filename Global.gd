extends Node

# Config
const ECHELLE = 1.7/152
#var current_profile_id := 0
var current_profile := {}
var config := {}

# Sélections
var current_map := "1"

# HUD
var race_time := 0.0
var penalty_to_show := false
var contact_sol := true
var vitesse := Vector2.ZERO
var player_position := Vector2.ZERO
var player_rotation := 0.0
var avancement := 0
var taux_compression :float= 0
var current_score :float

# Floors
var floor_is : int
var bike_ground_distance : float
var ground_distance : float

#Tricks
var current_trick := {}
var potential_trick_score :int
var potential_combo_score :int
var potential_trick := {}
var current_combo :Array[Dictionary]= []

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

# End map
var new_best_time :bool
var new_best_score :bool
var previous_best :Dictionary

#Menus
var menu_to_show := "MainMenu"

var rotation_name_and_point := {1:["",1.0],2:["Double",2.0],3:["Triple",3.0],
							4:["Quadruple",4.0],5:["Quintuple",5.0],6:["Sextuple",6.0],7:["Septuple",7.0]}
var tricks_values : Dictionary = {
	"":0,
	"length_to_double":10,
	"duration_to_double":3,
	"Air":50,
	"Wheelie":100,
	"Nose Wheelie":150,
	"Backflip":100,
	"Frontflip":150
}

# Dicos
var dico_maps := {
	"0":"res://Maps/map_0.tscn",
	"1":"res://Maps/map_1.tscn",
	"2":"res://Maps/map_2.tscn",
	"3":"res://Maps/map_3.tscn",
	"5":"res://Maps/special_map.tscn"
}
var dico_vélo := {
	0:"res://Bikes/bike_0.tscn",
	1:"res://Bikes/bike_1.tscn",
	2:"res://Bikes/bike_2.tscn",
}
var dico_avatars := {
	1:preload("res://Avatar/Players/Base/Woman.png"),
	2:preload("res://Avatar/Players/Base/Man.png"),
	3:preload("res://Avatar/Players/Base/Girl.png"),
	4:preload("res://Avatar/Players/Base/Cat.png")
}
var dico_scenes :={
	"Main_Game":"res://game.tscn"
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

func get_current_map():
	return dico_maps[current_map]

func get_profile_bike()->String:return dico_vélo[int(current_profile["bike_model"])]

func checkpoint_update(cp : String):
	if current_cp != cp:
		current_cp = cp
		cp_player_speed = vitesse
		cp_player_pos = player_position
		cp_player_score = current_score
		cp_player_boost = current_boost

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

func combo_update():
	potential_combo_score += potential_trick_score
	current_combo.append(current_trick.duplicate())
	hud_combo_update.emit(current_trick["trick"])

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
	check_map_record()
	SaveManager.save_profile(current_profile)

func check_map_record():
	new_best_score = false
	new_best_time = false
	previous_best = {"time":"-","score":"-"}
	if current_map in current_profile["map_record"]:
		previous_best = current_profile["map_record"][current_map].duplicate()
		if previous_best["time"] > Global.race_time:
			new_best_time = true
			current_profile["map_record"][current_map]["time"]=Global.race_time
		if previous_best["score"] < Global.current_score:
			new_best_score = true
			current_profile["map_record"][current_map]["score"]=Global.current_score
	else:
		current_profile["map_record"][current_map] = {}
		new_best_time = true
		current_profile["map_record"][current_map]["time"]=Global.race_time
		new_best_score = true
		current_profile["map_record"][current_map]["score"]=Global.current_score

func format_time(t: float) -> String:
	var minutes := int(t) / 60
	var seconds := int(t) % 60
	var ms := int((t - int(t)) * 1000)
	return "%02d:%02d.%03d" % [minutes, seconds, ms]

func name_rotation(number_of_rotation:int)->String:
	return rotation_name_and_point[number_of_rotation][0] + " " if number_of_rotation in rotation_name_and_point else "Wow, too much "

func points_rotation(number_of_rotation:int)->float:
	return rotation_name_and_point[number_of_rotation][1] if number_of_rotation in rotation_name_and_point else 10.0
