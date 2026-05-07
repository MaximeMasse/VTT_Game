extends Node2D

var ECHELLE = Global.ECHELLE
# Accélération
var ACCÉLÉRATION :float = Global.current_profile["stats"]["ACCÉLÉRATION"]
var FRICTION :float = Global.current_profile["stats"]["FRICTION"]
#Freins
var FORCE_FREINS :int = Global.current_profile["stats"]["FORCE_FREINS"]
# Balance
var COUPLE_CADRE_SOL :float = Global.current_profile["stats"]["COUPLE_CADRE_SOL"]
var COUPLE_CADRE_AIR :float = Global.current_profile["stats"]["COUPLE_CADRE_AIR"]
# Saut
var GREEN_TIME :float = Global.current_profile["stats"]["GREEN_TIME"]
var SWEET_SPOT :float = Global.current_profile["stats"]["SWEET_SPOT"]
var FORCE_SAUT :float = Global.current_profile["stats"]["FORCE_SAUT"]

const TRICK_LIST := ["Wheelie","Nose Wheelie","Air"]

@onready var couple_cadre_actuel := 0.0

@onready var roue_arrière := %Roue_arrière
@onready var contact_sol_arrière := %Contact_sol_arrière
@onready var contact_sol_avant := %Contact_sol_avant
@onready var roue_avant := %Roue_avant
@onready var cadre := %Cadre
@onready var animation := %Animation

var can_drive := false
var temps_compression := 0.0
var previous_state := "slow_riding"
var current_state := "slow_riding"

signal crashed

func _ready():
	roue_avant.mass = 1
	roue_arrière.mass = 1
	cadre.mass = 10
	cadre.center_of_mass = Vector2(10,15)

