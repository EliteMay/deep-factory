extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var status_label: Label3D = $StatusLabel

var _preview_material: StandardMaterial3D


func _ready() -> void:
	_preview_material = StandardMaterial3D.new()
	_preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_preview_material.roughness = 0.45
	mesh_instance.material_override = _preview_material
	set_valid(false)


func set_valid(is_valid: bool) -> void:
	if not is_instance_valid(mesh_instance):
		return

	if _preview_material == null:
		_preview_material = StandardMaterial3D.new()
		_preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_preview_material.roughness = 0.45
		mesh_instance.material_override = _preview_material

	if is_valid:
		_preview_material.albedo_color = Color(0.22, 0.92, 0.55, 0.38)
		status_label.text = "設置可能"
	else:
		_preview_material.albedo_color = Color(1.0, 0.28, 0.22, 0.38)
		status_label.text = "ここには置けない"
