extends Node
## Chinese source strings stay stable; Godot refreshes live Labels/Buttons on locale changes.
signal language_changed(locale: String)

const SETTINGS_PATH := "user://ying-language.cfg"
const WEB_STORAGE_KEY := "ying-language"
var locale := "zh_CN"
var messages: Dictionary = {}
var _english := Translation.new()
var _chinese := Translation.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/i18n.json"))
	if parsed is Dictionary:
		messages = parsed
	_english.locale = "en"
	_chinese.locale = "zh_CN"
	for source in messages:
		_english.add_message(source, String(messages[source]))
		_chinese.add_message(source, source)
	TranslationServer.add_translation(_english)
	TranslationServer.add_translation(_chinese)
	set_language(load_language(), false)

func load_language() -> String:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) == OK:
		var saved := String(settings.get_value("display", "language", ""))
		if saved in ["zh_CN", "en"]:
			return saved
	if OS.has_feature("web"):
		var saved = JavaScriptBridge.eval("(() => { try { return localStorage.getItem('ying-language') || ''; } catch (_) { return ''; } })()")
		if saved is String and saved in ["zh_CN", "en"]:
			return saved
	return "zh_CN" if OS.get_locale_language() == "zh" else "en"

func set_language(value: String, persist: bool = true) -> void:
	if value not in ["zh_CN", "en"]:
		return
	locale = value
	TranslationServer.set_locale(locale)
	_refresh_formatted(get_tree().root)
	if persist:
		var settings := ConfigFile.new()
		settings.set_value("display", "language", locale)
		if settings.save(SETTINGS_PATH) != OK:
			push_warning("Could not persist language preference.")
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(() => { try { localStorage.setItem('ying-language', '%s'); } catch (_) {} document.documentElement.lang = '%s'; document.title = '%s'; })()" % [locale, "zh-CN" if locale == "zh_CN" else "en", "Shadow"])
	language_changed.emit(locale)

func toggle_language() -> void:
	set_language("en" if locale == "zh_CN" else "zh_CN")

func set_formatted(label: Label, source: String, values: Variant) -> void:
	label.set_meta("i18n_format", [source, values])
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.text = String(TranslationServer.translate(source)) % values

func _refresh_formatted(node: Node) -> void:
	if node is Label and node.has_meta("i18n_format"):
		var data: Array = node.get_meta("i18n_format")
		node.text = String(TranslationServer.translate(data[0])) % data[1]
	for child in node.get_children():
		_refresh_formatted(child)

func configure_toggle(button: Button) -> void:
	button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	button.text = "中文  /  English"
	button.tooltip_text = "切换语言 / Switch language"
	button.pressed.connect(toggle_language)
	var update := func(_locale: String):
		button.text = "中文  /  [English]" if locale == "en" else "[中文]  /  English"
		button.queue_redraw()
	language_changed.connect(update)
	button.tree_exiting.connect(func():
		if language_changed.is_connected(update):
			language_changed.disconnect(update)
	)
	update.call(locale)
