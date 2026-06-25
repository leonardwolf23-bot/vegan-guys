extends WeaponBase
## Pilzsprungmine: Place nearly invisible mines that launch players upward.

const MINE_SCENE := preload("res://scenes/weapons/projectiles/mushroom_mine.tscn")


func _ready() -> void:
	weapon_name = "Pilzsprungmine"
	cooldown = 1.5


func _perform_attack() -> void:
	var place_pos := owner_player.global_position + get_aim_direction() * 1.5
	place_pos.y = owner_player.global_position.y
	var mine := MINE_SCENE.instantiate()
	get_tree().current_scene.add_child(mine)
	mine.global_position = place_pos
	if mine.has_method("setup"):
		mine.setup(owner_player)
