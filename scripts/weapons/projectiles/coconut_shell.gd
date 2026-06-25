extends ProjectileBase
## Coconut mortar shell - high arc, area damage, can break tiles.

@export var explosion_radius: float = 5.0
@export var tile_break_chance: float = 0.2
@export var knockback: float = 5.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if global_position.y <= 0.3 and _timer > 0.5:
		_explode()
		queue_free()


func _explode() -> void:
	var space := get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = explosion_radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), global_position)
	query.collision_mask = 2 | 16  # players + breakables
	var results := space.intersect_shape(query, 32)
	for result in results:
		var body: Node = result["collider"]
		if body is PlayerController:
			var dir := (body.global_position - global_position).normalized()
			(body as PlayerController).apply_knockback(dir, knockback)
		elif body is BreakableTile:
			if randf() < tile_break_chance:
				(body as BreakableTile).break_tile()
