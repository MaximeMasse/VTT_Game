extends Area2D

@onready var initial_position : Vector2 = global_position 

func _on_body_entered(_body: Node2D) -> void:
	if not Global.is_grabbed:
		Global.is_grabbed = true
		AudioManager.play_sfx("bird")

func _on_area_entered(area):_on_body_entered(null)

func reset():while global_position != initial_position: global_position = global_position.lerp(initial_position,0.5)

func store():
	AudioManager.play_sfx("ting")
	%AnimationPlayer.play("Store")

func _physics_process(delta: float) -> void:
	if Global.is_grabbed and not Global.is_stored: global_position = global_position.lerp(Global.player_position,0.1)
