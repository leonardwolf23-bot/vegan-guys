extends Area3D
## Hidden mushroom mine - launches players upward when stepped on.

@export var launch_force: float = 18.0
@export var arm_delay: float = 0.8

var owner_player: PlayerController = null
var _armed := false
var _timer := 0.0


func setup(owner: PlayerController) -> void:
	owner_player = owner


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 4
	collision_mask = 2
	# Nearly invisible - edit scale/material in editor
	scale = Vector3(0.4, 0.15, 0.4)


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= arm_delay:
		_armed = true


func _on_body_entered(body: Node3D) -> void:
	if not _armed:
		return
	if body is PlayerController and body != owner_player:
		(body as PlayerController).apply_knockback(Vector3(0, 1, 0), launch_force)
		queue_free()
