extends Area2D

func _on_body_entered(_body: Node2D) -> void:
	Global.is_collected = true
	AudioManager.play_sfx("ting")
	%AnimationPlayer.play("Grabbed")
