extends WeaponBase
## Smoothie Blaster: Obscures vision, minimal knockback.

const SMOOTHIE_SCENE := preload("res://scenes/weapons/projectiles/smoothie_blob.tscn")

@export var blind_duration: float = 2.5


func _ready() -> void:
	weapon_name = "Smoothie Blaster"
	cooldown = 0.3


func _perform_attack() -> void:
	for i in 3:
		var spread := Vector3(randf_range(-0.1, 0.1), randf_range(-0.05, 0.1), randf_range(-0.1, 0.1))
		var direction := (get_aim_direction() + spread).normalized()
		var smoothie: ProjectileBase = spawn_projectile(SMOOTHIE_SCENE, get_aim_origin(), direction, 15.0) as ProjectileBase
		if smoothie:
			smoothie.knockback_force = 1.0
			smoothie.body_entered.connect(_on_smoothie_hit.bind(smoothie))


func _on_smoothie_hit(body: Node3D, smoothie: ProjectileBase) -> void:
	if body is PlayerController and body != smoothie.shooter:
		GameManager.report_hit(body as PlayerController, smoothie.shooter)
		(body as PlayerController).apply_status(PlayerStatusEffects.STATUS_SMOOTHIE_BLIND, blind_duration)
