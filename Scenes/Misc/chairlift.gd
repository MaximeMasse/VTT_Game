extends Control

func play():
	%AnimationPlayer.play("on")
	await get_tree().create_timer(3).timeout
	unlock()
func unlock():%AnimationPlayer.play("on_2")
