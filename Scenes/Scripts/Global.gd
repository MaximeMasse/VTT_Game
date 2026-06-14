extends Node

# Config
var debug : bool = true
const ECHELLE = 1.7/152
var current_profile := {}
var config := {}

# Map
var current_map := "0"
var map_data : Dictionary

# HUD
var race_time : float
var money_catched : float
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
var is_in_gap : String
var gap_combo : Dictionary
var special_trick_done : bool
var gaps_done : Dictionary
var gaps_already_fulled : bool
var gaps_fulled : bool
var gaps_done_data : Dictionary
# Money
var bills_catched : Array
var bills_already_fulled : bool
var bills_fulled : bool
var bills_done_data : Dictionary
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
var previous_map_record :Dictionary
var previous_obj_and_bills : Dictionary
var objectives_already_done : bool
var objectives_done : bool
var objectives_completed : Array
var objectives_text : String
var queen_time_already_beaten : bool
var queen_time_beaten : bool
var queen_score_already_beaten : bool
var queen_score_beaten : bool
var crowns_unlocked : int

# Day
var current_day : Dictionary

#Menus
var menu_to_show := "MainMenu"

var rotation_name_and_point := {1:["",1.0],2:["Double ",2.0],3:["Triple ",3.0],
							4:["Quadruple ",4.0],5:["Quintuple ",5.0],6:["Sextuple ",6.0],7:["Septuple ",7.0]}
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
	"Tuto_Game":"res://Scenes/Games/tuto_game.tscn",
	"Forest_Map":"res://Scenes/Worlds/forest_map.tscn"
}

signal hud_trick_reset
signal hud_trick_activate
signal hud_combo_update
signal hud_score_update
signal hud_new_best
signal hud_cp_update

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

func get_cp_names_and_ratio() -> Dictionary :
	var cps_markers : Dictionary
	for cp in map_data["cps"]:cps_markers[cp] = map_data["cps"][cp].global_position.x/map_data["finish"].global_position.x
	return cps_markers

func new_day():
	current_day = {"course":[],"position":{"world":"Forest","node":"ForestChairlift"},"money":0,"stars":0,"crowns":0}

func set_start_values():
	is_grabbed = false
	is_stored = false
	is_in_gap = ""
	gap_combo = {}
	special_trick_done = false
	current_profile["best_tricks"] = current_profile.get("best_tricks",{
			"Air": {"length":0.0,"duration":0.0},
			"Wheelie": {"length":0.0,"duration":0.0},
			"Nose Wheelie": {"length":0.0,"duration":0.0}
			})
	previous_obj_and_bills = current_profile["current_run"]["finished_maps"]\
	.get(current_map,{"objectives":[],"bills":[],"gaps":{}})
	objectives_completed = []
	objectives_text = ""
	money_catched = 0
	bills_catched = []
	previous_map_record = current_profile["map_record"]\
	.get(current_map,{"crowns_unlocked":0,"queen_time_beaten":false,"queen_score_beaten":false\
	,"score":"-","time":"-","objectives_done":false,"bills_caught":false,"gaps_done":false,"gaps_discovered":[]})
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
	is_in_gap = ""
	gap_combo = {}

func checkpoint_update(cp : String,min_speed : float = 0):
	if current_cp != cp:
		current_cp = cp
		cp_player_speed =  min_speed * vitesse.normalized() if vitesse.length() < min_speed else vitesse
		cp_player_pos = player_position
		cp_player_score = current_score
		cp_player_boost = current_boost
		hud_cp_update.emit(cp)

func gap_entry(gap_name : String):
	if current_trick["trick"] != "" or not contact_sol:
		is_in_gap = gap_name
		gap_combo[gap_name] = []

func gap_exit(gap_name : String):
	if is_in_gap == gap_name: 
		gap_combo[gap_name].append(current_trick["trick"])
		combo_update(gap_name)
		AudioManager.play_sfx("gap")
		# Records
		# if gap not discovered
		if not previous_obj_and_bills["gaps"].has(gap_name) and not gaps_done.has(gap_name):gaps_done[gap_name] = false
	is_in_gap = ""

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
	if current_combo.size() > 0:AudioManager.play_sfx("combo" + str(current_combo.size()))

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
		potential_trick_score = int(trick_score(current_trick) * 2 ** current_combo.size())

