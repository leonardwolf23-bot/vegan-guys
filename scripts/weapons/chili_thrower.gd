extends WeaponBase
## Chili Werfer: 200% movement speed and 50% higher jumps for 5 seconds.

const CHILI_SCENE := preload("res://scenes/weapons/projectiles/chili_blob.tscn")

@export var chili_duration: float = 5.0
@export var speed_multiplier: float = 2.0
@export var jump_multiplier: float = 1.5


func _ready() -> void:
	weapon_name = "Chili Werfer"
	cooldown = 0.6


func _perform_attack() -> void:
	var direction := get_aim_direction()
	var chili: ProjectileBase = spawn_projectile(CHILI_SCENE, get_aim_origin(), direction, 16.0) as ProjectileBase
	if chili:
		chili.body_entered.connect(_on_chili_hit.bind(chili))


func _on_chili_hit(body: Node3D, chili: ProjectileBase) -> void:
	if body is PlayerController and body != chili.shooter:
		(body as PlayerController).apply_status(
			PlayerStatusEffects.STATUS_CHILI,
			chili_duration,
			{ "multiplier": speed_multiplier, "jump_multiplier": jump_multiplier }
		)
