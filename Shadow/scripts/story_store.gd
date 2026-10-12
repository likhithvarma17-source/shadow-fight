class_name ZeroHourStoryStore
extends RefCounted

const STORY_PATH := "res://data/story.xml"

static var _loaded := false
static var _scenes: Dictionary = {}
static var _barks: Dictionary = {}
static var _version := 0
static var _last_error := ""

static func reload() -> bool:
	_loaded = false
	_scenes.clear()
	_barks.clear()
	_version = 0
	_last_error = ""
	return _load()

static func get_scene(scene_id: String) -> Array[Dictionary]:
	_ensure_loaded()
	return _copy_entries(_scenes.get(scene_id, []))

static func get_barks(role: String) -> Array[Dictionary]:
	_ensure_loaded()
	return _copy_entries(_barks.get(role, []))

static func get_version() -> int:
	_ensure_loaded()
	return _version

static func get_last_error() -> String:
	_ensure_loaded()
	return _last_error

static func validate_xml_text(xml_text: String) -> bool:
	var parser := XMLParser.new()
	if parser.open_buffer(xml_text.to_utf8_buffer()) != OK:
		return false
	var open_elements: Array[String] = []
	var read_error := parser.read()
	while read_error == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT and not parser.is_empty():
			open_elements.append(parser.get_node_name())
		elif parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
			if open_elements.is_empty() or open_elements.pop_back() != parser.get_node_name():
				return false
		read_error = parser.read()
	return read_error == ERR_FILE_EOF and open_elements.is_empty()

static func _copy_entries(source: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in source:
		result.append(Dictionary(entry).duplicate(true))
	return result

static func _ensure_loaded() -> void:
	if not _loaded:
		_load()

static func _load() -> bool:
	_loaded = true
	var parser := XMLParser.new()
	var open_error := parser.open(STORY_PATH)
	if open_error != OK:
		_last_error = "Unable to open %s (%s)" % [STORY_PATH, error_string(open_error)]
		push_error(_last_error)
		return false
	if not validate_xml_text(FileAccess.get_file_as_string(STORY_PATH)):
		_last_error = "Malformed story XML: unclosed, mismatched, or unreadable element."
		push_error(_last_error)
		return false
	var container_type := ""
	var container_id := ""
	var pending_line: Dictionary = {}
	var pending_text := ""
	var read_error := parser.read()
	while read_error == OK:
		var node_type := parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT:
			var node_name := parser.get_node_name()
			var attributes := _read_attributes(parser)
			match node_name:
				"story":
					_version = int(attributes.get("version", "0"))
				"scene":
					container_type = "scene"
					container_id = String(attributes.get("id", ""))
					if not container_id.is_empty():
						_scenes[container_id] = []
				"barks":
					container_type = "barks"
					container_id = String(attributes.get("role", ""))
					if not container_id.is_empty():
						_barks[container_id] = []
				"line":
					pending_line = {
						"text": "",
						"speaker": String(attributes.get("speaker", "")),
						"target": String(attributes.get("target", "")),
						"duration": float(attributes.get("duration", "3.0"))
					}
					pending_text = ""
		elif node_type == XMLParser.NODE_TEXT or node_type == XMLParser.NODE_CDATA:
			if not pending_line.is_empty():
				pending_text += parser.get_node_data()
		elif node_type == XMLParser.NODE_ELEMENT_END:
			var closing_name := parser.get_node_name()
			if closing_name == "line" and not pending_line.is_empty() and not container_id.is_empty():
				pending_line["text"] = pending_text.strip_edges()
				if container_type == "scene":
					(_scenes[container_id] as Array).append(pending_line)
				elif container_type == "barks":
					(_barks[container_id] as Array).append(pending_line)
				pending_line = {}
				pending_text = ""
			elif closing_name == "scene" or closing_name == "barks":
				container_type = ""
				container_id = ""
		read_error = parser.read()
	if read_error != ERR_FILE_EOF:
		_last_error = "Malformed story XML (%s)." % error_string(read_error)
		_scenes.clear()
		_barks.clear()
		push_error(_last_error)
		return false
	if _version <= 0 or _scenes.is_empty():
		_last_error = "Story XML contains no valid scenes or version."
		push_error(_last_error)
		return false
	return true

static func _read_attributes(parser: XMLParser) -> Dictionary:
	var attributes := {}
	for index in range(parser.get_attribute_count()):
		attributes[String(parser.get_attribute_name(index))] = String(parser.get_attribute_value(index))
	return attributes
