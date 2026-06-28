extends Control

@export var fill_texture : Texture2D
@export var fill_mat : ShaderMaterial
@export var max_value : float

var value : float

func _ready():
	%Fill.set_anchors_preset(Control.PRESET_TOP_LEFT)
	%Fill.texture = fill_texture
	%Fill.material = fill_mat

func set_fillshader_param(param:String,value):%Fill.material.set_shader_parameter(param,value)

func _process(_delta):
	%Fillclip.size.x = size.x * value/max_value
