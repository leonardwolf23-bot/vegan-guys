extends Node
## Global game state, scoring, and scene transitions.

signal match_started
signal match_ended(winner_name: String)
signal player_eliminated(player_id: int)
signal kill_scored(killer_id: int, victim_id: int)
signal round_ended(round_number: int, scores: Dictionary)
signal session_ended(final_scores: Dictionary)

const MAIN_MENU_SCENE := "res://scenes/main_menu/main_menu.tscn"
const SURVIVAL_CAGE_SCENE := "res://scenes/minigames/survival_cage/survival_cage.tscn"

const MAX_PLAYERS := 6
const ELIMINATION_Y := -30.0
const TOTAL_ROUNDS := 10
const ROUND_SCORE_DISPLAY_TIME := 5.0
const KILL_ATTRIBUTION_WINDOW := 10.0

var current_minigame: String = ""
var alive_players: Array[int] = []
var match_active: bool = false
var session_active: bool = false
var current_round: int = 0
var kill_scores: Dictionary = {}  # peer_id -> kill count

var _last_hits: Dictionary = {}  # victim_id -> { attacker_id, time }
var _round_transition_running := false


func start_session() -> void:
	if not _is_session_authority():
		return
	session_active = true
	current_round = 0
	kill_scores.clear()
	_last_hits.clear()
	_round_transition_running = false
	_init_scores_for_connected_players()
	sync_session_start.rpc()
	_start_next_round()


func start_minigame(scene_path: String) -> void:
	current_minigame = scene_path
	match_active = true
	alive_players.clear()
	get_tree().change_scene_to_file(scene_path)


func start_survival_cage() -> void:
	start_session()


func return_to_menu() -> void:
	session_active = false
	match_active = false
	current_minigame = ""
	current_round = 0
	alive_players.clear()
	_last_hits.clear()
	_round_transition_running = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func register_player(player_id: int) -> void:
	if player_id not in alive_players:
		alive_players.append(player_id)
	_ensure_score(player_id)


func eliminate_player(player_id: int) -> void:
	if player_id not in alive_players:
		return

	alive_players.erase(player_id)
	player_eliminated.emit(player_id)

	var killer_id := get_kill_attribution(player_id)
	if killer_id > 0 and killer_id != player_id:
		_award_kill(killer_id, player_id)

	if not match_active or alive_players.size() > 1:
		return

	match_active = false
	var winner := ""
	if alive_players.size() == 1:
		winner = get_player_display_name(alive_players[0])
	match_ended.emit(winner)

	if _is_session_authority() and session_active:
		_handle_round_complete()


func report_hit(victim: PlayerController, attacker: PlayerController) -> void:
	if victim == null or attacker == null or victim == attacker:
		return
	sync_player_hit.rpc(victim.get_peer_id(), attacker.get_peer_id())


@rpc("any_peer", "call_local", "reliable")
func sync_player_hit(victim_id: int, attacker_id: int) -> void:
	if attacker_id <= 0 or victim_id == attacker_id:
		return
	_last_hits[victim_id] = {
		"attacker_id": attacker_id,
		"time": Time.get_ticks_msec() / 1000.0,
	}


func get_kill_attribution(victim_id: int) -> int:
	if victim_id not in _last_hits:
		return -1
	var hit: Dictionary = _last_hits[victim_id]
	var elapsed: float = Time.get_ticks_msec() / 1000.0 - hit["time"]
	if elapsed > KILL_ATTRIBUTION_WINDOW:
		return -1
	return hit["attacker_id"]


func get_player_display_name(peer_id: int) -> String:
	return NetworkManager.player_names.get(peer_id, "Player %d" % peer_id)


func get_local_kill_count() -> int:
	var peer_id := multiplayer.get_unique_id()
	return kill_scores.get(peer_id, 0)


func _award_kill(killer_id: int, victim_id: int) -> void:
	if not _is_session_authority():
		return
	_ensure_score(killer_id)
	kill_scores[killer_id] += 1
	sync_kill.rpc(killer_id, victim_id, kill_scores.duplicate())


@rpc("authority", "call_local", "reliable")
func sync_kill(killer_id: int, victim_id: int, scores: Dictionary) -> void:
	kill_scores = scores
	kill_scored.emit(killer_id, victim_id)


@rpc("authority", "call_local", "reliable")
func sync_session_start() -> void:
	session_active = true
	current_round = 0
	kill_scores.clear()
	_last_hits.clear()
	_round_transition_running = false
	_init_scores_for_connected_players()


func _handle_round_complete() -> void:
	if _round_transition_running:
		return
	_round_transition_running = true

	var is_final := current_round >= TOTAL_ROUNDS
	broadcast_round_ended.rpc(current_round, kill_scores.duplicate(), is_final)

	if is_final:
		session_active = false
		_round_transition_running = false
		return

	await get_tree().create_timer(ROUND_SCORE_DISPLAY_TIME).timeout
	_round_transition_running = false
	if session_active and _is_session_authority():
		_start_next_round()


@rpc("authority", "call_local", "reliable")
func broadcast_round_ended(round_number: int, scores: Dictionary, is_final: bool) -> void:
	kill_scores = scores
	current_round = round_number
	round_ended.emit(round_number, scores.duplicate())
	if is_final:
		session_active = false
		session_ended.emit(scores.duplicate())


func _start_next_round() -> void:
	current_round += 1
	current_minigame = SURVIVAL_CAGE_SCENE
	match_active = true
	alive_players.clear()
	_last_hits.clear()
	rpc_sync_start_round.rpc()


@rpc("authority", "call_local", "reliable")
func rpc_sync_start_round() -> void:
	match_active = true
	alive_players.clear()
	get_tree().change_scene_to_file(SURVIVAL_CAGE_SCENE)


func _init_scores_for_connected_players() -> void:
	_ensure_score(1)
	if multiplayer.multiplayer_peer:
		for peer_id in multiplayer.get_peers():
			_ensure_score(peer_id)


func _ensure_score(peer_id: int) -> void:
	if peer_id not in kill_scores:
		kill_scores[peer_id] = 0


func _is_session_authority() -> bool:
	return not multiplayer.multiplayer_peer or multiplayer.is_server()
