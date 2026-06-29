extends Node2D

@onready var debug_start_speed : float = %DebugStart.debug_start_speed
@onready var debug_start_position : Vector2 = %DebugStart.debug_start_position

@export var platform_texture: Texture2D
@export var platform_width := 50.0
@export var platform_visual_step := 6.0
@export var platform_repeat_px := 50.0

@export var road_texture: Texture2D
@export var road_width := 50.0
@export var road_visual_step := 6.0
@export var road_repeat_px := 50.0

@export var up_offset:= Vector2(0,-27)
@export var up_texture: Texture2D
@export var up_width := 55.0
@export var up_visual_step := 6.0
@export var up_repeat_px := 566.0

@export var down_offset:= Vector2(0,50)
@export var down_texture: Texture2D
@export var down_width := 100.0
@export var down_visual_step := 20.0
@export var down_repeat_px := 566.0

@export var under_offset:= Vector2(0,100)
@export var under_texture: Texture2D
@export var under_width := 200.0
@export var under_visual_step := 20.0
@export var under_repeat_px := 566.0

var bills_values : Dictionary
var map_data : Dictionary

func get_bill_value(id : float)->float:return bills_values[id]

func get_level_data(): return map_data

signal out_of_bounds
signal finish
signal gap_entry
signal gap_exit

func _ready():
	var platform :={
		"Texture":platform_texture,
		"Width":platform_width,
		"Step":platform_visual_step,
		"Repeat":platform_repeat_px
	}
	var road :={
		"Texture":road_texture,
		"Width":road_width,
		"Step":road_visual_step,
		"Repeat":road_repeat_px
	}
	var up :={
		"Offset":up_offset,
		"Texture":up_texture,
		"Width":up_width,
		"Step":up_visual_step,
		"Repeat":up_repeat_px
	}
	var down :={
		"Offset":down_offset,
		"Texture":down_texture,
		"Width":down_width,
		"Step":down_visual_step,
		"Repeat":down_repeat_px
	}
	var under :={
		"Offset":under_offset,
		"Texture":under_texture,
		"Width":under_width,
		"Step":under_visual_step,
		"Repeat":under_repeat_px
	}
	Map.generate_all_collisions(%Paths,%Floors)
	Map.generate_all_visuals(%Paths,%Textures,road,up,down,under)
	Map.generate_platforms_collisions(%PlatformsPaths,%Platforms)
	Map.generate_platforms_visuals(%PlatformsPaths,%PlatformsTextures,platform)
	# Special parts
	for part in %SpecialParts.get_children():part.set_meta("path",part.get_child(0))
	
	# Map data
	map_data = {
		"start": %Start,
		"finish": %Finish,
		"bills": {},
		"cps":{
			"cp1": %Checkpoint_1,
			"cp2": %Checkpoint_2,
			"cp3": %Checkpoint_3,
			},
		"gaps" : ["the 1st Platform","for the Homies","the Last Jump"],
		"target_score" : 10000,
		"target_time" : 60,
		"target_score_and_time" : [5000,120],
		"collectible" : "Shiny Blue Bird",
		"special_trick" : {"trick":"Wheelie","spot":"the 1st Platform"},
		"queen_time":35,
		"queen_score":30000
		}
	
	# Collectible loading
	var dico : Dictionary = Global.current_profile["current_run"]["maps"].get(Global.current_map,{"bills":[],"objectives":[]})
	for bill : Area2D in %Bills.get_children():
		bill.id = float(bill.get_index())
		map_data["bills"][bill.id] = bill.value
		if bill.id in dico["bills"]:
			bill.monitoring = false
			bill.visible = false
	if 4.0 in dico["objectives"]:%Bird.queue_free()

# Zones
func _on_crash_zone_body_entered(_body):out_of_bounds.emit()
func _on_finish_body_entered(_body):
	%Finish.activate()
	finish.emit()

# CPs
func _on_checkpoint_1_body_entered(_body):Global.checkpoint_update("cp1")
func _on_checkpoint_2_body_entered(body):Global.checkpoint_update("cp2")
func _on_checkpoint_3_body_entered(body):Global.checkpoint_update("cp3")

# Collectible
func return_collectible():%Bird.reset()
func store_collectible():%Bird.store()

# Gaps
func _on_st_platform_body_entered(body):gap_entry.emit("the 1st Platform")
func _on_st_platform_2_body_exited(body):gap_exit.emit("the 1st Platform")
func _on_for_the_homies_body_entered(body):
	AudioManager.play_sfx("cheering")
	gap_entry.emit("for the Homies")
func _on_for_the_homies_2_body_exited(body):gap_exit.emit("for the Homies")
func _on_last_jump_body_entered(body):gap_entry.emit("the Last Jump")
func _on_last_jump_2_body_exited(body):gap_exit.emit("the Last Jump")
