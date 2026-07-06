extends Node

var datas : Dictionary = {
	"ACCELERATION":{
		"values":[5000.0,6000.0,7000.0,8000.0,9000.0,10000.0],
		"unlock_lvl":[0,1,5,9,13,17],
		"unlock_cost":[0,100,200,500,1000]
	},
	"AIR_ROTATION_CONTROL":{
		"values":[3.0,3.5,4.0,5.0,6.0,20.0],
		"unlock_lvl":[0,2,6,10,14,18],
		"unlock_cost":[0,100,200,500,1000]
	},
	"GROUND_ROTATION_CONTROL":{
		"values":[10.0,8.0,6.0,4.0,3.0,2.0],
		"unlock_lvl":[0,3,7,11,15,19],
		"unlock_cost":[0,100,200,500,1000]
	},
	"FORCE_SAUT":{
		"values":[100.0,110.0,120.0,130.0,140.0,150.0],
		"unlock_lvl":[0,4,8,12,16,20],
		"unlock_cost":[0,100,200,500,1000]
	},
}

func get_upgrade_tier(upgrade:String,value:float):return datas[upgrade]["values"].find(value)
func get_upgrade_tier_data(upgrade:String,tier:float,data:String):return datas[upgrade][data][tier]
