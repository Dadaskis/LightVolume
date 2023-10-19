@tool

extends Node

var camera: Camera3D: set = set_camera

signal camera_changed()
signal disabled_in_editor()
signal enabled_in_editor()

func make_disabled_in_editor():
	emit_signal("disabled_in_editor")

func make_enabled_in_editor():
	emit_signal("enabled_in_editor")

func set_camera(value: Camera3D):
	camera = value
	emit_signal("camera_changed")
