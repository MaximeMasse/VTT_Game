extends Sprite2D

@export var lifetime := 0.8

func _ready():
	# Speed scaling or fading
	var factor := clampf(Global.vitesse.length()/80,0,1)
	scale = Vector2(factor,factor)

func start_fade():
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, lifetime)
	tween.finished.connect(queue_free)
