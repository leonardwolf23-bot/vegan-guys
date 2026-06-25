extends Node
## Global game state and scene transitions.
## Edit minigame paths here to add new game modes.

signal match_started
signal match_ended(winner_name: String)
signal player_eliminated(player_id: int)

const MAIN_MENU_SCENE := "res://scenes/main_menu/main_menu.tscn"
const SURVIVAL_CAGE_SCENE := "res://scenes/minigames/survival_cage/survival_cage.tscn"

const MAX_PLAYERS := 6
const ELIMINATION_Y := -30.0

var current_minigame: String = ""
var alive_players: Array[int] = []
var match_active: bool = false


func start_minigame(scene_path: String) -> void:
	current_minigame = scene_path
	match_active = true
	alive_players.clear()
	get_tree().change_scene_to_file(scene_path)


func start_survival_cage() -> void:
	start_minigame(SURVIVAL_CAGE_SCENE)


func return_to_menu() -> void:
	match_active = false
	current_minigame = ""
	alive_players.clear()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func register_player(player_id: int) -> void:
	if player_id not in alive_players:
		alive_players.append(player_id)


func eliminate_player(player_id: int) -> void:
	if player_id in alive_players:
		alive_players.erase(player_id)
		player_eliminated.emit(player_id)
		if match_active and alive_players.size() <= 1:
			var winner := ""
			if alive_players.size() == 1:
				winner = "Player %d" % alive_players[0]
			match_ended.emit(winner)
			match_active = false