func combo_update(gap=null):
	var score_to_add : float = potential_trick_score if gap == null else 100
	var trick_to_add : Dictionary = current_trick.duplicate() if gap == null else \
						{"trick":"[color=4a5ef5ff]" + gap + "[/color]","length":0.0,"duration":0.0,"rotation":0.0}
	potential_combo_score += int(score_to_add)
	current_combo.append(trick_to_add)
	if gap == null and is_in_gap != "" : gap_combo[is_in_gap].append(current_trick["trick"])
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
	if name_changed and rotation_name != current_trick["trick"]: current_trick["trick"] = rotation_name

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
	for gap in gap_combo:
		gaps_done[gap] = true
		if gap == map_data["special_trick"]["spot"] and not special_trick_done and \
		map_data["special_trick"]["trick"] in gap_combo[gap]:
			special_trick_done = true
			AudioManager.play_sfx("special_trick")
	gap_combo = {}
	is_in_gap = ""

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
	check_gaps()
	check_bills()
	World.end_map()
	profile_update()
	SaveManager.save_profile(current_profile)

func check_map_objectives():
	objectives_already_done = previous_map_record["objectives_done"]
	var previous_stars : Array = previous_obj_and_bills["objectives"]
	var target_score : float = map_data["target_score"]
	var target_time : float = map_data["target_time"]
	var tst_score : float = map_data["target_score_and_time"][0]
	var tst_time : float = map_data["target_score_and_time"][1]
	var special_trick : String = map_data["special_trick"]["trick"]+ " " + map_data["special_trick"]["spot"]
	if 1.0 not in previous_stars and current_score >= target_score : objectives_completed.append(1.0)
	if 2.0 not in previous_stars and race_time < target_time : objectives_completed.append(2.0)
	if 3.0 not in previous_stars and current_score >= tst_score and  race_time < tst_time : objectives_completed.append(3.0)
	if 4.0 not in previous_stars and is_stored : objectives_completed.append(4.0)
	if 5.0 not in previous_stars and special_trick_done : objectives_completed.append(5.0)
	if 1.0 in previous_stars : objectives_text += " [color=d9db00ff]Beat " + format_number(target_score) + " points[/color]\n\n"
	elif 1.0 in objectives_completed : objectives_text += " [rainbow][wave]Beat " + format_number(target_score) + " points[/wave][/rainbow]\n\n"
	else : objectives_text += " [color=33333bff]Beat " + format_number(target_score) + " points[/color]\n\n"
	if 2.0 in previous_stars : objectives_text += " [color=d9db00ff]Finish under " + format_time(target_time) + "[/color]\n\n"
	elif 2.0 in objectives_completed : objectives_text += " [rainbow][wave]Finish under " + format_time(target_time) + "[/wave][/rainbow]\n\n"
	else : objectives_text += " [color=33333bff]Finish under " + format_time(target_time) + "[/color]\n\n"
	if 3.0 in previous_stars : objectives_text += " [color=d9db00ff]Beat " + format_number(tst_score) + " point under " + format_time(tst_time) + "[/color]\n\n"
	elif 3.0 in objectives_completed : objectives_text += " [rainbow][wave]Beat " + format_number(tst_score) + " point under " + format_time(tst_time) + "[/wave][/rainbow]\n\n"
	else : objectives_text += " [color=33333bff]Beat " + format_number(tst_score) + " point under " + format_time(tst_time) + "[/color]\n\n"
	if 4.0 in previous_stars : objectives_text += " [color=d9db00ff]Collect the " + map_data["collectible"] + "[/color]\n\n"
	elif 4.0 in objectives_completed : objectives_text += " [rainbow][wave]Collect the " + map_data["collectible"] + "[/wave][/rainbow]\n\n"
	else : objectives_text += " [color=33333bff]Collect the " + map_data["collectible"] + "[/color]\n\n"
	if 5.0 in previous_stars : objectives_text += " [color=d9db00ff]" + special_trick + "[/color]\n\n"
	elif 5.0 in objectives_completed : objectives_text += " [rainbow][wave]" + special_trick + "[/wave][/rainbow]\n\n"
	else : objectives_text += " [color=33333bff]" + special_trick + "[/color]\n\n"
	objectives_done = previous_obj_and_bills["objectives"].size() + objectives_completed.size() == 5
	

func check_gaps():
	gaps_already_fulled = previous_map_record["gaps_done"]
	gaps_done_data["done"] = 0
	gaps_done_data["size"] = map_data["gaps"].size()
	for gap in previous_obj_and_bills["gaps"]:if previous_obj_and_bills["gaps"][gap]:gaps_done[gap] = true
	for i in map_data["gaps"].size():
		if map_data["gaps"][i] not in previous_map_record["gaps_discovered"] and not gaps_done.has(map_data["gaps"][i]):
			gaps_done_data["gap"+str(i+1)] = " ????????????????????"
			gaps_done_data["check"+str(i+1)] = "unknow"
		else:
			gaps_done_data["gap"+str(i+1)] = " " + map_data["gaps"][i].substr(0, 1).to_upper() + map_data["gaps"][i].substr(1)
			if gaps_done.get(map_data["gaps"][i],false) :
				gaps_done_data["check"+str(i+1)] = "valid"
				gaps_done_data["done"] += 1
			else:gaps_done_data["check"+str(i+1)] = "empty"
	gaps_fulled = int(gaps_done_data["done"]) == map_data["gaps"].size()
	if gaps_already_fulled : gaps_done_data["crown_anim"] = "RESET"
	elif gaps_fulled:gaps_done_data["crown_anim"] = "Spin"
	else : gaps_done_data["crown_anim"] = "Locked"
	
