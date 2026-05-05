extends Node2D


func _physics_process(delta):
	
	if Input.is_action_just_pressed("Restart"):
		queue_free()
		
func get_level_data():
	return {
		"start": %Start.global_position,
		"finish": %Finish.global_position,
		"checkpoints":[
			%Checkpoint_1.global_position
		]
		}
