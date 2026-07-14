extends Node

const bosses_names : Array = ["Adriano","Boss 2","Boss 3","Boss 4"]

const bosses_bikes :Dictionary = {
	"Bike 1":{"name":bosses_names[0],"cost":1},
	"Bike 2":{"name":bosses_names[1],"cost":2},
	"Bike 3":{"name":bosses_names[2],"cost":5},
	"Bike 4":{"name":bosses_names[3],"cost":10}
}

const datas : Dictionary = {
	"ACCELERATION":{
		"values":[5000.0,6000.0,7000.0,8000.0,9000.0,10000.0],
		"unlock_lvl":[0,1,5,9,13,17],
		"unlock_cost":[0,100,200,500,1000]
	},
	"AIR BALANCE":{
		"values":[3.0,3.5,4.0,5.0,6.0,20.0],
		"unlock_lvl":[0,2,6,10,14,18],
		"unlock_cost":[0,100,200,500,1000]
	},
	"GROUND BALANCE":{
		"values":[10.0,8.0,6.0,4.0,3.0,2.0],
		"unlock_lvl":[0,3,7,11,15,19],
		"unlock_cost":[0,100,200,500,1000]
	},
	"JUMP POWER":{
		"values":[100.0,110.0,120.0,130.0,140.0,150.0],
		"unlock_lvl":[0,4,8,12,16,20],
		"unlock_cost":[0,100,200,500,1000]
	},
	"Bike":{
		"AIR_SPEED_CONTROL":[0.0,2.5,5.0,7.5,10.0],
		"BALANCE_CONTROL":[10.0,25.0,50.0,75.0,100.0],
		"CM_OFFSET":[[0.0,0.0],[1.3,5.0],[2.6,10.0],[3.9,15.0],[5.2,25.0]],
		"FORCE_FREINS":[75.0,90.0,110.0,130.0,150.0],
		"GREEN_TIME":[1.0,0.8,0.6,0.4,0.2],
		"SWEET_SPOT":[0.1,0.2,0.3,0.4,0.5]
	},
	"Protections":{
		"cost":[1,2,5,10],
		"names":["Elbow Pad","Knee Pad","Chest Plate","Helmet"],
		"RESPAWN_HP_PENALTY": [5,5,5,5],
		"RESPAWN_TIME_PENALTY": [1,1,1,1]
	},
	"Beds":{
		0:{"texture":"res://Images/Menus/Shops/Trailer/Inside_0.png","unlock_lvl":0,"healing":25,"cost":0},
		1:{"texture":"res://Images/Menus/Shops/Trailer/Inside_1.png","unlock_lvl":5,"healing":50,"cost":1},
		2:{"texture":"res://Images/Menus/Shops/Trailer/Inside_2.png","unlock_lvl":10,"healing":75,"cost":5},
		3:{"texture":"res://Images/Menus/Shops/Trailer/Inside_3.png","unlock_lvl":15,"healing":100,"cost":10}
	},
	"Passes":{
		"None":{"price":0,"acces":[]},
		"Forest":{"price":100,"acces":["Forest"]},
		"Desert":{"price":200,"acces":["Forest","Desert"]},
		"Icy":{"price":500,"acces":["Forest","Desert","Icy"]},
		"Tropical":{"price":1000,"acces":["Forest","Desert","Icy","Tropical"]}
	}
}

const ACHIEVEMENTS := {
	"finished_map": {
		"name": "Map Finisher",
		"description": "Finish x Map for the 1st Time",
		"levels": [1,4,8,13,20]
	},
	"stars": {
		"name": "Stars Reacher",
		"description": "Reach x Stars",
		"levels": [3,10,25,40,60]
	},
	"crowns": {
		"name": "Crowns Earner",
		"description": "Unlock x Crowns",
		"levels": [1,10,25,40,60]
	},
	"days": {
		"name": "Days survived",
		"description": "Survive x Days in a Single Run",
		"levels": [1,4,8,13,20]
	},
	"queen_obj": {
		"name": "Queen Beater",
		"description": "Beat x Queen Time or Score Objectives",
		"levels": [1,5,10,16,24]
	},
	"played_day": {
		"name": "Player",
		"description": "Play x days in Total",
		"levels": [1,5,20,50,100]
	},
	"money_gained": {
		"name": "Money Earner",
		"description": "Gain x RogueBucks in Total",
		"levels": [500,2000,5000,10000,20000]
	},
	"map_gaps_done": {
		"name": "Gaps Finisher",
		"description": "Land the 3 Differents Gaps on x Maps",
		"levels": [1,3,6,9,12]
	},
	"five_stars": {
		"name": "Objectives Finisher",
		"description": "Get 5 Stars on x Maps",
		"levels": [1,3,6,9,12]
	},
	"completed": {
		"name": "Map Clearer",
		"description": "Get 5 Crowns on x Maps",
		"levels": [1,3,6,9,12]
	}
}

