extends WeaponBase
## Kokosnuss Mörser: High arc mortar with area damage and 20% tile break chance.

const COCONUT_SCENE := preload("res://scenes/weapons/projectiles/coconut_shell.tscn")


func _ready() -> void:
	weapon_name = "Kokosnuss Mörser"
	cooldown = 2.5


func _perform_attack() -> void:
	var direction := (get_aim_direction() + Vector3(0, 0.8, 0)).normalized()
	spawn_projectile(COCONUT_SCENE, get_aim_origin() + Vector3(0, 0.5, 0), direction, 12.0)
