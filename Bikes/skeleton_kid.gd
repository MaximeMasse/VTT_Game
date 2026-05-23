extends Node2D

var rest_position := Vector2.ZERO
var rest_rotation := deg_to_rad(0)
var back_position := Vector2(-18,17)
var back_rotation := deg_to_rad(4)
var front_position := Vector2(35,2)
var front_rotation := deg_to_rad(7)
var leaning_speed := 0.1
var leaning_return_speed := 0.8
var low_position := Vector2(20,21)
var low_rotation := deg_to_rad(5)
var high_position := Vector2(14,-13)
var high_rotation := deg_to_rad(-8.5)
var jumping_speed := 0.8

var is_jumping : bool

signal contact(body: Node2D)

func _ready():
	var sprites_path := Global.get_sprites_path()
	%HeadSprite.texture = load(sprites_path+"Head.png")
	%ArmUpBack.texture = load(sprites_path+"ArmUp.png")
	%ArmDownBack.texture = load(sprites_path+"ArmBackDown.png")
	%TorsoSprite.texture = load(sprites_path+"Torso.png")
	%ArmUp.texture = load(sprites_path+"ArmUp.png")
	%ArmDown.texture = load(sprites_path+"ArmDown.png")
	%FrontLegUp.texture = load(sprites_path+"FrontLegUp.png")
	%FrontFoot.texture = load(sprites_path+"Foot.png")
	%FrontLegDown.texture = load(sprites_path+"FrontLegDown.png")
	%BackLegUp.texture = load(sprites_path+"BackLegUp.png")
	%BackLegDown.texture = load(sprites_path+"FrontLegDown.png")
	%BackFoot.texture = load(sprites_path+"Foot.png")
	%Tail.texture = load(sprites_path+"Tail.png")


func _process(_delta: float) -> void:pass
	#%Contact.global_position = %Torso.global_position
	#%Contact.global_rotation = %Torso.global_rotation
	

func crank_rotate(angle: float):
	%Cranks.rotate(angle)

func lean(input:float):
	if Global.taux_compression > 0.0 or is_jumping:return
	var target_position := rest_position
	var target_rotation := rest_rotation
	var moving_speed := leaning_return_speed
	if input < 0.0:
		target_position = back_position
		target_rotation = back_rotation
		moving_speed = leaning_speed
	elif input > 0.0:
		target_position = front_position
		target_rotation = front_rotation
		moving_speed = leaning_speed
	%Torso.position = lerp(%Torso.position,target_position,moving_speed)
	%Torso.rotation = lerp_angle(%Torso.rotation,target_rotation,moving_speed)

func compress():
	%Torso.position = lerp(%Torso.position,rest_position + (Global.taux_compression/100) * (low_position-rest_position),0.5)
	%Torso.rotation = lerp_angle(%Torso.rotation,rest_rotation + (Global.taux_compression/100) * (low_rotation-rest_rotation),0.5)
	
func jump(puissance):
	is_jumping = true
	%Torso.position = lerp(%Torso.position,high_position,clampf(puissance/100,0.1,1))
	%Torso.rotation = lerp_angle(%Torso.rotation,high_rotation,clampf(puissance/100,0.1,1))
	await get_tree().create_timer(0.5).timeout
	is_jumping = false


func _on_contact_body_entered(body: Node2D) -> void:contact.emit(body)
