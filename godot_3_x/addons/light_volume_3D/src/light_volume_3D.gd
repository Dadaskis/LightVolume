tool 

class_name LightVolume3D, \
	"res://addons/light_volume_3D/assets/icon/icon.png"

extends MeshInstance

const PREFAB_SCENE = preload(
	"res://addons/light_volume_3D/assets/prefab/light_volume0.tscn"
)
const FADE_ANGLE = 80.0
const VOLUME_LOGIC_DISABLE_DISTANCE = 2500.0

export(bool) var reinitialize = false setget set_reinitialize
export(float) var point_scale = 3.0 setget set_point_scale
export(float) var light_scale = 1.5 setget set_light_scale
export(float) var light_alpha = 1.0 setget set_light_alpha
export(float) var volume_scale_x = 1.6 setget set_volume_scale_x
export(float) var volume_scale_y = 1.9 setget set_volume_scale_y
export(Color) var color = Color.aqua setget set_color
export(Color) var color_glow_add = Color.black setget set_color_glow_add
export(bool) var disable_all_in_editor = false setget set_disable_all_in_editor
#export()

var initialized = false
var prefab: Spatial
var glow: MeshInstance
var glow_mat: ShaderMaterial
var volume: MeshInstance
var volume_mat: ShaderMaterial
var update_timer = 0.0

var disable_all_in_editor_no_logic = false

func on_enabled_in_editor():
	disable_all_in_editor_no_logic = true
	set_disable_all_in_editor(false)
	disable_all_in_editor_no_logic = false

func on_disabled_in_editor():
	disable_all_in_editor_no_logic = true
	set_disable_all_in_editor(true)
	disable_all_in_editor_no_logic = false

func set_disable_all_in_editor(value):
	disable_all_in_editor = value
	get_child(0).visible = not disable_all_in_editor
	if disable_all_in_editor_no_logic:
		return
	if disable_all_in_editor:
		LightVolume3DCamera.make_disabled_in_editor()
	else:
		LightVolume3DCamera.make_enabled_in_editor()

func set_point_scale(value):
	point_scale = value
	if not is_instance_valid(prefab):
		return
	prefab.scale = Vector3(point_scale, point_scale, point_scale)

func set_light_scale(value):
	light_scale = value
	if not is_instance_valid(prefab):
		return
	glow.scale = Vector3(light_scale, light_scale, light_scale)

func set_volume_scale_x(value):
	volume_scale_x = value
	if not is_instance_valid(prefab):
		return
	volume.scale.x = volume_scale_x

func set_volume_scale_y(value):
	volume_scale_y = value
	if not is_instance_valid(prefab):
		return
	volume.scale.y = volume_scale_y

func set_light_alpha(value):
	light_alpha = value
	if not is_instance_valid(prefab):
		return
	
	var glow_color = glow_mat.get_shader_param("albedo_alpha_color")
	var light_alpha_color = Color(
		glow_color.r, glow_color.g, glow_color.b, light_alpha)
	glow_mat.set_shader_param("albedo_alpha_color", light_alpha_color)

func set_color(value):
	color = value
	
	if not is_instance_valid(prefab):
		return
	
	volume_mat.set_shader_param("albedo_alpha_color", color)
	glow_mat.set_shader_param("albedo_alpha_color", color)
	
	set_light_alpha(light_alpha)

func set_color_glow_add(value):
	set_color(color)
	color_glow_add = value
	
	if not is_instance_valid(prefab):
		return
	
	glow_mat.set_shader_param(
		"albedo_alpha_color", color + color_glow_add)
	set_light_alpha(light_alpha)

func set_reinitialize(value):
	if reinitialize == value:
		return
	reinitialize = false
	initialized = false
	for child in get_children():
		child.queue_free()
	yield(VisualServer, "frame_post_draw")
	yield(VisualServer, "frame_post_draw")
	yield(VisualServer, "frame_post_draw")
	initialize()

func create_prefab():
	if get_node_or_null("__PREFAB"):
		var prev_prefab = get_node_or_null("__PREFAB")
		prev_prefab.name = "__REMOVE"
		prev_prefab.queue_free()
	prefab = PREFAB_SCENE.instance()
	prefab.name = "__PREFAB"
	add_child(prefab)
	
	glow = prefab.get_node_or_null("glow0")
	glow_mat = glow.get_surface_material(0).duplicate()
	glow.set_surface_material(0, glow_mat)
	
	volume = prefab.get_node_or_null("volume0")
	volume_mat = volume.get_surface_material(0).duplicate()
	volume.set_surface_material(0, volume_mat)
	
	glow.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	volume.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	
	set_point_scale(point_scale)
	set_light_scale(light_scale)
	set_volume_scale_x(volume_scale_x)
	set_volume_scale_y(volume_scale_y)
	set_color(color)
	set_color_glow_add(color_glow_add)
	set_light_alpha(light_alpha)

func initialize():
	if initialized:
		return
	initialized = true
	create_prefab()
	if Engine.editor_hint:
		var cube = CubeMesh.new()
		cube.size = Vector3(0.2, 0.2, 0.2)
		mesh = cube
		var mat: = SpatialMaterial.new()
		mat.albedo_color = Color(0.6, 0.1, 0.1)
		mat.flags_unshaded = true
		mat.params_blend_mode = SpatialMaterial.BLEND_MODE_ADD
		material_override = mat
	else:
		mesh = null
	set_physics_process(true)

func on_camera_change():
	set_physics_process(true)

func _ready():
	initialize()
	LightVolume3DCamera.connect("camera_changed", self, "on_camera_change")
	LightVolume3DCamera.connect(
		"enabled_in_editor", self, "on_enabled_in_editor")
	LightVolume3DCamera.connect(
		"disabled_in_editor", self, "on_disabled_in_editor")

func _physics_process(delta: float) -> void:
	#if Engine.editor_hint:
	#	return
	
	set_meta("_edit_group_", true)
	get_child(0).set_meta("_edit_lock_", true)
	
	update_timer += delta
	
	var camera = LightVolume3DCamera.camera
	if not is_instance_valid(camera):
		print_debug("[LightVolume3D] Invalid camera node! Disabling updating.")
		set_physics_process(false)
		return
	if not is_instance_valid(volume):
		return
	
	var cam_pos = camera.global_transform.origin
	var volume_pos = volume.global_transform.origin
	var distance = cam_pos.distance_squared_to(volume_pos)
	if distance > VOLUME_LOGIC_DISABLE_DISTANCE:
		return
	
	var timer_delay = distance * 0.005
	timer_delay = min(timer_delay, 0.6)
	if update_timer < timer_delay:
		return
	update_timer = 0.0
	
	var up_vector = global_transform.basis.y
	var direction = volume_pos.direction_to(cam_pos)
	volume.global_transform = \
		volume.global_transform.looking_at(cam_pos, up_vector)
	volume.rotation_degrees.x = 0.0
	volume.rotation_degrees.z = 0.0
	set_volume_scale_x(volume_scale_x)
	set_volume_scale_y(volume_scale_y)
	
	var fade_angle = rad2deg((up_vector.abs()).angle_to(direction.abs()))
	fade_angle = min(fade_angle, FADE_ANGLE)
	fade_angle = max(fade_angle, 0.0)
	var fade_blend = fade_angle / FADE_ANGLE
	volume_mat.set_shader_param(
		"albedo_alpha_color",
		lerp(Color(0.0, 0.0, 0.0, 0.0), color, fade_blend)
	)
