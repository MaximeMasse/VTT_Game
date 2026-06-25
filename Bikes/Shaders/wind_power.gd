extends Node2D

func blow():
	AudioManager.play_sfx("boss_wind")
	%AnimationPlayer.play("blow")
