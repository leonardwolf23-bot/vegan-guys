extends WeaponBase
## Bananenschalen Werfer: Throws banana peels that cause slipping.

const PEEL_SCENE := preload("res://scenes/weapons/projectiles/banana_peel.tscn")


func _ready() -> void:
	weapon_name = "Bananenschalen Werfer"
	cooldown = 0.6


func _perform_attack() -> void:
	var direction := get_aim_direction()
	spawn_projectile(PEEL_SCENE, get_aim_origin(), direction, 10.0)
