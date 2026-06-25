extends ProjectileBase
## Tomato grenade - explodes on impact launching players upward.

@export var explosion_radius: float = 3.5
@export var launch_force: float = 16.0
@export var back_force: float = 8.0


func _on_body_entered(body: Node3D) -> void:
	if body == shooter:
		return
	_explode()
	queue_free()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_on_floor_check():
		_explode()
		queue_free()


func is_on_floor_check() -> bool:
	return global_position.y < 0.5 and _timer > 0.3


func _explode() -> void:
	var space := get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = explosion_radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), global_position)
	query.collision_mask = 2
	var results := space.intersect_shape(query, 16)
	for result in results:
		var body: Node = result["collider"]
		if body is PlayerController:
			var player := body as PlayerController
			if shooter:
				GameManager.report_hit(player, shooter)
			var dir := (player.global_position - global_position).normalized()
			player.apply_knockback(Vector3(dir.x * back_force, launch_force, dir.z * back_force), 1.0)
