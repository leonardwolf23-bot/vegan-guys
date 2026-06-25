extends WeaponBase
## Lauchlanze: Absurdly long melee range with light knockback.

@export var lance_range: float = 6.0
@export var knockback: float = 6.0


func _ready() -> void:
	weapon_name = "Lauchlanze"
	cooldown = 0.9
	attack_range = lance_range


func _perform_attack() -> void:
	var origin := get_aim_origin()
	var direction := get_aim_direction()
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * lance_range, 2)
	query.exclude = [owner_player.get_rid()]
	var result := space.intersect_ray(query)
	if result.is_empty():
		return
	var body: Node = result.get("collider")
	if body is PlayerController and body != owner_player:
		var knock_dir := direction
		knock_dir.y = 0.1
		(body as PlayerController).apply_knockback(knock_dir, knockback)