func check_bills():
	bills_already_fulled = previous_map_record["bills_caught"]
	bills_done_data["size"] = map_data["bills"].size()
	bills_done_data["number_per_value_total"] = {50:0,100:0,200:0,500:0}
	bills_done_data["number_per_value_caught"] = {50:0,100:0,200:0,500:0}
	for bill in map_data["bills"]:bills_done_data["number_per_value_total"][map_data["bills"][bill]] += 1
	for bill in previous_obj_and_bills["bills"]:bills_catched.append(bill)
	for bill in bills_catched:bills_done_data["number_per_value_caught"][map_data["bills"][bill]] += 1
	bills_done_data["done"] = bills_catched.size()
	bills_fulled = bills_done_data["done"] == bills_done_data["size"]
	if bills_already_fulled : bills_done_data["crown_anim"] = "RESET"
	elif bills_fulled:bills_done_data["crown_anim"] = "Spin"
	else : bills_done_data["crown_anim"] = "Locked"

func check_map_record():
	new_best_score = false
	new_best_time = false
	queen_time_already_beaten = false
	queen_time_beaten = false
	queen_score_already_beaten = false
	queen_score_beaten = false
	if previous_map_record["time"] is float :
		if previous_map_record["time"] > race_time:
			new_best_time = true
		if previous_map_record["score"] < current_score:
			new_best_score = true
		if previous_map_record["time"] < map_data["queen_time"]:queen_time_already_beaten = true
		if previous_map_record["score"] > map_data["queen_score"]:queen_score_already_beaten = true
	else:
		new_best_time = true
		new_best_score = true
	if race_time < map_data["queen_time"]:queen_time_beaten = true
	if current_score > map_data["queen_score"]:queen_score_beaten = true

func profile_update():
	var new_map_data := previous_obj_and_bills.duplicate()
	var new_map_record := previous_map_record.duplicate()
	# Map records
	if new_best_time:new_map_record["time"] = race_time
	if new_best_score:new_map_record["score"] = current_score
	new_map_record["queen_time_beaten"] = queen_time_already_beaten or queen_time_beaten
	new_map_record["queen_score_beaten"] = queen_score_already_beaten or queen_score_beaten
	# Money
	current_profile["current_run"]["money"] += money_catched
	money_catched = 0
	new_map_data["bills"] = bills_catched
	new_map_record["bills_caught"] = bills_already_fulled or bills_fulled
	# Stars
	current_profile["current_run"]["stars"] += objectives_completed.size()
	new_map_data["objectives"].append_array(objectives_completed)
	new_map_record["objectives_done"] = objectives_already_done or objectives_done
	# Gaps
	new_map_record["gaps_done"] = gaps_already_fulled or gaps_fulled
	for gap in gaps_done:
		new_map_data["gaps"][gap] = gaps_done[gap]
		if gap not in new_map_record["gaps_discovered"]:new_map_record["gaps_discovered"].append(gap)
	# Crowns
	var new_crowns := 0
	if not objectives_already_done and objectives_done: new_crowns += 1
	if not queen_time_already_beaten and queen_time_beaten: new_crowns += 1
	if not queen_score_already_beaten and queen_score_beaten: new_crowns += 1
	if not bills_already_fulled and bills_fulled : new_crowns += 1
	if not gaps_already_fulled and gaps_fulled : new_crowns += 1
	current_profile["crowns"] += new_crowns
	var crowns : int = 0 
	for data in new_map_record: if new_map_record[data] is bool and new_map_record[data] :crowns += 1
	new_map_record["crowns_unlocked"] = crowns
	# Profile update
	current_profile["current_run"]["finished_maps"][current_map] = new_map_data
	current_profile["map_record"][current_map] = new_map_record
	current_profile["current_run"]["current_day"] = current_day

func format_time(t: float) -> String:
	var minutes := int(t/60)
	var seconds := int(t) % 60
	var ms := int((t - int(t)) * 1000)
	return "%02d:%02d.%03d" % [minutes, seconds, ms]

func format_number(value: float) -> String:
	var s := str(int(value))
	for i in range(s.length() - 3, 0, -3):s = s.insert(i, ".")
	return s

func name_rotation(number_of_rotation:int)->String:
	return rotation_name_and_point[number_of_rotation][0] if number_of_rotation in rotation_name_and_point else "Wow, too much "

func points_rotation(number_of_rotation:int)->float:
	return rotation_name_and_point[number_of_rotation][1] if number_of_rotation in rotation_name_and_point else 10.0
