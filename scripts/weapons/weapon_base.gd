class_name WeaponBase
extends Node3D
## Base class for all vegan weapons.
## Extend this and override try_attack(). Assign meshes/materials in child nodes in the editor.

@export var weapon_name: String = "Weapon"
@export var cooldown: float = 0.5
@export var attack_range: float = 10.0

var owner_player: PlayerController = null
var _cooldown_timer := 0.0


func setup(player: PlayerController) -> void:
	owner_player = player


func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta


func try_attack(_player: PlayerController) -> void:
	if _cooldown_timer > 0.0:
		return
	if _can_attack():
		_cooldown_timer = cooldown
		_perform_attack()


func _can_attack() -> bool:
	return owner_player != null and is_instance_valid(owner_player)


func _perform_attack() -> void:
	pass  # Override in subclasses


func get_aim_direction() -> Vector3:
	if owner_player == null:
		return Vector3.FORWARD
	return -owner_player.global_transform.basis.z


func get_aim_origin() -> Vector3:
	if owner_player == null:
		return global_position
	return owner_player.global_position + Vector3(0, 1.2, 0)


func spawn_projectile(scene: PackedScene, origin: Vector3, direction: Vector3, speed: float) -> Node3D:
	var projectile := scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = origin
	if projectile.has_method("launch"):
		projectile.launch(direction, speed, owner_player)
	return projectile
