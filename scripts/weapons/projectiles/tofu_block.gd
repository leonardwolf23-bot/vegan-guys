extends ProjectileBase
## Tofu block - applies suffocation effect on hit.

func _hit_player(player: PlayerController) -> void:
	if shooter:
		GameManager.report_hit(player, shooter)
	player.apply_status(
		PlayerStatusEffects.STATUS_TOFU_SUFFOCATE,
		3.0,
		{ "mash_required": 15 }
	)