func _physics_process(delta):
	if not can_drive:
		Global.vitesse = Vector2.ZERO
		Global.current_trick = ""
		roue_arrière.constant_force = Vector2.ZERO
		return
	
	# Tracking
	Global.vitesse = cadre.linear_velocity * ECHELLE * 3.6
	var traveled = (cadre.global_position - Global.player_position).length() * ECHELLE
	var acceleration_direction: Vector2
	if cadre.linear_velocity.length() > 5.0:
		acceleration_direction = cadre.linear_velocity.normalized()
	else:
		acceleration_direction = Vector2.RIGHT.rotated(rotation)
	Global.player_position = cadre.global_position
	Global.contact_sol = contact_sol_arrière.has_overlapping_bodies() or contact_sol_avant.has_overlapping_bodies()
	current_state = get_current_state()
	
	# Frictions
	print(Global.race_time,";",Global.vitesse.length(),";",FRICTION * Global.vitesse.length_squared()*delta,";",(ACCÉLÉRATION * delta/ECHELLE))
	cadre.apply_central_force(-(FRICTION * Global.vitesse.length_squared()*delta) * acceleration_direction)
	
	# Actions
	# Tjs actif
	if Input.is_action_just_released("Pédaler"):
		animation.pause()
	
	# Si contact arrière
	if contact_sol_arrière.has_overlapping_bodies():
		# Accélération
		if Input.is_action_pressed("Pédaler") \
		and not Input.is_action_pressed("Frein_arrière"):
			roue_arrière.apply_central_force((ACCÉLÉRATION * delta/ECHELLE) * acceleration_direction)
			animation.play("pédale")
			
		# Frein arrière
		if Input.is_action_pressed("Frein_arrière"):
			roue_arrière.linear_velocity = lerp(
				roue_arrière.linear_velocity, Vector2(0.0,0.0), 0.5 * FORCE_FREINS * delta)
	
	# Si contact avant
	if contact_sol_avant.has_overlapping_bodies():
		if Input.is_action_pressed("Frein_avant"):
			roue_avant.linear_velocity = lerp(
				roue_avant.linear_velocity, Vector2(0.0,0.0), FORCE_FREINS * delta)
		
	# Balance au sol
	if contact_sol_arrière.has_overlapping_bodies() or contact_sol_avant.has_overlapping_bodies():
		if Input.is_action_pressed("Arrière"):
			couple_cadre_actuel = -2 * COUPLE_CADRE_SOL * delta
		elif Input.is_action_pressed("Avant"):
			couple_cadre_actuel = COUPLE_CADRE_SOL * delta
		else:
			couple_cadre_actuel = 0.0
	# Balance en l'air
	else:
		Global.taux_compression = 0
		if Input.is_action_pressed("Arrière"):
			couple_cadre_actuel = -1.5 * COUPLE_CADRE_AIR * delta
		elif Input.is_action_pressed("Avant"):
			couple_cadre_actuel = COUPLE_CADRE_AIR * delta
		else:
			couple_cadre_actuel = 0.0
	cadre.apply_torque(couple_cadre_actuel)
	
	# Jump (si un contact)
	if contact_sol_arrière.has_overlapping_bodies() or contact_sol_avant.has_overlapping_bodies():
		if Input.is_action_pressed("Jump"):
			temps_compression += delta
			Global.taux_compression = temps_compression_en_pourcentage(temps_compression)
		if Input.is_action_just_released("Jump"):
			cadre.apply_central_impulse(FORCE_SAUT * Global.taux_compression * Vector2.UP.rotated(rotation))
			temps_compression = 0
			Global.taux_compression = 0
	
	# States
	#print("Timer off : ",%ChangeState_Timer.is_stopped()," | previous_state : ",previous_state,
	#" | current_state : ",current_state, " | Global.current_trick :",Global.current_trick,
	#" | Trick length : ",Global.trick_datas.x," | Trick duration ",Global.trick_datas.y)
	if %ChangeState_Timer.is_stopped():
		if current_state == previous_state: Global.trick_datas += Vector2(traveled,delta)
		else:
			if current_state not in TRICK_LIST:
				Global.valid_trick()
				AudioManager.stop_ground_sfx()
				AudioManager.play_ground_sfx(current_state)
				Global.current_trick = ""
			else:
				if previous_state in TRICK_LIST:
					Global.valid_trick()
					AudioManager.stop_ground_sfx()
					if current_state == "Air": AudioManager.play_ground_sfx(current_state)
					else: AudioManager.play_ground_sfx("landing")
				%ChangeState_Timer.start()
				Global.current_trick = ""
				Global.trick_datas = Vector2.ZERO
	else:
		if current_state == previous_state: Global.trick_datas += Vector2(traveled,delta)
		else:
			if current_state in TRICK_LIST: %ChangeState_Timer.start()
			else: %ChangeState_Timer.stop()
			Global.current_trick = ""
			Global.trick_datas = Vector2.ZERO
			
	previous_state = get_current_state()

func _on_change_state_timer_timeout() -> void:
	#print("Timer timed out")
	AudioManager.stop_ground_sfx()
	AudioManager.play_ground_sfx(current_state)
	Global.current_trick = current_state

func _on_crash(body):
	AudioManager.stop_ground_sfx()
	AudioManager.play_sfx("ouch")
	AudioManager.play_sfx("bone_crack")
	crashed.emit()
	queue_free()

func get_current_state()-> String:
	if contact_sol_arrière.has_overlapping_bodies() and contact_sol_avant.has_overlapping_bodies():
		if Global.vitesse.length() < 20: return "slow_riding"
		elif Global.vitesse.length() < 40: return "medium_riding"
		else: return "fast_riding"
	elif contact_sol_arrière.has_overlapping_bodies():
		return "Wheelie"
	elif contact_sol_avant.has_overlapping_bodies():
		return "Nose Wheelie"
	else: return "Air"

func temps_compression_en_pourcentage(temps):
	var pourcentage :int
	if temps < GREEN_TIME:
		pourcentage = int((temps/GREEN_TIME) * 100)
	elif temps <= GREEN_TIME + 2 * SWEET_SPOT: pourcentage = 100
	else: pourcentage = int(100 * (2 + (2 * SWEET_SPOT - temps)/GREEN_TIME))
	return pourcentage
