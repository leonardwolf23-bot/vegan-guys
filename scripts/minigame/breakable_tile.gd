class_name BreakableTile
extends StaticBody3D
## Individual cage tile that can break and fall away.
## Swap mesh/material on MeshInstance3D child in Godot editor.

signal tile_broken

@export_group("Breaking")
@export var break_delay: float = 1.5
@export var fall_speed: float = 5.0
@export var auto_break_chance: float = 0.0  # Per-second chance when enabled
@export var is_floor_tile: bool = false  # Floor tiles can randomly break away during the match

@export_group("Warning Visuals")
@export var warning_enabled: bool = true
@export var warning_color: Color = Color(1.0, 0.35, 0.15)
@export var warning_flash_speed: float = 5.0
@export var warning_shake_amount: float = 0.07

var _is_broken := false
var _falling := false
var _velocity := Vector3.ZERO
var _mesh: MeshInstance3D
var _mesh_rest_position := Vector3.ZERO
var _warning_material: StandardMaterial3D
var _base_albedo := Color.WHITE
var _warning_tweens: Array[Tween] = []


func _ready() -> void:
	collision_layer = 16  # breakables layer
	collision_mask = 0
	_mesh = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if _mesh:
		_mesh_rest_position = _mesh.position
		var mat := _get_surface_material()
		if mat:
			_base_albedo = mat.albedo_color
	if not is_floor_tile and global_position.y < 0.5:
		is_floor_tile = true


func break_tile(delay: float = -1.0) -> void:
	if _is_broken:
		return
	_is_broken = true

	var wait_time := break_delay if delay < 0.0 else delay
	if wait_time > 0.0:
		_start_warning(wait_time)
		await get_tree().create_timer(wait_time).timeout
		_stop_warning()

	_start_fall()


func _get_surface_material() -> StandardMaterial3D:
	if _mesh == null:
		return null
	var mat := _mesh.get_surface_override_material(0) as StandardMaterial3D
	if mat == null and _mesh.mesh:
		mat = _mesh.mesh.surface_get_material(0) as StandardMaterial3D
	return mat


func _start_warning(duration: float) -> void:
	if not warning_enabled or _mesh == null:
		return

	var base_mat := _get_surface_material()
	if base_mat:
		_warning_material = base_mat.duplicate() as StandardMaterial3D
		_mesh.set_surface_override_material(0, _warning_material)

	var flash_step := 0.5 / maxf(warning_flash_speed, 0.1)
	var flash := create_tween().set_loops()
	flash.tween_method(_set_warning_blend, 0.0, 1.0, flash_step)
	flash.tween_method(_set_warning_blend, 1.0, 0.0, flash_step)
	_warning_tweens.append(flash)

	var shake := create_tween().set_loops()
	shake.tween_property(
		_mesh,
		"position",
		_mesh_rest_position + Vector3(warning_shake_amount, 0.0, warning_shake_amount),
		0.05
	)
	shake.tween_property(
		_mesh,
		"position",
		_mesh_rest_position - Vector3(warning_shake_amount, 0.0, warning_shake_amount),
		0.05
	)
	shake.tween_property(_mesh, "position", _mesh_rest_position, 0.05)
	_warning_tweens.append(shake)


func _set_warning_blend(amount: float) -> void:
	if _warning_material == null:
		return
	_warning_material.albedo_color = _base_albedo.lerp(warning_color, amount)
	_warning_material.emission_enabled = amount > 0.05
	_warning_material.emission = warning_color * amount * 0.35


func _stop_warning() -> void:
	for tween in _warning_tweens:
		if tween:
			tween.kill()
	_warning_tweens.clear()
	if _mesh:
		_mesh.position = _mesh_rest_position


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
		break_tile()


func _on_area_entered(_area: Area3D) -> void:
	break_tile(0.35)
