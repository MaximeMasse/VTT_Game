extends Control

@onready var dico_stars := {
	1.0:%Star1,
	2.0:%Star2,
	3.0:%Star3,
	4.0:%Star4,
	5.0:%Star5
}

func stars_update(activated_stars:Array):
	for star in dico_stars:
		if star in activated_stars : dico_stars[star].texture = load("res://Images/Menus/Maps/star_full.png")
		else:dico_stars[star].texture = load("res://Images/Menus/Maps/star_empty.png")
