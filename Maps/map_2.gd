extends Node2D

func get_level_data():
	return {
		"start": %Start,
		"finish": %Finish,
		}

signal finish

func _on_finish_body_entered(body):
	%Finish.activate()
	finish.emit()
