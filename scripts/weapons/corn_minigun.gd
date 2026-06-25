extends WeaponBase
## Maiskolbenminigun: 3 second spray, 4 second cooldown, low knockback.

const CORN_SCENE := preload("res://scenes/weapons/projectiles/corn_kernel.tscn")

@export var spray_duration: float = 3.0
@export var spray_cooldown: float = 4.0
@export var fire_rate: float = 0.08

var _is_spraying := false
var _spray_timer := 0.0
var _fire_timer := 0.0


func _ready() -> void:
	weapon_name = "Maiskolbenminigun"
	cooldown = spray_cooldown


func _process(delta: float) -> void:
	super._process(delta)
	if _is_spraying:
		_spray_timer -= delta
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_fire_timer = fire_rate
			_fire_kernel()
		if _spray_timer <= 0.0:
			_is_spraying = false
			_cooldown_timer = spray_cooldown


func _can_attack() -> bool:
	return super._can_attack() and not _is_spraying and _cooldown_timer <= 0.0


func _perform_attack() -> void:
	_is_spraying = true
	_spray_timer = spray_duration


func _fire_kernel() -> void:
	var spread := Vector3(randf_range(-0.08, 0.08), randf_range(-0.05, 0.05), randf_range(-0.08, 0.08))
	var direction := (get_aim_direction() + spread).normalized()
	var kernel: ProjectileBase = spawn_projectile(CORN_SCENE, get_aim_origin(), direction, 22.0) as ProjectileBase
	if kernel:
		kernel.knockback_force = 2.0
