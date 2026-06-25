extends Control
## Main menu with host/join multiplayer and minigame selection.

@onready var host_button: Button = $VBox/HostButton
@onready var join_button: Button = $VBox/JoinButton
@onready var play_button: Button = $VBox/PlayButton
@onready var quit_button: Button = $VBox/QuitButton
@onready var address_input: LineEdit = $VBox/AddressInput
@onready var name_input: LineEdit = $VBox/NameInput
@onready var status_label: Label = $VBox/StatusLabel
@onready var title_label: Label = $VBox/TitleLabel


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	NetworkManager.server_started.connect(_on_server_started)
	NetworkManager.connected_to_server.connect(_on_connected)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.player_connected.connect(_on_player_connected)

	play_button.disabled = true
	status_label.text = "Hoste oder trete einem Spiel bei (max. 6 Spieler)"


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_host_pressed() -> void:
	var player_name := name_input.text if name_input.text else "Host"
	var err := NetworkManager.host_game(player_name)
	if err != OK:
		status_label.text = "Fehler beim Hosten: %d" % err
	else:
		status_label.text = "Server gestartet! Warte auf Spieler..."


func _on_join_pressed() -> void:
	var address := address_input.text if address_input.text else "127.0.0.1"
	var player_name := name_input.text if name_input.text else "Player"
	var err := NetworkManager.join_game(address, player_name)
	if err != OK:
		status_label.text = "Verbindungsfehler: %d" % err
	else:
		status_label.text = "Verbinde mit %s..." % address


func _on_play_pressed() -> void:
	if NetworkManager.is_host():
		rpc("sync_start_game")
	elif NetworkManager.peer != null:
		_request_start.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _request_start() -> void:
	if multiplayer.is_server():
		GameManager.start_session()
		rpc("sync_start_game")


@rpc("authority", "call_local", "reliable")
func sync_start_game() -> void:
	if NetworkManager.is_host():
		GameManager.start_session()


func _on_server_started() -> void:
	play_button.disabled = false
	status_label.text = "Server läuft! (%d/%d Spieler)" % [NetworkManager.get_player_count(), GameManager.MAX_PLAYERS]


func _on_connected() -> void:
	play_button.disabled = true
	status_label.text = "Verbunden! Warte auf Host..."


func _on_connection_failed() -> void:
	status_label.text = "Verbindung fehlgeschlagen!"
	play_button.disabled = true


func _on_player_connected(_peer_id: int) -> void:
	if NetworkManager.is_host():
		status_label.text = "Server läuft! (%d/%d Spieler)" % [NetworkManager.get_player_count(), GameManager.MAX_PLAYERS]


func _on_quit_pressed() -> void:
	get_tree().quit()
