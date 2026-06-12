extends Node

# Position
var current_world : String
var current_node : String
var node_done : bool

# Unlocks
var map_finished : Array
var worlds_unlocks : Array

func set_world_values():
	var world_position : Dictionary = Global.current_profile["current_run"].get("world_position",
						{"world":"Forest","node":"ForestChairlift","done":false})
	current_world = world_position["world"]
	current_node = world_position["node"]
	node_done = world_position["done"]
	worlds_unlocks = Global.current_profile["current_run"].get("worlds_unlocks",["ForestChairlift"])
	for map in Global.current_profile["current_run"]["finished_maps"]:map_finished.append(map)
