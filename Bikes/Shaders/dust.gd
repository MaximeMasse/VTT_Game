extends Node2D

@onready var dust_sprite: Sprite2D = %Dust1

func _process(delta):
	var speed := Global.vitesse.length() # ou ta vraie vitesse vélo
	var mat := dust_sprite.material as ShaderMaterial
	mat.set_shader_parameter("bike_speed", speed)
	# Speed scaling or fading
	var factor := clampf(speed/80,0,1)
	scale = scale.lerp(Vector2(factor,factor),6*delta) if speed > 5.0 and\
		Global.contact_sol and Global.floor_is == 1 else Vector2.ZERO 
