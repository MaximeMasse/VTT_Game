extends Node2D

var back_position := Vector2(-18.29,6)
var back_rotation := deg_to_rad(12)
var front_position := Vector2(31,1)
var front_rotation := deg_to_rad(-6)
var leaning_speed := 0.1

func crank_rotate(angle: float):%Cranks.rotate(angle)

func lean(input:float):
	var target_position := Vector2.ZERO 
	var target_rotation := 0.0
	var moving_speed := 0.8
	if input < 0.0:
		target_position = back_position
		target_rotation = back_rotation
		moving_speed = leaning_speed
	elif input > 0.0:
		target_position = front_position
		target_rotation = front_rotation
		moving_speed = leaning_speed
	%Torso.position = lerp(%Torso.position,target_position,moving_speed)
	%Torso.rotation = lerp(%Torso.rotation,target_rotation,moving_speed)
