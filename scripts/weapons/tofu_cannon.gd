extends WeaponBase
## Tofukanone: Fires tofu blocks every 2 seconds. Hit players must mash E within 3s or die.

const TOFU_SCENE := preload("res://scenes/weapons/projectiles/tofu_block.tscn")

@export var fire_interval: float = 2.0
@export var suffocate_duration: float = 3.0
@export var mash_required: int = 15

var _fire_timer := 0.0


func _ready() -> void:
	weapon_name = "Tofukanone"
	cooldown = 0.1


func _process(delta: float) -> void:
	super._process(delta)
	_fire_timer += delta
	if _fire_timer >= fire_interval and owner_player and owner_player.is_multiplayer_authority():
		_fire_timer = 0.0
		_shoot_tofu()


func _perform_attack() -> void:
	_shoot_tofu()


func _shoot_tofu() -> void:
	var origin := get_aim_origin()
	var direction := get_aim_direction()
	spawn_projectile(TOFU_SCENE, origin, direction, 12.0)
