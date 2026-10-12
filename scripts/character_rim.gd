extends Sprite2D

const RIM_SHADER: Shader = preload("res://shaders/character_rim.gdshader")
const TuningStore = preload("res://scripts/tuning_store.gd")
const FRAME_CENTER_Y := 96.0
const DRAW_ORIGIN_Y := 24.0

var rim_material: ShaderMaterial

func _ready() -> void:
	name = "CharacterRimLight"
	centered = true
	z_index = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rim_material = ShaderMaterial.new()
	rim_material.shader = RIM_SHADER
	rim_material.set_shader_parameter("key_color", Color(0.30, 1.0, 0.96, 1.0))
	rim_material.set_shader_parameter("bounce_color", Color(1.0, 0.24, 0.60, 0.84))
	rim_material.set_shader_parameter("outline_width", 4.2)
	rim_material.set_shader_parameter("inner_strength", 0.68)
	rim_material.set_shader_parameter("outer_strength", 1.0)
	rim_material.set_shader_parameter("rim_brightness", 1.0)
	rim_material.set_shader_parameter("flip_sign", 1.0)
	material = rim_material

func set_visual(frame_texture: Texture2D, sprite_scale: float, horizontally_flipped: bool) -> void:
	texture = frame_texture
	scale = Vector2(sprite_scale, sprite_scale)
	position = Vector2(0.0, DRAW_ORIGIN_Y - FRAME_CENTER_Y * sprite_scale)
	flip_h = horizontally_flipped
	rim_material.set_shader_parameter("flip_sign", -1.0 if horizontally_flipped else 1.0)
	rim_material.set_shader_parameter("outline_width", TuningStore.get_value("rim_width"))
	rim_material.set_shader_parameter("rim_brightness", TuningStore.get_value("rim_brightness"))

func get_parameter(parameter_name: StringName) -> Variant:
	return rim_material.get_shader_parameter(parameter_name)
