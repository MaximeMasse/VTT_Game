extends Node

# Config
const ECHELLE = 1.7/152
var current_profile_id := 0
var current_profile := {}
var config := {}

# Sélections
var current_map := 2

# HUD
var race_time := 0.0
var contact_sol := true
var vitesse := Vector2.ZERO
var player_position := Vector2.ZERO
var avancement := 0
var taux_compression := 0
var penalty_to_show := false

# Position and cp speed
var current_cp := "start"
var cp_player_speed := Vector2.ZERO
var cp_player_pos := Vector2.ZERO

#Menus
var menu_to_show := "MainMenu"

# Dicos
var dico_maps := {
	1:preload("res://Maps/map_1.tscn"),
	2:preload("res://Maps/map_2.tscn"),
	5:preload("res://Maps/special_map.tscn")
}
var dico_vélo := {
	0:preload("res://Bikes/bike_0.tscn"),
	1:preload("res://Bikes/bike_1.tscn"),
	2:preload("res://Bikes/bike_2.tscn")
}
var dico_avatars := {
	1:preload("res://Avatar/Players/Noir/Avatar.png"),
	2:preload("res://Avatar/Players/Rose/Avatar.png")
}

func get_current_map():
	return dico_maps[current_map]

func get_profile_bike():
	return dico_vélo[int(current_profile["bike_model"])]

func checkpoint_update(cp : String):
	if current_cp != cp:
		current_cp = cp
		cp_player_speed = vitesse
		cp_player_pos = player_position
