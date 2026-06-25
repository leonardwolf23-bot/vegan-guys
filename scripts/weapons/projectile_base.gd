class_name ProjectileBase
extends Area3D
## Base projectile - replace mesh child with your custom model in Godot editor.

@export var lifetime: float = 5.0
@export var knockback_force: float = 5.0
@export var damage_type: String = "knockback"

var velocity: Vector3 = Vector3.ZERO
var shooter: PlayerController = null
var _timer := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 2 | 4  # players + projectiles


func launch(direction: Vector3, speed: float, owner: PlayerController) -> void:
	velocity = direction.normalized() * speed
	shooter = owner
	look_at(global_position + direction)


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * 0.3 * delta
	_timer += delta
	if _timer >= lifetime:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body == shooter:
		return
	if body is PlayerController:
		_hit_player(body as PlayerController)
	queue_free()


func _hit_player(player: PlayerController) -> void:
	if shooter:
		GameManager.report_hit(player, shooter)
	if knockback_force > 0.0:
		var dir := (player.global_position - global_position).normalized()
		dir.y = 0.2
		player.apply_knockback(dir, knockback_force)
