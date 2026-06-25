extends WeaponBase
## Tofukanone: Fires tofu blocks on left click. Hit players must mash E within 3s or die.

const TOFU_SCENE := preload("res://scenes/weapons/projectiles/tofu_block.tscn")

@export var suffocate_duration: float = 3.0
@export var mash_required: int = 15


func _ready() -> void:
	weapon_name = "Tofukanone"
	cooldown = 2.0


func _perform_attack() -> void:
	var origin := get_aim_origin()
	var direction := get_aim_direction()
	spawn_projectile(TOFU_SCENE, origin, direction, 12.0)
