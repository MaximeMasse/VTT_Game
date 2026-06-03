extends Area2D

var grabbed := false

func _on_body_entered(_body: Node2D) -> void:
	if not grabbed:
		grabbed = true
		Global.is_grabbed = true
		AudioManager.play_sfx("ting")
		%AnimationPlayer.play("Grabbed")

func _on_area_entered(area):_on_body_entered(null)

func reset():
	grabbed = false
	%AnimationPlayer.play("Return")
