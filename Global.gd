extends Node

# Config
const ECHELLE = 1.7/152
var current_profile_id := 0
var current_profile := {}
var config := {}

# Sélections
var current_map := 0

# HUD
var race_time := 0.0
var penalty_to_show := false
var contact_sol := true
var vitesse := Vector2.ZERO
var player_position := Vector2.ZERO
var player_rotation := 0.0
var avancement := 0
var taux_compression := 0

#Tricks
var current_trick := {}
var potential_trick := {}
var current_combo :Array[Dictionary]= []

# CP position and speed
var current_cp := "start"
var cp_player_speed := Vector2.ZERO
var cp_player_pos := Vector2.ZERO

#Menus
var menu_to_show := "MainMenu"

# Dicos
var dico_maps := {
	0:"res://Maps/map_0.tscn",
	1:"res://Maps/map_1.tscn",
	2:"res://Maps/map_2.tscn",
	3:"res://Maps/map_3.tscn",
	5:"res://Maps/special_map.tscn"
}
var dico_vélo := {
	0:preload("res://Bikes/bike_0.tscn"),
	1:preload("res://Bikes/bike_1.tscn"),
	2:preload("res://Bikes/bike_2.tscn"),
}
var dico_avatars := {
	1:preload("res://Avatar/Players/Noir/Avatar.png"),
	2:preload("res://Avatar/Players/Rose/Avatar.png")
}

signal hud_trick_reset
signal hud_trick_activate
signal hud_combo_update
signal new_best


func get_current_map():
	return dico_maps[current_map]

func get_profile_bike():
	return dico_vélo[int(current_profile["bike_model"])]

func checkpoint_update(cp : String):
	if current_cp != cp:
		current_cp = cp
		cp_player_speed = vitesse
		cp_player_pos = player_position

func reset_tricks():
	current_trick = {"trick":"","length":0.0,"duration":0.0,"rotation":0.0}
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

func combo_update():
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
	print("combo validé :")
	for trick in current_combo:print(trick)

func name_rotation(number_of_rotation:int)->String:
	var naming := {1:"",2:"Double",3:"Triple"}
	return naming[number_of_rotation]

#func valid_trick():
	#if current_trick != "":
		#if current_profile["best_tricks"][current_trick]["length"] < trick_datas.x:
			#current_profile["best_tricks"][current_trick]["length"] = trick_datas.x
			#new_best.emit()
		#if current_profile["best_tricks"][current_trick]["duration"] < trick_datas.y:
			#current_profile["best_tricks"][current_trick]["duration"] = trick_datas.y
			#new_best.emit()
