extends Node
## Bind bundled fonts only at runtime, after the clean editor import completes.
var _theme: Theme

func _enter_tree() -> void:
	_theme = Theme.new()
	_theme.default_font = load("res://assets/template/fonts/manuscc0_regular.tres") as Font
	get_tree().node_added.connect(_bind)
	_bind_tree(get_tree().root)

func _bind_tree(node: Node) -> void:
	_bind(node)
	for child in node.get_children():
		_bind_tree(child)

func _bind(node: Node) -> void:
	if node is Control and node.get_parent_control() == null and node.theme == null:
		node.theme = _theme
