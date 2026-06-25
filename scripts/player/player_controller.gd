class_name PlayerController
extends CharacterBody3D
## 3D player with Fall Guys-style movement: run, jump, slide, dodge.
## Replace MeshInstance3D child with your Blender-imported character model.

signal eliminated
signal weapon_changed(weapon_name: String)

@export_group("Movement")
@export var walk_speed: float = 7.0
@export var slide_speed: float = 10.0
@export var jump_velocity: float = 9.0
@export var dodge_speed: float = 14.0
@export var dodge_duration: float = 0.35
@export var slide_duration: float = 0.6
@export var gravity_multiplier: float = 1.0
@export var rotation_speed: float = 12.0

@export_group("Camera")
@export var camera_sensitivity: float = 0.003

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var mesh: Node3D = $Visuals
@onready var weapon_holder: Node3D = $WeaponHolder
@onready var status_label: Label3D = $StatusLabel

var status_effects := PlayerStatusEffects.new()
var current_weapon: WeaponBase = null
var weapon_index: int = 0
var available_weapons: Array[PackedScene] = []

var _is_sliding := false
var _is_dodging := false
var _dodge_timer := 0.0
var _slide_timer := 0.0
var _dodge_direction := Vector3.ZERO
var _camera_rotation_x := 0.0
var _is_alive := true
var _tofu_mash_count := 0
var _tofu_mash_required := 15

# Network sync properties
var sync_position := Vector3.ZERO
var sync_rotation_y := 0.0


func _ready() -> void:
	if not is_multiplayer_authority():
		camera.current = false
		return
	camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_load_weapons()
	_equip_weapon(0)
	GameManager.register_player(multiplayer.get_unique_id())
	_apply_player_color(multiplayer.get_unique_id())


func _load_weapons() -> void:
	var weapon_paths := [
		"res://scenes/weapons/tofu_cannon.tscn",
		"res://scenes/weapons/broccoli_hammer.tscn",
		"res://scenes/weapons/smoothie_blaster.tscn",
		"res://scenes/weapons/banana_peel_thrower.tscn",
		"res://scenes/weapons/salad_spinner.tscn",
		"res://scenes/weapons/tomato_bomber.tscn",
		"res://scenes/weapons/corn_minigun.tscn",
		"res://scenes/weapons/coconut_mortar.tscn",
		"res://scenes/weapons/cream_cannon.tscn",
		"res://scenes/weapons/mushroom_mine.tscn",
		"res://scenes/weapons/spaghetti_lasso.tscn",
		"res://scenes/weapons/chili_thrower.tscn",
		"res://scenes/weapons/leek_lance.tscn",
	]
	for path in weapon_paths:
		if ResourceLoader.exists(path):
			available_weapons.append(load(path))


func _physics_process(delta: float) -> void:
	if not _is_alive:
		return

	if is_multiplayer_authority():
		_process_authority(delta)
	else:
		global_position = global_position.lerp(sync_position, 0.2)
		rotation.y = lerp_angle(rotation.y, sync_rotation_y, 0.2)

	_check_elimination()


func _process_authority(delta: float) -> void:
	_process_status_effects(delta)
	if status_effects.has_effect(PlayerStatusEffects.STATUS_TOFU_SUFFOCATE):
		_handle_tofu_suffocation(delta)
		return

	if _is_dodging:
		_process_dodge(delta)
	elif _is_sliding:
		_process_slide(delta)
	else:
		_process_normal_movement(delta)

	_apply_gravity(delta)
	move_and_slide()

	sync_position = global_position
	sync_rotation_y = rotation.y

	if Input.is_action_just_pressed("attack") and current_weapon:
		current_weapon.try_attack(self)
	if Input.is_action_just_pressed("weapon_next"):
		_equip_weapon((weapon_index + 1) % max(available_weapons.size(), 1))
	if Input.is_action_just_pressed("weapon_prev"):
		_equip_weapon((weapon_index - 1 + available_weapons.size()) % max(available_weapons.size(), 1))


