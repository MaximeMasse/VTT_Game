extends Node

# Run saves
const RUNS_DIR := "user://maps"
var current_run: Dictionary
var recording : bool

func start_recording():
	current_run = {}
	recording = true

func save_run():
	recording = false
	var map_dir := RUNS_DIR.path_join(Global.current_map)
	DirAccess.make_dir_recursive_absolute(map_dir)
	var date := Time.get_datetime_string_from_system().replace(":", "-")
	var file_path := map_dir.path_join("run_%s.json" % date)
	var datas := {
		"avatar": Global.current_profile["avatar"],
		"score": Global.current_score,
		"race_time": Global.race_time,
		"frames": current_run
	}
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Impossible de sauvegarder la run : " + file_path)
		return
	file.store_string(JSON.stringify(datas))
	file.close()

func load_run(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var error := json.parse(text)
	if error != OK:
		push_error("Erreur JSON dans : " + path)
		return {}
	return json.data

func _process(_delta):
	if recording:
		current_run[Global.race_time] = {
			"x": Global.player_position.x,
			"y": Global.player_position.y,
			"rotation": Global.player_rotation,
			"score": Global.current_score,
			"hp": Global.current_hp
		}
