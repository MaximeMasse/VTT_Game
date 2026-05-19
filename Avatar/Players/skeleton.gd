extends Node2D

var rest_position := Vector2(-6.565,4.63)
var rest_rotation := deg_to_rad(0)
var back_position := Vector2(-26,19)
var back_rotation := deg_to_rad(5.5)
var front_position := Vector2(27,-2)
var front_rotation := deg_to_rad(23.5)
var leaning_speed := 0.1
var leaning_return_speed := 0.8
var low_position := Vector2(-29,28)
var low_rotation := deg_to_rad(7)
var high_position := Vector2(8,-1)
var high_rotation := deg_to_rad(-9.5)
var jumping_speed := 0.8

var is_jumping : bool

func crank_rotate(angle: float):
	%Cranks.rotate(angle)

func lean(input:float):
	if is_jumping:return
	var target_position := rest_position
	var target_rotation := rest_rotation
	var moving_speed := leaning_return_speed
	if input < 0.0:
		target_position = back_position
		target_rotation = back_rotation
		moving_speed = leaning_speed
	elif input > 0.0:
		target_position = front_position
		target_rotation = front_rotation
		moving_speed = leaning_speed
	%Torso.position = lerp(%Torso.position,target_position,moving_speed)
	%Torso.rotation = lerp_angle(%Torso.rotation,target_rotation,moving_speed)

func compress():
	%Torso.position = rest_position + (Global.taux_compression/100) * (low_position-rest_position)
	%Torso.rotation = rest_rotation + (Global.taux_compression/100) * (low_rotation-rest_rotation)
	
func jump(puissance):
	is_jumping = true
	%AnimationPlayer.play("jump")
	await get_tree().create_timer(0.5).timeout
	is_jumping = false
