extends Node
## Multiplayer networking layer.
## Uses Godot ENet for LAN/online play. Steam integration via GodotSteam plugin can replace transport later.

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connection_failed
signal server_started
signal connected_to_server

const DEFAULT_PORT := 7777
const MAX_CLIENTS := 5

var peer: ENetMultiplayerPeer = null
var player_names: Dictionary = {}  # peer_id -> display name


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func host_game(player_name: String = "Host", port: int = DEFAULT_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	player_names[1] = player_name
	server_started.emit()
	return OK


func join_game(address: String, player_name: String = "Player", port: int = DEFAULT_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	player_names[multiplayer.get_unique_id()] = player_name
	return OK


func disconnect_game() -> void:
	if peer:
		peer.close()
		peer = null
	multiplayer.multiplayer_peer = null
	player_names.clear()


func is_host() -> bool:
	return multiplayer.is_server()


func get_local_player_name() -> String:
	var id := multiplayer.get_unique_id()
	return player_names.get(id, "Player %d" % id)


func get_player_count() -> int:
	if peer == null:
		return 0
	return multiplayer.get_peers().size() + 1


func _on_peer_connected(id: int) -> void:
	player_names[id] = "Player %d" % id
	player_connected.emit(id)


func _on_peer_disconnected(id: int) -> void:
	player_names.erase(id)
	player_disconnected.emit(id)


func _on_connected_to_server() -> void:
	var id := multiplayer.get_unique_id()
	if id not in player_names:
		player_names[id] = "Player %d" % id
	connected_to_server.emit()


func _on_connection_failed() -> void:
	disconnect_game()
	connection_failed.emit()


func _on_server_disconnected() -> void:
	disconnect_game()
	connection_failed.emit()
