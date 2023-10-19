extends Node

func check_children(node):
	for child in node.get_children():
		var mesh_instance = child as MeshInstance
		if is_instance_valid(mesh_instance):
			var shape = mesh_instance.mesh.create_trimesh_shape()
			var static_body: = StaticBody.new()
			var owner_id = static_body.create_shape_owner(static_body)
			static_body.shape_owner_add_shape(owner_id, shape)
			mesh_instance.add_child(static_body)
		check_children(child)

func _ready() -> void:
	check_children(self)
