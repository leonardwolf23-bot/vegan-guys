extends WeaponBase
## Spaghetti Lasso: Pulls enemies toward you at long range.

@export var lasso_range: float = 25.0
@export var pull_force: float = 20.0


func _ready() -> void:
	weapon_name = "Spaghetti Lasso"
	cooldown = 1.8
	attack_range = lasso_range


func _perform_attack() -> void:
	var origin := get_aim_origin()
	var direction := get_aim_direction()
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * lasso_range, 2)
	query.exclude = [owner_player.get_rid()]
	var result := space.intersect_ray(query)
	if result.is_empty():
		return
	var body: Node = result["collider"]
	if body is PlayerController and body != owner_player:
		GameManager.report_hit(body as PlayerController, owner_player)
		(body as PlayerController).pull_toward(owner_player.global_position, pull_force)
