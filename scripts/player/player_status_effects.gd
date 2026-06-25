class_name PlayerStatusEffects
extends RefCounted
## Tracks temporary status effects on a player.
## Attach logic via Player node - all durations editable in weapon resources.

const STATUS_SLOW := "slow"
const STATUS_CHILI := "chili"
const STATUS_SMOOTHIE_BLIND := "blind"
const STATUS_TOFU_SUFFOCATE := "tofu_suffocate"
const STATUS_SLIP := "slip"

var active_effects: Dictionary = {}  # status_name -> { "timer": float, "data": Dictionary }


func has_effect(status: String) -> bool:
	return active_effects.has(status)


func apply_effect(status: String, duration: float, data: Dictionary = {}) -> void:
	active_effects[status] = { "timer": duration, "data": data }


func remove_effect(status: String) -> void:
	active_effects.erase(status)


func tick(delta: float) -> Array[String]:
	var expired: Array[String] = []
	for status in active_effects.keys():
		active_effects[status]["timer"] -= delta
		if active_effects[status]["timer"] <= 0.0:
			expired.append(status)
	for status in expired:
		active_effects.erase(status)
	return expired


func get_speed_multiplier() -> float:
	var mult := 1.0
	if has_effect(STATUS_SLOW):
		mult *= active_effects[STATUS_SLOW]["data"].get("multiplier", 0.5)
	if has_effect(STATUS_CHILI):
		mult *= active_effects[STATUS_CHILI]["data"].get("multiplier", 2.0)
	if has_effect(STATUS_SLIP):
		mult *= 0.3
	return mult


func get_jump_multiplier() -> float:
	if has_effect(STATUS_CHILI):
		return active_effects[STATUS_CHILI]["data"].get("jump_multiplier", 1.5)
	return 1.0
