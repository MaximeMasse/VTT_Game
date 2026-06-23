extends CanvasLayer

func _ready():
	%Money.text = "[img]res://Images/HUD/Player/BucksLogo_mini.png[/img]  " +\
		Global.format_number(Global.current_profile["current_run"]["money"])
	%Stars.text = "           " + str(int(Global.current_profile["current_run"]["stars"]))
	%Crowns.text = "[img]res://Images/HUD/Player/CrownsLogo_mini.png[/img]  " +\
		str(int(Global.current_profile["crowns"]))
	%XPBar.value = Global.current_profile["xp"]
	%HPBar.value = Global.current_profile["current_run"]["hp"]
	update_position()

func update_position():
	%Position.text = Global.current_profile["current_run"]["current_day"]["world"] + " - " +\
		Global.current_profile["current_run"]["current_day"]["node"]
