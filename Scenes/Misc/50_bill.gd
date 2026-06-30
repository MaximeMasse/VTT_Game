extends Area2D

var grabbed := false
var id : float
var value := 50

func _on_body_entered(_body):
	if not grabbed:
		grabbed = true
		AudioManager.play_sfx("kaching")
		%AnimationPlayer.play("Grabbed")
		Global.money_update(value,id)

func _on_area_entered(_area):_on_body_entered(null)
