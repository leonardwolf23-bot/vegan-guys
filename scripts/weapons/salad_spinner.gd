extends WeaponBase
## Salatschleuder: Throws spinning lettuce leaves with knockback.

const LETTUCE_SCENE := preload("res://scenes/weapons/projectiles/lettuce_leaf.tscn")


func _ready() -> void:
	weapon_name = "Salatschleuder"
	cooldown = 0.7


func _perform_attack() -> void:
	var direction := get_aim_direction()
	var leaf: ProjectileBase = spawn_projectile(LETTUCE_SCENE, get_aim_origin(), direction, 14.0) as ProjectileBase
	if leaf:
		leaf.knockback_force = 8.0
