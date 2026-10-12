class_name NeonTuningStore
extends RefCounted

const CONFIG_PATH := "user://zero_hour_tuning.cfg"
const CONFIG_VERSION := 16
const FOCUS_TIME_SCALE := 0.34
const DEFAULTS := {
	# Player movement and combat.
	"camera_distance": 1.45,
	"run_speed": 470.0,
	"acceleration": 2550.0,
	"gravity": 1480.0,
	"jump_force": 800.0,
	"jump_launch_multiplier": 1.35,
	"jump_rise_gravity_multiplier": 1.65,
	"jump_fall_gravity_multiplier": 1.45,
	"jump_animation_fps": 18.0,
	"attack_cooldown": 0.35,
	"slash_dash_distance": 240.0,
	"slash_dash_speed": 1200.0,
	"focus_drain": 25.0,
	"focus_regen": 14.0,
	# Directional attack rectangle.
	"attack_hitbox_forward": 60.0,
	"attack_hitbox_back": 50.0,
	"attack_hitbox_height": 102.0,
	# Player damage-receiving capsule.
	"player_hurtbox_width": 31.0,
	"player_hurtbox_height": 97.0,
	# Shared enemy damage-receiving capsule.
	"enemy_hurtbox_width": 30.0,
	"enemy_hurtbox_height": 97.0,
	# Enemy roles and aggression multipliers.
	"blade_move_speed": 186.0,
	"blade_patrol_speed": 58.0,
	"blade_aggression": 1.3,
	"blade_alert_range": 780.0,
	"gunner_patrol_speed": 42.0,
	"gunner_aggression": 1.5,
	"gunner_alert_range": 1050.0,
	"gunner_projectile_speed": 610.0,
	# Multi-hit boss encounter.
	"boss_max_health": 25.0,
	"boss_katana_damage": 1.0,
	"boss_melee_parry_damage": 2.0,
	"boss_reflected_damage": 2.0,
	"boss_action_interval": 0.58,
	"boss_dash_speed": 980.0,
	"boss_projectile_speed": 690.0,
	"melee_parry_slow_duration": 0.3,
	"melee_parry_time_scale": 0.5,
	"parry_zoom_amount": 0.02,
	"parry_zoom_duration": 0.28,
	# Foreground character lighting.
	"rim_width": 1.3,
	"rim_brightness": 0.35,
	# Audio mix. SFX is an offset applied to each authored event level.
	"bgm_volume_db": -1.0,
	"sfx_volume_db": 0.0,
	"rain_volume_db": -15.5
}

static var _values: Dictionary = {}
static var _loaded := false

static func get_value(key: String) -> float:
	_ensure_loaded()
	return float(_values.get(key, DEFAULTS.get(key, 0.0)))

static func set_value(key: String, value: float) -> void:
	_ensure_loaded()
	_values[key] = value
	_save()

static func reset() -> void:
	_values = DEFAULTS.duplicate(true)
	_loaded = true
	_save()

static func export_payload() -> Dictionary:
	_ensure_loaded()
	return {
		"format": "ying-tweaks",
		"config_version": CONFIG_VERSION,
		"project": "Shadow",
		"values": _values.duplicate(true)
	}

static func export_json() -> String:
	return JSON.stringify(export_payload(), "\t", true) + "\n"

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_values = DEFAULTS.duplicate(true)
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		var stored_version := int(config.get_value("meta", "version", 0))
		if stored_version >= 4 and stored_version <= CONFIG_VERSION:
			for key in DEFAULTS.keys():
				_values[key] = float(config.get_value("tuning", key, DEFAULTS[key]))
	_loaded = true

static func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "version", CONFIG_VERSION)
	for key in _values.keys():
		config.set_value("tuning", key, _values[key])
	config.save(CONFIG_PATH)
