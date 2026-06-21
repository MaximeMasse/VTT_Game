extends Node2D

@onready var cadre := %Cadre
var input_enabled : bool

var can_drive := false
var couple_cadre_actuel :float = 0.0
var temps_compression := 0.0
var previous_state := "slow_riding"
var current_state := "slow_riding"

signal crashed
signal boost_consumed

func _process(delta):
	var direction = Input.get_vector("Arrière", "Avant", "Pédaler", "Frein_avant")
	global_position += 30 * direction
