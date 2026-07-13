extends CanvasLayer

@onready var xpbar : TextureProgressBar = %XPBar

func _ready():
	set_up_buttons(self)
	%Money.text = "[img]res://Images/HUD/Player/BucksLogo_mini.png[/img]  " +\
		Global.format_number(Global.current_profile["current_run"]["money"])
	%Stars.text = "           " + str(int(Global.current_profile["current_run"]["stars"]))
	%Crowns.text = "[img]res://Images/HUD/Player/CrownsLogo_mini.png[/img]  " +\
		str(int(Global.current_profile["crowns"]))
	%HPBar.value = Global.current_profile["current_run"]["hp"]
	%NewAchievement.hide()
	%LevelUp.hide()
	xpbar.max_value = UpgradesManager.XP_LEVELS[int(Global.current_profile["lvl"])]
	xpbar.value = Global.current_profile["xp"]
	%Level.text = " Lvl : " + str(int(Global.current_profile["lvl"]))
	update_position()

func update_position():
	%Position.text = Global.current_profile["current_run"]["current_day"]["world"] + " - " +\
		Global.current_profile["current_run"]["current_day"]["node"]

func new_achievement(datas:Dictionary,level:int):
	AudioManager.play_sfx("achievement")
	%NewAchievementName.text = datas["name"]
	var description : String = datas["description"].replace("x",str(datas["levels"][level]))
	%NewAchievementDatas.text = description + "\n\n" + "Tier " + str(level) + " -> Tier " + str(level+1)
	%NewAchievement.show()

func xp_up():xpbar.value += 1

func level_up():
	AudioManager.play_sfx("level_up")
	%AnimationPlayer.play("level_up")
	xpbar.value = 0
	xpbar.max_value = UpgradesManager.XP_LEVELS[int(Global.current_profile["lvl"])]
	%Level.text = "Lvl : " + str(int(Global.current_profile["lvl"]))

func set_up_buttons(node):
	for child in node.get_children():
		if child is BaseButton:
			child.mouse_entered.connect(func(): on_button_hover(child))
			child.mouse_exited.connect(func(): on_button_hover_exit(child))
			child.focus_entered.connect(func(): on_button_focus(child))
			child.pressed.connect(func():on_button_pressed(child))
		set_up_buttons(child)
func on_button_hover(button:BaseButton):if not button.disabled:button.grab_focus()
func on_button_hover_exit(_button:BaseButton):get_viewport().gui_release_focus()
func on_button_focus(_button:BaseButton):AudioManager.play_ui("hover")
func on_button_pressed(_button:BaseButton):AudioManager.play_ui("click")

func _on_achievement_ok_pressed():
	%NewAchievement.hide()
	UpgradesManager.achievement_display_finished.emit()
