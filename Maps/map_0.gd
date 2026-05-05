extends Node2D

func get_level_data():
	return {
		"start": %Start,
		"finish": %Finish,
		"cp1": %Checkpoint_1,
		"cp2": %Checkpoint_2
		}

signal finish

func _on_finish_body_entered(body):
	%Finish.activate()
	finish.emit()

func _on_checkpoint_1_body_entered(body):
	Global.checkpoint_update("cp1")

func _on_checkpoint_2_body_entered(body):
	Global.checkpoint_update("cp2")
