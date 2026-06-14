extends Node

var current_world_datas : Dictionary

func current(data:String):return current_world_datas[data]
func change(data:String,value):current_world_datas[data] = value

func set_world_values():
	current_world_datas = {"run_finished_maps":[],"finished_maps":[]}
	current_world_datas["world"] = Global.current_day["position"]["world"]
	current_world_datas["node"] = Global.current_day["position"]["node"]
	current_world_datas["course"] = Global.current_day["course"].duplicate()
	current_world_datas["unlocks"] = Global.current_profile["current_run"].get("unlocks",[])
	for map in Global.current_profile["current_run"]["finished_maps"]:current_world_datas["run_finished_maps"].append(map)
	for map in Global.current_profile["map_record"]:current_world_datas["finished_maps"].append(map)

func end_map():profile_update()

func profile_update():
	Global.current_day["position"]["world"] = current("world") 
	Global.current_day["position"]["node"] = current("node")
	Global.current_day["course"] = current("course")
