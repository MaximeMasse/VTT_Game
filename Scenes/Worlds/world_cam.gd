extends Camera2D

var zoom_step := 0.1
var zoom_min := 1
var zoom_max := 3.0
var drag_speed := 1.0

var camera_smooth := 3.0
var target_position : Vector2
var target_zoom : Vector2

var node_cam_position : Dictionary = {
	"full_screen":{"position":Vector2(640.0,360.0),"zoom":Vector2.ONE},
	"reset":{"position":Vector2(640.0,360.0),"zoom":Vector2(1.2,1.2)},
	"ForestChairlift":{"position":Vector2(728.0,380.0),"zoom":Vector2(1.375,1.375)},
	"0":{"position":Vector2(742.0,247.0),"zoom":Vector2(2.415,2.415)},
	"1":{"position":Vector2(740.0,382.0),"zoom":Vector2(-2.735,-1.34)},
	"2":{"position":Vector2(740.0,382.0),"zoom":Vector2(-2.735,-1.34)},
	"ForestBoss":{"position":Vector2(740.0,382.0),"zoom":Vector2(-2.735,-1.34)},
	"ChairliftToDesert":{"position":Vector2(740.0,382.0),"zoom":Vector2(-2.735,-1.34)}
}

var canvas_size := Vector2(1280.0,720.0)

var dragging := false
var zooming := false

func position_cam(node:String):
	position = node_cam_position["reset"]["position"]
	zoom = node_cam_position["reset"]["zoom"]
	zooming = true
	target_position = node_cam_position[node]["position"]
	target_zoom = node_cam_position[node]["zoom"]

func _unhandled_input(event: InputEvent) -> void:
	if zooming:return
	if event is InputEventMouseButton:
		# Clic molette pour déplacer la caméra
		if event.button_index == MOUSE_BUTTON_MIDDLE:dragging = event.pressed
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:zoom_at_mouse(1.0 - zoom_step)
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:zoom_at_mouse(1.0 + zoom_step)
	elif event is InputEventMouseMotion and dragging:
		position -= event.relative / zoom * drag_speed
		clamp_camera()

func zoom_at_mouse(factor: float) -> void:
	var mouse_before := get_global_mouse_position()
	zoom *= factor
	zoom.x = clamp(zoom.x, zoom_min, zoom_max)
	zoom.y = clamp(zoom.y, zoom_min, zoom_max)
	var mouse_after := get_global_mouse_position()
	position += mouse_before - mouse_after
	clamp_camera()

func clamp_camera():
	var viewport_size := get_viewport_rect().size
	var half_width := viewport_size.x * 0.5 / zoom.x
	var half_height := viewport_size.y * 0.5 / zoom.y
	position.x = clamp(position.x,half_width,canvas_size.x - half_width)
	position.y = clamp(position.y,half_height,canvas_size.y - half_height)
	
func _process(delta):
	print("zooming : ",zooming)
	if not zooming:return
	position = position.lerp(target_position,camera_smooth*delta)
	zoom = zoom.lerp(target_zoom,camera_smooth*delta)
	zooming = position.distance_to(target_position) > 1.0 or zoom.distance_to(target_zoom) > 0.01
