extends ProjectileBase
## Spinning lettuce leaf projectile.

var _spin_speed := 10.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	rotate_y(_spin_speed * delta)