const XP_GAIN := [10,25,50,100,150]
const XP_LEVELS := [10,20,30,40,50,60,70,90,110,130,150,170,190,210,230,250,280,330,410,520]

signal new_achievement
signal achievement_display_finished
signal xp_up
signal level_up

func check_achievements():
	var current_achievements : Dictionary = Global.current_profile.get("achievements",{})
	var current_values : Dictionary = get_map_datas()
	for ach in ["days","stars"]:current_values[ach]=Global.current_profile["current_run"][ach]
	for ach in ["played_day","money_gained"]:current_values[ach]=Global.current_profile[ach]
	for achievement in ACHIEVEMENTS:
		var achievement_level : int = int(current_achievements.get(achievement,0))
		var current_level : int = get_achievement_value_level(achievement,current_values[achievement])
		while current_level > achievement_level:
			new_achievement.emit(ACHIEVEMENTS[achievement],achievement_level)
			await achievement_display_finished
			await gain_xp(achievement_level)
			achievement_level += 1
		current_achievements[achievement] = achievement_level
	Global.current_profile["achievements"] = current_achievements.duplicate()
	SaveManager.save_profile(Global.current_profile)

func gain_xp(level:int):
	var xp_gain : float = XP_GAIN[level]
	var waiting_time : float = 1/xp_gain
	while xp_gain > 0:
		Global.current_profile["xp"] += 1
		xp_up.emit()
		if Global.current_profile["xp"] == XP_LEVELS[Global.current_profile["lvl"]]:
			Global.current_profile["lvl"] += 1
			Global.current_profile["xp"] = 0
			level_up.emit()
		xp_gain -= 1
		await get_tree().create_timer(waiting_time).timeout

func get_map_datas()-> Dictionary:
	var map_records : Dictionary = Global.current_profile["map_records"]
	var finished_map : int = map_records.size()
	var crowns : int = 0
	var queen_obj : int = 0
	var map_gaps_done : int = 0
	var five_stars : int = 0
	var completed : int = 0
	for map in map_records:
		var map_datas : Dictionary = map_records[map]
		crowns += int(map_datas["crowns_unlocked"])
		queen_obj += 1 if map_datas["queen_time_beaten"] else 0
		queen_obj += 1 if map_datas["queen_score_beaten"] else 0
		map_gaps_done += 1 if map_datas["gaps_done"] else 0
		five_stars += 1 if map_datas["objectives_done"] else 0
		completed += 1 if int(map_datas["crowns_unlocked"]) == 5 else 0
	return {"finished_map":finished_map,"crowns":crowns,"queen_obj":queen_obj,
		"map_gaps_done":map_gaps_done,"five_stars":five_stars,"completed":completed}

func get_achievement_value_level(achievement:String,value:float)->int:
	var index : int = 0
	for step in ACHIEVEMENTS[achievement]["levels"]:
		if value < step : return index
		else:index += 1
	return index

func get_upgrade_tier(upgrade:String,value:float):return datas[upgrade]["values"].find(value)
func get_upgrade_tier_data(upgrade:String,tier:float,data:String):return datas[upgrade][data][tier]

func get_current_bike()->String:
	var current_stat : float = Global.current_profile["stats"]["AIR_SPEED_CONTROL"]
	return "Bike " + str(datas["Bike"]["AIR_SPEED_CONTROL"].find(current_stat))
func get_bike_boss_data(bike,data):return bosses_bikes[bike][data]

func get_protection_boss_name(protection):return bosses_names[datas["Protections"]["names"].find(protection)]
func get_protection_data(protection,data):return datas["Protections"][data][datas["Protections"]["names"].find(protection)]

func get_bed_data(data:String,bed=null):
	if bed == null:
		bed = 0
		for unlock:String in Global.current_profile["permanent_unlocks"]:
			if "Bed" in unlock:bed = max(bed,int(unlock.split(" ")[1]))
	return datas["Beds"][bed][data]

func pass_grants_acces_to(spot:String):
	for world in datas["Passes"][Global.current_profile["current_run"]["current_day"]["pass"]]["acces"]:
		if world in spot: return true 
	return false
