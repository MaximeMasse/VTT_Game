extends Control

func _ready():%Avatar.texture = load(Global.get_sprites_path() + "Avatar_backseat.png")

func play():
	%AnimationPlayer.play("on")
	await get_tree().create_timer(3).timeout
	unlock()
func unlock():%AnimationPlayer.play("on_2")
