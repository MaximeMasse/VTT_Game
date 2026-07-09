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
	}
}

const ACHIEVEMENTS := {
	"finish_maps": {
		"name": "Finisher",
		"description": "Finir des maps",
		"stat": "maps_finished",
		"levels": [1,2,5,10,20]
	}
}

const XP_GAIN := [10,25,50,100,150]
const XP_LEVELS := [10,20,30,40,50,60,70,90,110,130,150,170,190,210,230,250,280,330,410,520]

func get_upgrade_tier(upgrade:String,value:float):return datas[upgrade]["values"].find(value)
func get_upgrade_tier_data(upgrade:String,tier:float,data:String):return datas[upgrade][data][tier]

func get_current_bike()->String:
	var current_stat : float = Global.current_profile["stats"]["AIR_SPEED_CONTROL"]
	return "Bike " + str(datas["Bike"]["AIR_SPEED_CONTROL"].find(current_stat))
func get_bike_boss_data(bike,data):return bosses_bikes[bike][data]

func get_protection_boss_name(protection):return bosses_names[datas["Protections"]["names"].find(protection)]
func get_protection_data(protection,data):return datas["Protections"][data][datas["Protections"]["names"].find(protection)]
