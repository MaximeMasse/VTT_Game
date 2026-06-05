extends Node

# Dicos
var dico_music := {
	"MainMenu": preload("res://Sound/Music/awesomeness.wav"),
	"Victory": preload("res://Sound/Music/Victory_music.wav"),
	"Tuto": preload("res://Sound/Music/Tuto.wav"),
	"Map_0": preload("res://Sound/Music/Map_0.mp3"),
	"Map_1": preload("res://Sound/Music/Map_1.mp3"),
	"Map_2": preload("res://Sound/Music/Map_2.mp3"),
	"Map_3": preload("res://Sound/Music/Map_2.mp3")
}
var dico_sfx := {
	"fireworks": preload("res://Sound/SFX/fireworks.wav"),
	"3": preload("res://Sound/SFX/Start/3.wav"),
	"2": preload("res://Sound/SFX/Start/2.wav"),
	"1": preload("res://Sound/SFX/Start/1.wav"),
	"Go": preload("res://Sound/SFX/Start/Go.wav"),
	"horn": preload("res://Sound/SFX/Start/horn.wav"),
	"ouch": preload("res://Sound/SFX/ouch.wav"),
	"bone_crack": preload("res://Sound/SFX/bone_crack.wav"),
	"ting": preload("res://Sound/SFX/Ting.mp3"),
	"kaching":preload("res://Sound/SFX/kaching.mp3"),
	"banana":preload("res://Sound/SFX/banana.mp3"),
	"gap":preload("res://Sound/SFX/Gap.wav"),
	"special_trick":preload("res://Sound/SFX/SpecialTrick.wav"),
	"combo1":preload("res://Sound/SFX/Combo1.mp3"),
	"combo2":preload("res://Sound/SFX/Combo2.mp3"),
	"combo3":preload("res://Sound/SFX/Combo3.mp3"),
	"combo4":preload("res://Sound/SFX/Combo4.mp3"),
	"combo5":preload("res://Sound/SFX/Combo5.mp3"),
	"combo6":preload("res://Sound/SFX/Combo6.mp3"),
	"combo7":preload("res://Sound/SFX/Combo7.mp3")
}
var dico_ground_sfx := {
	"slow_riding":{
		1: preload("res://Sound/SFX/Ground/low_speed_1.wav"),
		2: preload("res://Sound/SFX/Ground/low_speed_2.wav")
	},
	"medium_riding":{
		1: preload("res://Sound/SFX/Ground/medium_speed_1.wav")
	},
	"fast_riding":{
		1: preload("res://Sound/SFX/Ground/high_speed_1.wav"),
		2: preload("res://Sound/SFX/Ground/high_speed_2.wav")
	},
	"Air":{
		1: preload("res://Sound/SFX/Ground/air_1.wav"),
		2: preload("res://Sound/SFX/Ground/air_2.wav"),
		3: preload("res://Sound/SFX/Ground/air_3.wav")
	},
	"landing":{
		1: preload("res://Sound/SFX/Ground/landing_1.wav"),
		2: preload("res://Sound/SFX/Ground/landing_2.wav")
	},
	"Wheelie": {
		1: preload("res://Sound/SFX/Ground/wheeling_1.wav"),
		2: preload("res://Sound/SFX/Ground/wheeling_2.wav"),
		3: preload("res://Sound/SFX/Ground/wheeling_3.wav")
	},
	"Nose Wheelie": {
		1: preload("res://Sound/SFX/Ground/wheeling_1.wav"),
		2: preload("res://Sound/SFX/Ground/wheeling_2.wav"),
		3: preload("res://Sound/SFX/Ground/wheeling_3.wav")
	},
}
var dico_ui := {
	"click": preload("res://Sound/UI/click.wav"),
	"hover": preload("res://Sound/UI/hover.wav")
}

var music_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var ground_sfx_players: Array[AudioStreamPlayer] = []

const SFX_POOL_SIZE := 8

func _ready():
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	ui_player = AudioStreamPlayer.new()
	ui_player.bus = "UI"
	add_child(ui_player)

	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)
		var gplayer := AudioStreamPlayer.new()
		gplayer.bus = "GROUND_SFX"
		add_child(gplayer)
		ground_sfx_players.append(gplayer)

func play_music(music):
	var stream = dico_music[music]
	if music_player.stream == stream and music_player.playing:
		return

	music_player.stream = stream
	music_player.play()

func stop_music():
	music_player.stop()
	
func play_ui(music):
	var stream = dico_ui[music]
	ui_player.stream = stream
	ui_player.play()

func play_sfx(music):
	var stream = dico_sfx[music]
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return

func stop_sfx():
	for player in sfx_players:
		player.stop()

func play_ground_sfx(music):
	var specific_dict = dico_ground_sfx[music]
	var stream = specific_dict[randi_range(1,specific_dict.size())]
	for player in ground_sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return player

func stop_ground_sfx():
	for player in ground_sfx_players:
		player.stop()

func set_bus_volume(bus_name: String, value: float):
	var bus_index := AudioServer.get_bus_index(bus_name)
	var db := linear_to_db(value)
	AudioServer.set_bus_volume_db(bus_index, db)
