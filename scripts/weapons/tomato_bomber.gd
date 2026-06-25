extends WeaponBase
## Tomatenbomber: Explosive tomatoes launch players upward.

const TOMATO_SCENE := preload("res://scenes/weapons/projectiles/tomato_grenade.tscn")


func _ready() -> void:
	weapon_name = "Tomatenbomber"
	cooldown = 1.2


func _perform_attack() -> void:
	var direction := (get_aim_direction() + Vector3(0, 0.4, 0)).normalized()
	spawn_projectile(TOMATO_SCENE, get_aim_origin(), direction, 16.0)
