extends Node

# Position
var current_world : String
var current_node : String
var node_done : bool

# Unlocks
var finished_maps : Array
var run_finished_maps : Array
var day_finished_maps : Array
var worlds_unlocks : Array

func set_world_values():
	current_world = Global.current_day["position"]["world"]
	current_node = Global.current_day["position"]["node"]
	node_done = Global.current_day["position"]["done"]
	worlds_unlocks = Global.current_profile["current_run"].get("worlds_unlocks",["ForestChairlift"])
	for map in Global.current_profile["current_run"]["finished_maps"]:run_finished_maps.append(map)
	for map in Global.current_profile["map_record"]:finished_maps.append(map)

func end_map():
	node_done = true
	profile_update()

func profile_update():
	Global.current_profile["current_run"]["world_position"] = {
		"world":current_world,"node":current_node,"done":node_done
		}
	Global.current_profile["current_run"]["finished_maps"] = run_finished_maps
	Global.current_profile["map_record"] = finished_maps
