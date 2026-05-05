extends RigidBody2D

func _draw():
	draw_circle(center_of_mass, 5, Color.RED)

func _process(delta):
	queue_redraw()
