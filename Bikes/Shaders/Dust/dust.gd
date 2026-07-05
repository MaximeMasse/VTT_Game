extends Node2D

var max_speed : float = 60
var max_rocks_iv : float = 4000

func _process(delta):
	var speed_ratio : float = Global.vitesse.length()/max_speed
	for emiter:GPUParticles2D in %Particules.get_children():
		var proc : ParticleProcessMaterial = emiter.process_material
		if "Rocks" in emiter.name :proc.initial_velocity_max = max_rocks_iv * speed_ratio
		emiter.amount_ratio = speed_ratio
		emiter.emitting = Global.contact_sol and Global.floor_is == 1 and speed_ratio > 0.05

func go_right():
	scale.x = 1.0
	%Dust1.texture = load("res://Bikes/Shaders/Dust/Puffs/Puffs1.png")
	%Dust2.texture = load("res://Bikes/Shaders/Dust/Puffs/Puffs2.png")

func go_left():
	scale.x = -1.0
	%Dust1.texture = load("res://Bikes/Shaders/Dust/Puffs/Puffs1 - backward.png")
	%Dust2.texture = load("res://Bikes/Shaders/Dust/Puffs/Puffs2 - backward.png")
