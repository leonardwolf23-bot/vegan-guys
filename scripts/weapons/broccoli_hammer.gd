extends WeaponBase
## Brokkoli Hammer: Heavy melee with strong knockback.

@export var knockback: float = 18.0
@export var swing_arc: float = 2.5


func _ready() -> void:
	weapon_name = "Brokkoli Hammer"
	cooldown = 0.8


func _perform_attack() -> void:
	var origin := get_aim_origin()
	var direction := get_aim_direction()
	_swing_hit(origin, direction)


func _swing_hit(origin: Vector3, direction: Vector3) -> void:
	var space := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := SphereShape3D.new()
	shape.radius = swing_arc
	query.shape = shape
	query.transform = Transform3D(Basis(), origin + direction * swing_arc * 0.5)
	query.collision_mask = 2
	var results := space.intersect_shape(query, 8)
	for result in results:
		var body: Node = result["collider"]
		if body is PlayerController and body != owner_player:
			GameManager.report_hit(body as PlayerController, owner_player)
			var knock_dir: Vector3 = ((body as Node3D).global_position - origin).normalized()
			knock_dir.y = 0.3
			(body as PlayerController).apply_knockback(knock_dir, knockback)
