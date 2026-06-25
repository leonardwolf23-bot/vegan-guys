class_name BreakableTile
extends StaticBody3D
## Individual cage tile that can break and fall away.
## Swap mesh/material on MeshInstance3D child in Godot editor.

signal tile_broken

@export var break_delay: float = 0.0
@export var fall_speed: float = 5.0
@export var auto_break_chance: float = 0.0  # Per-second chance when enabled

var _is_broken := false
var _falling := false
var _velocity := Vector3.ZERO
var _mesh: MeshInstance3D


func _ready() -> void:
	collision_layer = 16  # breakables layer
	collision_mask = 0
	_mesh = get_node_or_null("MeshInstance3D") as MeshInstance3D


func break_tile(delay: float = 0.0) -> void:
	if _is_broken:
		return
	_is_broken = true
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	_start_fall()


func _start_fall() -> void:
	_falling = true
	collision_layer = 0
	_velocity = Vector3(0, -fall_speed, 0)
	tile_broken.emit()
	if _mesh:
		var tween := create_tween()
		tween.tween_property(_mesh, "scale", Vector3(0.6, 0.6, 0.6), 0.4)


func _physics_process(delta: float) -> void:
	if _falling:
		global_position += _velocity * delta
		_velocity.y -= 15.0 * delta
		if global_position.y < GameManager.ELIMINATION_Y:
			queue_free()
	elif auto_break_chance > 0.0 and randf() < auto_break_chance * delta:
		break_tile(randf_range(0.5, 2.0))


func _on_area_entered(_area: Area3D) -> void:
	break_tile(0.2)
