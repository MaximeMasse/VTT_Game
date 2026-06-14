extends Control

func play():
	%AnimationPlayer.play("on")
	await get_tree().create_timer(6).timeout
	unlock()
func unlock():%AnimationPlayer.play("on_2")
