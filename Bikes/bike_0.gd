extends Node2D

@onready var cadre := %Cadre

signal crashed

func _process(delta):
	var direction = Input.get_vector("Arrière", "Avant", "Pédaler", "Frein_avant")
	global_position += 30 * direction
