class_name NeonSaveStore
extends RefCounted

const SAVE_PATH := "user://zero_hour_save.json"
const VERSION := 2

static func get_best_time() -> float:
	var data := _load_data()
	return float(data.get("best_time", 0.0))

static func submit_time(seconds: float) -> bool:
	var data := _load_data()
	var previous := float(data.get("best_time", 0.0))
	if previous <= 0.0 or seconds < previous:
		data["best_time"] = seconds
		data["version"] = VERSION
		_save_data(data)
		return true
	return false

static func has_completed_tutorial() -> bool:
	return bool(_load_data().get("tutorial_complete", false))

static func mark_tutorial_complete() -> void:
	set_tutorial_complete(true)

static func set_tutorial_complete(completed: bool) -> void:
	var data := _load_data()
	data["tutorial_complete"] = completed
	data["version"] = VERSION
	_save_data(data)

static func _default_data() -> Dictionary:
	return {
		"version": VERSION,
		"best_time": 0.0,
		"tutorial_complete": false
	}

static func _load_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return _default_data()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return _default_data()
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return _default_data()
	var stored_version := int(parsed.get("version", 0))
	if stored_version == VERSION:
		return {
			"version": VERSION,
			"best_time": float(parsed.get("best_time", 0.0)),
			"tutorial_complete": bool(parsed.get("tutorial_complete", false))
		}
	if stored_version == 1:
		var migrated := {
			"version": VERSION,
			"best_time": float(parsed.get("best_time", 0.0)),
			"tutorial_complete": false
		}
		_save_data(migrated)
		return migrated
	return _default_data()

static func _save_data(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
