extends CanvasLayer
## In-game HUD for survival cage minigame.

@onready var alive_label: Label = $Panel/VBox/AliveLabel
@onready var weapon_label: Label = $Panel/VBox/WeaponLabel
@onready var winner_panel: Panel = $WinnerPanel
@onready var winner_label: Label = $WinnerPanel/WinnerLabel
@onready var back_button: Button = $WinnerPanel/BackButton


func _ready() -> void:
	winner_panel.visible = false
	back_button.pressed.connect(_on_back_pressed)
	GameManager.player_eliminated.connect(_on_player_eliminated)
	_update_alive()


func _process(_delta: float) -> void:
	_update_alive()
	var players := get_tree().get_nodes_in_group("players")
	for p in players:
		if p is PlayerController and p.is_multiplayer_authority():
			if p.current_weapon:
				weapon_label.text = "Waffe: %s (Q/F wechseln)" % p.current_weapon.weapon_name
			break


func _update_alive() -> void:
	alive_label.text = "Übrig: %d Spieler" % GameManager.alive_players.size()


func _on_player_eliminated(_player_id: int) -> void:
	_update_alive()


func show_winner(winner_name: String) -> void:
	winner_panel.visible = true
	if winner_name.is_empty():
		winner_label.text = "Unentschieden!"
	else:
		winner_label.text = "%s gewinnt!" % winner_name


func _on_back_pressed() -> void:
	NetworkManager.disconnect_game()
	GameManager.return_to_menu()
