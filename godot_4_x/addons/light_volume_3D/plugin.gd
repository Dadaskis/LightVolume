@tool
extends EditorPlugin

func _enter_tree() -> void:
	self.add_autoload_singleton(
		"LightVolume3DCamera", 
		"res://addons/light_volume_3D/src/light_volume_3D_camera.gd"
	)
	
	self.add_custom_type(
		"LightVolume3D", 
		"MeshInstance3D", 
		load("res://addons/light_volume_3D/src/light_volume_3D.gd"),
		load("res://addons/light_volume_3D/assets/icon/icon.png")
	)
	
	var result = ProjectSettings.save()
	assert(result == OK, "Failed to save project settings")

func _handles(obj: Object) -> bool:
	#if obj.name == "__PREFAB":
	#	if not obj.get_parent() is LightVolume3D:
	#		return false
	#	return false
	if obj is LightVolume3D:
		return true
	return false

func _forward_3d_gui_input(camera, event):
	#print("It's happening")
	LightVolume3DCamera.set_camera(camera)
	var forward = false
	if event is InputEventMouseButton:
		forward = false
	return forward

func _exit_tree() -> void:
	self.remove_custom_type("LightVolume3D")
	self.remove_autoload_singleton("LightVolume3DCamera")
