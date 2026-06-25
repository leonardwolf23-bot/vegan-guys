extends WeaponBase
## Vegane Sahnekanone: Reduces target speed by 50% for 3 seconds.

const CREAM_SCENE := preload("res://scenes/weapons/projectiles/cream_blob.tscn")

@export var slow_multiplier: float = 0.5
@export var slow_duration: float = 3.0


func _ready() -> void:
	weapon_name = "Vegane Sahnekanone"
	cooldown = 0.5


func _perform_attack() -> void:
	var direction := get_aim_direction()
	var blob: ProjectileBase = spawn_projectile(CREAM_SCENE, get_aim_origin(), direction, 14.0) as ProjectileBase
	if blob:
		blob.body_entered.connect(_on_cream_hit.bind(blob))


func _on_cream_hit(body: Node3D, blob: ProjectileBase) -> void:
	if body is PlayerController and body != blob.shooter:
		GameManager.report_hit(body as PlayerController, blob.shooter)
		(body as PlayerController).apply_status(
			PlayerStatusEffects.STATUS_SLOW,
			slow_duration,
			{ "multiplier": slow_multiplier }
		)
