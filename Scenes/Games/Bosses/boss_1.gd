extends Node2D

# Run datas
var datas : Dictionary
var frames : Dictionary
var started : bool
var speed : float

func _ready():
	started = false
	datas = RunSaveManager.load_run("res://Scenes/Games/Bosses/Maps/run_2026-06-23T23-11-16.json")
	frames = datas["frames"]

func start():
	started = true
	%AnimationPlayer.play("Ride")

func _process(delta):
	if not started:return
	var frame = frames.get(str(Global.race_time),{})
	global_position.x = frame.get("x",global_position.x)
	global_position.y = frame.get("y",global_position.y)
	rotation = frame.get("rotation",rotation)
	speed = frame.get("speed",speed)
	var wheel_rotation_speed = speed * 1000.0 / (3600.0 * Global.ECHELLE * 31.5)
	%FrontWheel.rotation += wheel_rotation_speed * delta
	%BackWheel.rotation += wheel_rotation_speed * delta
