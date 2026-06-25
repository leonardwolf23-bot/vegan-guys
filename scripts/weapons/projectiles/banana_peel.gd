extends Area3D
## Banana peel hazard - players slip when stepping on it.

@export var slip_duration: float = 1.5
@export var lifetime: float = 20.0

var _timer := 0.0
var _triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 4
	collision_mask = 2


func launch(direction: Vector3, speed: float, owner: PlayerController) -> void:
	velocity_internal = direction.normalized() * speed


var velocity_internal := Vector3.ZERO


func _physics_process(delta: float) -> void:
	if not _triggered:
		global_position += velocity_internal * delta
		velocity_internal.y -= 8.0 * delta
	_timer += delta
	if _timer >= lifetime:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body is PlayerController:
		(body as PlayerController).apply_status(PlayerStatusEffects.STATUS_SLIP, slip_duration)
		_triggered = true
		velocity_internal = Vector3.ZERO
