extends Node

const PROFILE_DIR := "user://profiles/"
const CONFIG_PATH := "user://config.json"

func _ready():
	DirAccess.make_dir_recursive_absolute(PROFILE_DIR)
	load_config()

func generate_profile_id() -> int:
	Global.config["profils_existants"] = int(Global.config["profils_existants"] + 1)
	return int(Global.config["profils_existants"])
	
func get_profile_path(profile_id: int) -> String:
	return PROFILE_DIR + "profile_%d.json" % profile_id
	
func profile_exists(profile_id: int) -> bool:
	return FileAccess.file_exists(get_profile_path(profile_id))
	
func create_profile(player_name: String, avatar_id: int) -> Dictionary:
	var id := generate_profile_id()
	var profile := {
		"id": id,
		"name": player_name,
		"avatar": avatar_id,
		"bike_model": 1, 
		"state": "tuto",
		"stats": {
			"ACCÉLÉRATION": 5000.0,
			"AIR_ROTATION_CONTROL": 2.0,
			"AIR_SPEED_CONTROL": 0.0,
			"AV_CONTROL": 10.0,
			"BALANCE_CONTROL": 10.0,
			"CM_OFFSET": [
				0.0,
				0.0
			],
			"COUPLE_CADRE_AIR": 400000.0,
			"COUPLE_CADRE_SOL": 1700000.0,
			"FORCE_FREINS": 75.0,
			"FORCE_SAUT": 100.0,
			"FRICTION": 150.0,
			"GREEN_TIME": 1.0,
			"SWEET_SPOT": 0.1
		},
		"boost": {
			"BOOST_ACCELERATION": 5000.0,
			"BOOST_CONSUMPTION": 2500.0,
			"BOOST_MAX_QUANTITY": 5000.0,
			"ONE_TIME_RATIO": 5.0
		},
		"upgrades": {
			"RESPAWN_PENALTY" : 5.0
		},
		"best_tricks":{
			"Air": {"length":0.0,"duration":0.0},
			"Wheelie": {"length":0.0,"duration":0.0},
			"Nose Wheelie": {"length":0.0,"duration":0.0}
		},
		"best_combo": [],
		"map_record": {}
	}
	save_profile(profile)
	set_current_profile(profile)
	return profile

func save_profile(profile: Dictionary) -> void:
	var path := get_profile_path(profile["id"])
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(profile, "\t"))

func load_profile(profile_id: int) -> Dictionary:
	var path := get_profile_path(profile_id)

	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("Profil corrompu : ",profile_id)
		return {}
	return json.data

func set_current_profile(profile: Dictionary) -> void:
	Global.current_profile = profile
	#Global.current_profile_id = int(profile["id"])

	Global.config["profil_en_cours"] = int(profile["id"])
	save_config()

func delete_profile(slot: int) -> void:
	if profile_exists(slot):
		DirAccess.remove_absolute(get_profile_path(slot))
		
func load_config() -> Dictionary:
	if not FileAccess.file_exists(CONFIG_PATH):
		Global.config = {
			"profil_en_cours": 0,
			"profils_existants": 0,
			"music_volume": 0.7,
			"sfx_volume": 0.9,
			"ui_volume": 0.8
		}
		save_config()
		return Global.config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	var text := file.get_as_text()
	var json := JSON.new()
	if json.parse(text) != OK:
		Global.config = {}
	else:
		Global.config = json.data
	return Global.config

func save_config() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(Global.config, "\t"))
