extends Node2D

func _draw():
	draw_circle(get_parent().center_of_mass, 5, Color.RED)

func _process(delta):
	queue_redraw()
