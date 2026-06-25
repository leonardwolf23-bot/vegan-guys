extends Node3D
## Survival cage arena: procedural generation or manually placed tiles in the editor.
## In manual mode, place BreakableTile scenes under Tiles and Marker3D nodes under SpawnPoints.

enum ArenaMode {
	GENERATED,
	MANUAL,
}

@export_group("Arena")
@export var arena_mode: ArenaMode = ArenaMode.GENERATED
@export var grid_width: int = 12
@export var grid_depth: int = 12
@export var tile_size: float = 2.0
@export var wall_height: int = 3
@export var tile_scene: PackedScene

@export_group("Breaking")
@export var random_break_interval: float = 3.0
@export var tiles_per_break_wave: int = 2
@export var break_wave_enabled: bool = true

@onready var tiles_container: Node3D = $Tiles
@onready var spawn_points: Node3D = $SpawnPoints

var _all_tiles: Array[BreakableTile] = []
var _break_timer := 0.0


func _ready() -> void:
	if tile_scene == null:
		tile_scene = preload("res://scenes/minigames/survival_cage/breakable_tile.tscn")

	match arena_mode:
		ArenaMode.GENERATED:
			_generate_arena()
		ArenaMode.MANUAL:
			_collect_manual_arena()

	if break_wave_enabled and multiplayer.is_server():
		_start_break_waves()


func _process(delta: float) -> void:
	if not break_wave_enabled or not multiplayer.is_server():
		return
	_break_timer += delta
	if _break_timer >= random_break_interval:
		_break_timer = 0.0
		_break_random_tiles()


func _generate_arena() -> void:
	_all_tiles.clear()
	var half_w := grid_width * tile_size * 0.5
	var half_d := grid_depth * tile_size * 0.5

	for x in grid_width:
		for z in grid_depth:
			var pos := Vector3(
				x * tile_size - half_w + tile_size * 0.5,
				0,
				z * tile_size - half_d + tile_size * 0.5
			)
			_spawn_tile(pos)

	for h in wall_height:
		var y := (h + 1) * tile_size
		for x in grid_width:
			_spawn_tile(Vector3(x * tile_size - half_w + tile_size * 0.5, y, -half_d + tile_size * 0.5))
			_spawn_tile(Vector3(x * tile_size - half_w + tile_size * 0.5, y, half_d - tile_size * 0.5))
		for z in grid_depth:
			_spawn_tile(Vector3(-half_w + tile_size * 0.5, y, z * tile_size - half_d + tile_size * 0.5))
			_spawn_tile(Vector3(half_w - tile_size * 0.5, y, z * tile_size - half_d + tile_size * 0.5))

	_setup_generated_spawn_points(half_w, half_d)


func _collect_manual_arena() -> void:
	_all_tiles.clear()
	for node in tiles_container.find_children("", "BreakableTile", true, false):
		_all_tiles.append(node as BreakableTile)

	if _all_tiles.is_empty():
		push_warning("Manual arena: No BreakableTile nodes found under Arena/Tiles.")

	_ensure_manual_spawn_points()


func _spawn_tile(pos: Vector3) -> void:
	var tile: BreakableTile = tile_scene.instantiate()
	tiles_container.add_child(tile)
	tile.global_position = pos
	_all_tiles.append(tile)


func _setup_generated_spawn_points(half_w: float, half_d: float) -> void:
	var positions := [
		Vector3(-half_w * 0.5, 2, -half_d * 0.5),
		Vector3(half_w * 0.5, 2, -half_d * 0.5),
		Vector3(-half_w * 0.5, 2, half_d * 0.5),
		Vector3(half_w * 0.5, 2, half_d * 0.5),
		Vector3(0, 2, 0),
		Vector3(0, 2, -half_d * 0.3),
	]
	for i in positions.size():
		var marker := Marker3D.new()
		marker.name = "Spawn%d" % i
		marker.position = positions[i]
		spawn_points.add_child(marker)


func _ensure_manual_spawn_points() -> void:
	var markers: Array[Marker3D] = []
	for child in spawn_points.get_children():
		if child is Marker3D:
			markers.append(child)

	if markers.is_empty():
		push_warning("Manual arena: No Marker3D under Arena/SpawnPoints. Using default spawn at (0, 2, 0).")
		var marker := Marker3D.new()
		marker.name = "Spawn0"
		marker.position = Vector3(0, 2, 0)
		spawn_points.add_child(marker)


func get_spawn_position(index: int) -> Vector3:
	var marker := spawn_points.get_node_or_null("Spawn%d" % index) as Marker3D
	if marker:
		return marker.global_position

	var markers: Array[Marker3D] = []
	for child in spawn_points.get_children():
		if child is Marker3D:
			markers.append(child)
	if index < markers.size():
		return markers[index].global_position

	return Vector3(0, 2, 0)


func _break_random_tiles() -> void:
	var floor_tiles: Array[BreakableTile] = []
	for tile in _all_tiles:
		if is_instance_valid(tile) and tile.is_floor_tile:
			floor_tiles.append(tile)
	floor_tiles.shuffle()
	for i in mini(tiles_per_break_wave, floor_tiles.size()):
		var delay := randf_range(0.3, 1.5)
		floor_tiles[i].break_tile(delay)
		rpc("sync_break_tile", floor_tiles[i].get_path(), delay)


@rpc("authority", "call_local", "reliable")
func sync_break_tile(tile_path: NodePath, delay: float) -> void:
	var tile := get_node_or_null(tile_path) as BreakableTile
	if tile:
		tile.break_tile(delay)


func _start_break_waves() -> void:
	_break_timer = random_break_interval * 0.5
