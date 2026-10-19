extends CharacterBody3D
## Radial attraction changes acceleration; releasing never resets launch velocity.

signal attached
signal released
signal jumped
signal landed
signal fell

@export var run_speed := 6.5
@export var ground_acceleration := 42.0
@export var air_acceleration := 8.0
@export var jump_speed := 9.0
@export var gravity_force := 20.0
@export var attraction_force := 56.0
@export var magnet_range := 24.0
@export var max_speed := 25.0

var active_anchor: Node3D
var candidate: Node3D
var anchors: Array[Node3D] = []
var controls_enabled := true
var facing := Vector3.RIGHT
var coyote_left := 0.0
var jump_buffer := 0.0
var visual: Node3D
var animation: AnimationPlayer

func _ready() -> void:
	name = "MagnetRunner"
	collision_layer = 2
	collision_mask = 1
	setup_inputs()
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.2
	collider.shape = capsule
	collider.position.y = 0.6
	add_child(collider)
	if ResourceLoader.exists("res://objects/character.tscn"):
		visual = load("res://objects/character.tscn").instantiate()
		add_child(visual)
		animation = visual.get_node_or_null("AnimationPlayer")

func setup_inputs() -> void:
	for entry in [["move_left", KEY_A], ["move_right", KEY_D], ["move_forward", KEY_W], ["move_back", KEY_S], ["jump", KEY_SPACE], ["magnet", KEY_E], ["restart", KEY_R], ["pause_run", KEY_ESCAPE]]:
		if InputMap.has_action(entry[0]):
			continue
		InputMap.add_action(entry[0])
		var event := InputEventKey.new()
		event.physical_keycode = entry[1]
		InputMap.action_add_event(entry[0], event)

func _physics_process(delta: float) -> void:
	if not controls_enabled:
		return
	var axes := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(axes.x, 0, axes.y)
	if direction.length_squared() > 0.01:
		facing = direction.normalized()
	candidate = select_anchor()
	if Input.is_action_pressed("magnet") and not active_anchor and candidate:
		attach_to(candidate)
	if not Input.is_action_pressed("magnet") and active_anchor:
		release_magnet()
	if active_anchor:
		if not is_instance_valid(active_anchor) or global_position.distance_to(active_anchor.global_position) > magnet_range * 1.2 or not has_line_of_sight(active_anchor):
			release_magnet()
	var on_ground := is_on_floor()
	if on_ground:
		coyote_left = 0.12
		velocity.x = move_toward(velocity.x, direction.x * run_speed, ground_acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * run_speed, ground_acceleration * delta)
		if velocity.y < 0:
			velocity.y = 0
	else:
		coyote_left = maxf(0, coyote_left - delta)
		velocity += direction * air_acceleration * delta
	velocity.y -= gravity_force * delta
	jump_buffer = maxf(0, jump_buffer - delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.12
	if jump_buffer > 0 and coyote_left > 0:
		velocity.y = jump_speed
		jump_buffer = 0
		coyote_left = 0
		jumped.emit()
	if active_anchor:
		apply_attraction(delta)
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
	move_and_slide()
	if is_on_floor() and not on_ground:
		landed.emit()
	if visual:
		var aim := Vector3(velocity.x, 0, velocity.z) if velocity.length_squared() > 0.5 else facing
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(aim.x, aim.z), minf(1, delta * 10))
	if animation:
		var next := "jump" if not is_on_floor() else ("walk" if Vector2(velocity.x, velocity.z).length() > 0.4 else "idle")
		if animation.current_animation != next and animation.has_animation(next):
			animation.play(next, 0.15)
	if position.y < -15:
		fell.emit()

func select_anchor() -> Node3D:
	var selected: Node3D
	var best := INF
	for anchor in anchors:
		if not is_instance_valid(anchor):
			continue
		var offset := anchor.global_position - global_position
		if offset.x * (1.0 if facing.x >= 0 else -1.0) < 0.8:
			continue
		var distance := offset.length()
		if distance <= magnet_range and distance < best and has_line_of_sight(anchor):
			selected = anchor
			best = distance
	return selected

func has_line_of_sight(anchor: Node3D) -> bool:
	var start := global_position + Vector3.UP * 0.6
	var offset := anchor.global_position - start
	# Aim at the field surface, not inside the solid hanger terminating at its center.
	var end := anchor.global_position - offset.normalized() * minf(0.35, offset.length() * 0.5)
	var query := PhysicsRayQueryParameters3D.create(start, end, 1)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func attach_to(anchor: Node3D) -> bool:
	if not controls_enabled or not is_instance_valid(anchor) or global_position.distance_to(anchor.global_position) > magnet_range or not has_line_of_sight(anchor):
		return false
	active_anchor = anchor
	attached.emit()
	return true

func apply_attraction(delta: float) -> void:
	if not is_instance_valid(active_anchor):
		return
	var offset := active_anchor.global_position - (global_position + Vector3.UP * 0.6)
	# Soft radial field avoids a singularity at the anchor; tangent velocity is retained.
	var strength := minf(1.0, offset.length() / 2.0)
	velocity += offset.normalized() * attraction_force * strength * delta

func release_magnet() -> void:
	if not active_anchor:
		return
	active_anchor = null
	released.emit()

func reset_to(at: Vector3) -> void:
	release_magnet()
	global_position = at
	velocity = Vector3.ZERO
	candidate = null
	coyote_left = 0
	jump_buffer = 0
	facing = Vector3.RIGHT
	controls_enabled = true
