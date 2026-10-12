extends CanvasLayer

const CRT_SHADER: Shader = preload("res://shaders/crt_filter.gdshader")
const FILTER_LAYER := 10

var overlay: ColorRect
var shader_material: ShaderMaterial

func _ready() -> void:
	layer = FILTER_LAYER
	overlay = ColorRect.new()
	overlay.name = "CrtPixelFilter"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.color = Color.WHITE
	shader_material = ShaderMaterial.new()
	shader_material.shader = CRT_SHADER
	shader_material.set_shader_parameter("virtual_resolution", Vector2(800.0, 450.0))
	shader_material.set_shader_parameter("curvature", 0.012)
	shader_material.set_shader_parameter("chromatic_aberration", 0.55)
	shader_material.set_shader_parameter("scanline_strength", 0.085)
	shader_material.set_shader_parameter("mask_strength", 0.05)
	shader_material.set_shader_parameter("noise_strength", 0.015)
	shader_material.set_shader_parameter("vignette_strength", 0.18)
	shader_material.set_shader_parameter("saturation", 1.08)
	shader_material.set_shader_parameter("brightness", 1.08)
	overlay.material = shader_material
	add_child(overlay)

func set_filter_enabled(enabled: bool) -> void:
	overlay.visible = enabled

func is_filter_enabled() -> bool:
	return is_instance_valid(overlay) and overlay.visible

func get_parameter(name: StringName) -> Variant:
	return shader_material.get_shader_parameter(name)
