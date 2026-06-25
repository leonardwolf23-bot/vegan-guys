extends Node3D
## Handles player spawning and multiplayer sync for minigames.

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

@onready var arena: Node3D = $Arena
@onready var players_container: Node3D = $Players
@onready var hud: CanvasLayer = $HUD

var _spawned_players: Dictionary = {}


func _ready() -> void:
	GameManager.match_started.emit()
	if multiplayer.is_server():
		_spawn_all_players()
		multiplayer.peer_connected.connect(_on_peer_connected)
	else:
		await get_tree().create_timer(0.5).timeout
		_request_spawn.rpc_id(1)

	GameManager.match_ended.connect(_on_match_ended)


func _spawn_all_players() -> void:
	var index := 0
	_spawn_player(1, index)
	index += 1
	for peer_id in multiplayer.get_peers():
		_spawn_player(peer_id, index)
		index += 1


func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		var index := _spawned_players.size()
		_spawn_player(peer_id, index)


@rpc("any_peer", "call_local", "reliable")
func _request_spawn() -> void:
	if multiplayer.is_server():
		var peer_id := multiplayer.get_remote_sender_id()
		if peer_id not in _spawned_players:
			_spawn_player(peer_id, _spawned_players.size())


func _spawn_player(peer_id: int, spawn_index: int) -> void:
	if peer_id in _spawned_players:
		return
	var player: PlayerController = PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	players_container.add_child(player, true)
	player.set_multiplayer_authority(peer_id)

	var spawn_pos := Vector3(0, 3, 0)
	if arena and arena.has_method("get_spawn_position"):
		spawn_pos = arena.get_spawn_position(spawn_index)
	player.global_position = spawn_pos

	_spawned_players[peer_id] = player
	rpc("confirm_spawn", peer_id, spawn_pos)


@rpc("authority", "call_local", "reliable")
func confirm_spawn(peer_id: int, pos: Vector3) -> void:
	if peer_id in _spawned_players:
		_spawned_players[peer_id].global_position = pos


func _on_match_ended(winner_name: String) -> void:
	if hud and hud.has_method("show_winner"):
		hud.show_winner(winner_name)
