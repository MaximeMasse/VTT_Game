extends Node2D

var ECHELLE = Global.ECHELLE
# Accélération
var ACCÉLÉRATION :float = Global.current_profile["stats"]["ACCÉLÉRATION"]
var FRICTION :float = Global.current_profile["stats"]["FRICTION"]
#Freins
var FORCE_FREINS :float = Global.current_profile["stats"]["FORCE_FREINS"]
# Balance
var CM_OFFSET:= Vector2(Global.current_profile["stats"]["CM_OFFSET"][0],
								Global.current_profile["stats"]["CM_OFFSET"][1]) 
var COUPLE_CADRE_SOL :float = Global.current_profile["stats"]["COUPLE_CADRE_SOL"]
var COUPLE_CADRE_AIR :float = Global.current_profile["stats"]["COUPLE_CADRE_AIR"]
var BALANCE_CONTROL :float = Global.current_profile["stats"]["BALANCE_CONTROL"]
var AV_CONTROL :float = Global.current_profile["stats"]["AV_CONTROL"]
var AIR_ROTATION_CONTROL :float = Global.current_profile["stats"]["AIR_ROTATION_CONTROL"]
# Saut
var GREEN_TIME :float = Global.current_profile["stats"]["GREEN_TIME"]
var SWEET_SPOT :float = Global.current_profile["stats"]["SWEET_SPOT"]
var FORCE_SAUT :float = Global.current_profile["stats"]["FORCE_SAUT"]
# Air control
var AIR_SPEED_CONTROL :float = Global.current_profile["stats"]["AIR_SPEED_CONTROL"]

const TRICK_LIST := ["Wheelie","Nose Wheelie","Air"]

@onready var roue_arrière := %Roue_arrière
@onready var contact_sol_arrière := %Contact_sol_arrière
@onready var contact_sol_avant := %Contact_sol_avant
@onready var roue_avant := %Roue_avant
@onready var cadre := %Cadre
@onready var animation := %Animation

# Variables
# Physics
var can_drive := false
var input_enabled := true
var couple_cadre_actuel :float = 0.0
var temps_compression := 0.0
# States
var current_frame_state :String
var actual_state :String
var previous_actual_state :String


signal crashed
#signal hud_trick_reset
#signal hud_trick_activate

func _ready():
	reset_physic()
	reset_states()
	Global.reset_tricks()
	

func reset_physic():
	for parts in [cadre, roue_avant, roue_arrière]:
		parts.linear_velocity = Vector2.ZERO
		parts.angular_velocity = 0.0
	couple_cadre_actuel = 0.0
	temps_compression = 0.0
	cadre.center_of_mass = CM_OFFSET

func reset_states():
	current_frame_state = "slow_riding"
	actual_state = "slow_riding"
	previous_actual_state = "slow_riding"
	
func _physics_process(delta):
	if not can_drive:
		Global.vitesse = Vector2.ZERO
		roue_arrière.constant_force = Vector2.ZERO
		return
	
	# HUD Tracking
	Global.vitesse = cadre.linear_velocity * ECHELLE * 3.6
	var traveled = (cadre.global_position - Global.player_position).length() * ECHELLE
	Global.player_position = cadre.global_position
	var rotated = angle_difference(cadre.rotation,Global.player_rotation)
	Global.player_rotation = cadre.rotation
	Global.contact_sol = contact_sol_arrière.has_overlapping_bodies() or contact_sol_avant.has_overlapping_bodies()
	#Acceleration direction
	var acceleration_direction: Vector2
	if cadre.linear_velocity.x > 5.0:
		acceleration_direction = cadre.linear_velocity.normalized()
	else:
		acceleration_direction = Vector2.RIGHT.rotated(cadre.rotation)
	
	# Frictions
	cadre.apply_central_force(-(FRICTION * Global.vitesse.length_squared()*delta) * acceleration_direction)
	
	# Actions
	var input_balance := Input.get_axis("Arrière", "Avant") if input_enabled else 0.0
	var couple_cible := 0.0
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
		if Input.is_action_pressed("Frein_arrière") and input_enabled:
			roue_arrière.linear_velocity = lerp(
				roue_arrière.linear_velocity, Vector2(0.0,0.0), 0.5 * FORCE_FREINS * delta)
	# Si contact avant
	if contact_sol_avant.has_overlapping_bodies():
		if Input.is_action_pressed("Frein_avant") and input_enabled:
			roue_avant.linear_velocity = lerp(
				roue_avant.linear_velocity, Vector2(0.0,0.0), FORCE_FREINS * delta)
	# Air or Ground
	if Global.contact_sol:
		# Balance
		couple_cible = input_balance * COUPLE_CADRE_SOL
		# Balance enhancer
		cadre.angular_velocity = clampf(cadre.angular_velocity,-AV_CONTROL,AV_CONTROL)
		# Jump
		if Input.is_action_pressed("Jump"):
			temps_compression += delta
			Global.taux_compression = temps_compression_en_pourcentage(temps_compression)
		if Input.is_action_just_released("Jump"):
			cadre.apply_central_impulse(FORCE_SAUT * Global.taux_compression * Vector2.UP.rotated(cadre.rotation))
			temps_compression = 0
			Global.taux_compression = 0
	else : 
		# Balance
		couple_cible = input_balance * COUPLE_CADRE_AIR
		# Rotation control
		cadre.angular_velocity = clampf(cadre.angular_velocity,-AIR_ROTATION_CONTROL,AIR_ROTATION_CONTROL)
		# Air speed control
		if not Input.is_action_pressed("Pédaler"):
			cadre.linear_velocity -= AIR_SPEED_CONTROL * acceleration_direction
		# No Jump
		Global.taux_compression = 0
	# Apply balance
	couple_cadre_actuel = lerp(couple_cadre_actuel,couple_cible,1.0-exp(-BALANCE_CONTROL * delta))
	cadre.apply_torque(couple_cadre_actuel)
	
	# Actual State determination
	current_frame_state = get_current_state()
	if current_frame_state not in TRICK_LIST:
		actual_state = current_frame_state
		%Trick_status_changer.stop()
	elif current_frame_state != actual_state and %Trick_status_changer.is_stopped():
		Global.potential_trick = {"trick":"","length":0.0,"duration":0.0,"rotation":0.0}
		%Trick_status_changer.start()
	# Tracking if waiting to become real
	if not %Trick_status_changer.is_stopped():
		Global.trick_update(traveled,delta,rotated,true)
		
	#Actually tricking
	if actual_state in TRICK_LIST:
		Global.trick_update(traveled,delta,rotated)
		# Combo starting
		if previous_actual_state not in TRICK_LIST:
			Global.new_trick(actual_state)
		# Combo continue
		elif actual_state != previous_actual_state:
			Global.combo_update()
			Global.new_trick(actual_state)
	# Not tricking
	else:
		# Combo end
		if previous_actual_state in TRICK_LIST:
			Global.combo_update()
			Global.valid_combo()
			Global.reset_tricks()

	# Audio
	if actual_state != previous_actual_state: ground_sfx_change()
	
	previous_actual_state = actual_state

func ground_sfx_change():
	AudioManager.stop_ground_sfx()
	if previous_actual_state == "Air":
		AudioManager.play_ground_sfx("landing")
		await get_tree().create_timer(0.5).timeout
	AudioManager.play_ground_sfx(actual_state)
	
func _on_trick_status_changer_timeout():
	actual_state = current_frame_state

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
