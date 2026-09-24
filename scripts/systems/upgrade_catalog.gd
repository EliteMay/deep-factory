class_name UpgradeCatalog
extends RefCounted

const DATA_PATH := "res://data/upgrades.json"


static func load_all() -> Dictionary:
	var file: FileAccess = FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("UpgradeCatalog: upgrades.jsonを開けません")
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_error("UpgradeCatalog: upgrades.jsonの形式が不正です")
		return {}

	return parsed as Dictionary
