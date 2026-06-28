extends Node2D

func _process(delta):
	var speed_km : float = Global.vitesse.length()
	for emiter:GPUParticles2D in %Particules.get_children():
		if "Rocks" in emiter.name :emiter.process_material.initial_velocity_max = 4000 * speed_km/80
		emiter.emitting = Global.contact_sol and Global.floor_is == 1 and speed_km > 5
		