func _process_normal_movement(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (camera_pivot.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var speed := walk_speed * status_effects.get_speed_multiplier()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		var target_rotation := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity * status_effects.get_jump_multiplier()

	if Input.is_action_just_pressed("slide") and is_on_floor() and velocity.length() > 1.0:
		_start_slide()

	if Input.is_action_just_pressed("dodge") and not is_on_floor():
		_start_dodge(direction if direction != Vector3.ZERO else -camera_pivot.global_transform.basis.z)


func _start_slide() -> void:
	_is_sliding = true
	_slide_timer = slide_duration


func _process_slide(delta: float) -> void:
	_slide_timer -= delta
	var slide_dir := -global_transform.basis.z
	velocity.x = slide_dir.x * slide_speed * status_effects.get_speed_multiplier()
	velocity.z = slide_dir.z * slide_speed * status_effects.get_speed_multiplier()
	if _slide_timer <= 0.0:
		_is_sliding = false


func _start_dodge(direction: Vector3) -> void:
	_is_dodging = true
	_dodge_timer = dodge_duration
	_dodge_direction = direction.normalized()


func _process_dodge(delta: float) -> void:
	_dodge_timer -= delta
	velocity.x = _dodge_direction.x * dodge_speed
	velocity.z = _dodge_direction.z * dodge_speed
	if _dodge_timer <= 0.0:
		_is_dodging = false


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier * delta


func _process_status_effects(delta: float) -> void:
	var expired := status_effects.tick(delta)
	for status in expired:
		_on_effect_expired(status)
	_update_status_label()


func _on_effect_expired(status: String) -> void:
	match status:
		PlayerStatusEffects.STATUS_SMOOTHIE_BLIND:
			if camera:
				camera.fov = 75.0
		PlayerStatusEffects.STATUS_TOFU_SUFFOCATE:
			_tofu_mash_count = 0
			_eliminate()


func _handle_tofu_suffocation(_delta: float) -> void:
	velocity = Vector3.ZERO
	if Input.is_action_just_pressed("mash_escape"):
		_tofu_mash_count += 1
		if _tofu_mash_count >= _tofu_mash_required:
			status_effects.remove_effect(PlayerStatusEffects.STATUS_TOFU_SUFFOCATE)
			_tofu_mash_count = 0


func apply_knockback(direction: Vector3, force: float) -> void:
	if not is_multiplayer_authority():
		return
	velocity += direction.normalized() * force


func apply_status(status: String, duration: float, data: Dictionary = {}) -> void:
	status_effects.apply_effect(status, duration, data)
	match status:
		PlayerStatusEffects.STATUS_SMOOTHIE_BLIND:
			if camera:
				camera.fov = 110.0
		PlayerStatusEffects.STATUS_TOFU_SUFFOCATE:
			_tofu_mash_count = 0
			_tofu_mash_required = data.get("mash_required", 15)


func pull_toward(target: Vector3, strength: float) -> void:
	if not is_multiplayer_authority():
		return
	var dir := (target - global_position).normalized()
	velocity += dir * strength


func _equip_weapon(index: int) -> void:
	if available_weapons.is_empty():
		return
	weapon_index = index
	if current_weapon:
		current_weapon.queue_free()
	var weapon_scene: PackedScene = available_weapons[index]
	current_weapon = weapon_scene.instantiate()
	weapon_holder.add_child(current_weapon)
	current_weapon.setup(self)
	weapon_changed.emit(current_weapon.weapon_name)


func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * camera_sensitivity
		_camera_rotation_x -= event.relative.y * camera_sensitivity
		_camera_rotation_x = clamp(_camera_rotation_x, -1.2, 1.2)
		camera_pivot.rotation.x = _camera_rotation_x


func _check_elimination() -> void:
	if global_position.y < GameManager.ELIMINATION_Y and _is_alive:
		_eliminate()


func _eliminate() -> void:
	_is_alive = false
	visible = false
	set_physics_process(false)
	var pid := name.to_int() if name.is_valid_int() else multiplayer.get_unique_id()
	GameManager.eliminate_player(pid)
	eliminated.emit()
	if is_multiplayer_authority():
		rpc("sync_eliminate")


@rpc("any_peer", "call_local", "reliable")
func sync_eliminate() -> void:
	_is_alive = false
	visible = false
	set_physics_process(false)


func _apply_player_color(peer_id: int) -> void:
	var body_mesh := mesh.get_node_or_null("BodyMesh") as MeshInstance3D
	if body_mesh == null:
		return
	var mat := StandardMaterial3D.new()
	var hue := fmod(peer_id * 0.17, 1.0)
	mat.albedo_color = Color.from_hsv(hue, 0.55, 0.85)
	body_mesh.material_override = mat


func _update_status_label() -> void:
	if not status_label:
		return
	var texts: PackedStringArray = []
	if status_effects.has_effect(PlayerStatusEffects.STATUS_TOFU_SUFFOCATE):
		texts.append("SUFFOCATING! Mash E!")
	if status_effects.has_effect(PlayerStatusEffects.STATUS_SLOW):
		texts.append("Slowed")
	if status_effects.has_effect(PlayerStatusEffects.STATUS_CHILI):
		texts.append("CHILI RUSH!")
	if status_effects.has_effect(PlayerStatusEffects.STATUS_SLIP):
		texts.append("Slipping!")
	status_label.text = "\n".join(texts)
