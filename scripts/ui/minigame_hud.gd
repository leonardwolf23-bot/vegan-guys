extends CanvasLayer
## In-game HUD for survival cage minigame.

@onready var alive_label: Label = $Panel/VBox/AliveLabel
@onready var weapon_label: Label = $Panel/VBox/WeaponLabel
@onready var round_label: Label = $Panel/VBox/RoundLabel
@onready var kills_label: Label = $Panel/VBox/KillsLabel
@onready var round_score_panel: Panel = $RoundScorePanel
@onready var round_score_title: Label = $RoundScorePanel/TitleLabel
@onready var round_score_list: Label = $RoundScorePanel/ScoreList
@onready var final_scoreboard_panel: Panel = $FinalScoreboardPanel
@onready var final_score_title: Label = $FinalScoreboardPanel/TitleLabel
@onready var final_score_list: Label = $FinalScoreboardPanel/ScoreList
@onready var back_button: Button = $FinalScoreboardPanel/BackButton


func _ready() -> void:
	round_score_panel.visible = false
	final_scoreboard_panel.visible = false
	back_button.pressed.connect(_on_back_pressed)
	GameManager.player_eliminated.connect(_on_player_eliminated)
	GameManager.kill_scored.connect(_on_kill_scored)
	GameManager.round_ended.connect(_on_round_ended)
	GameManager.session_ended.connect(_on_session_ended)
	_update_alive()
	_update_round_info()
	_update_kills()


func _process(_delta: float) -> void:
	_update_alive()
	_update_round_info()
	_update_kills()
	var players := get_tree().get_nodes_in_group("players")
	for p in players:
		if p is PlayerController and p.is_multiplayer_authority():
			if p.current_weapon:
				weapon_label.text = "Waffe: %s (Linksklick) | Q/F wechseln" % p.current_weapon.weapon_name
			break


func _update_alive() -> void:
	alive_label.text = "Übrig: %d Spieler" % GameManager.alive_players.size()


func _update_round_info() -> void:
	if GameManager.session_active:
		round_label.text = "Runde %d / %d" % [GameManager.current_round, GameManager.TOTAL_ROUNDS]
	else:
		round_label.text = "Runde - / %d" % GameManager.TOTAL_ROUNDS


func _update_kills() -> void:
	kills_label.text = "Kills: %d" % GameManager.get_local_kill_count()


func _on_player_eliminated(_player_id: int) -> void:
	_update_alive()


func _on_kill_scored(_killer_id: int, _victim_id: int) -> void:
	_update_kills()


func _on_round_ended(round_number: int, scores: Dictionary) -> void:
	_show_mouse()
	round_score_title.text = "Runde %d abgeschlossen" % round_number
	round_score_list.text = _format_score_list(scores)
	round_score_panel.visible = true
	final_scoreboard_panel.visible = false


func _on_session_ended(final_scores: Dictionary) -> void:
	_show_mouse()
	round_score_panel.visible = false
	final_score_title.text = "Spiel beendet — Final Scoreboard"
	final_score_list.text = _format_score_list(final_scores)
	final_scoreboard_panel.visible = true


func _format_score_list(scores: Dictionary) -> String:
	var entries: Array[Dictionary] = []
	for peer_id in scores.keys():
		entries.append({
			"name": GameManager.get_player_display_name(int(peer_id)),
			"kills": scores[peer_id],
		})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["kills"] > b["kills"]
	)

	var lines: PackedStringArray = []
	for i in entries.size():
		var entry: Dictionary = entries[i]
		lines.append("%d. %s — %d Kills" % [i + 1, entry["name"], entry["kills"]])
	if lines.is_empty():
		return "Keine Kills in dieser Runde."
	return "\n".join(lines)


func _show_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_back_pressed() -> void:
	NetworkManager.disconnect_game()
	GameManager.return_to_menu()
