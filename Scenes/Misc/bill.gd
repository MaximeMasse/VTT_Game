extends Area2D

var grabbed := false

func _on_body_entered(body):
	if not grabbed:
		grabbed = true
		AudioManager.play_sfx("kaching")
		%AnimationPlayer.play("Grabbed")

func _on_area_entered(area):_on_body_entered(null)
