extends Node2D

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

func get_level_data():
	return {
		"start": %Start,
		"finish": %Finish,
		"cp1": %Checkpoint_1,
		"cp2": %Checkpoint_2,
		"cp3": %Checkpoint_3,
		"target_score" : 10000,
		"target_time" : 60,
		"target_score_and_time" : [5000,120]
		
		}

signal out_of_bounds
signal finish

func _ready():
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

func _on_crash_zone_body_entered(_body):out_of_bounds.emit()
func _on_finish_body_entered(_body):
	%Finish.activate()
	finish.emit()

func _on_checkpoint_1_body_entered(_body):Global.checkpoint_update("cp1")
func _on_checkpoint_2_body_entered(_body):Global.checkpoint_update("cp2")
func _on_checkpoint_3_body_entered(_body):Global.checkpoint_update("cp3")
