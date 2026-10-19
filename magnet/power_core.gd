extends Area3D

signal collected(core)
var consumed := false
var mesh: MeshInstance3D
var rest_height := 0.0
var clock := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var collider := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.8
	collider.shape = sphere
	add_child(collider)
	mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.8
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("ffb55f")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	add_child(mesh)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	clock += delta
	mesh.rotation = Vector3(clock * 0.5, clock, PI / 4)
	mesh.position.y = sin(clock * 2) * 0.15

func _on_body_entered(body: Node3D) -> void:
	if consumed or not body.has_method("attach_to"):
		return
	consumed = true
	mesh.visible = false
	collected.emit(self)

func reset_core() -> void:
	consumed = false
	mesh.visible = true
