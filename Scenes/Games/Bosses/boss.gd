extends Node2D

# Boss datas
var bosses : Dictionary = {
	"Adriano":{"run_path":"res://Scenes/Games/Bosses/Maps/run_2026-06-22T20-22-23.json"}
}
var boss_name : String

# Run datas
var datas : Dictionary
var frames : Dictionary
var started : bool

func _ready():
	started = false
	set_boss_datas()

func set_boss_datas():
	boss_name = Global.current_boss
	datas = RunSaveManager.load_run(bosses[boss_name]["run_path"])
	frames = datas["frames"]


func _process(_delta):
	if not started:return
	var frame = frames.get(str(Global.race_time),{})
	global_position.x = frame.get("x",global_position.x)
	global_position.y = frame.get("y",global_position.y)
	rotation = frame.get("rotation",rotation)
