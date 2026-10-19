extends Node3D

const PlayerScript = preload("res://magnet/player.gd")
const CoreScript = preload("res://magnet/power_core.gd")
const HudScript = preload("res://magnet/hud.gd")
const MINT := Color("7dffdc")
const AMBER := Color("ffb55f")
const DECKS: Array[Vector3] = [Vector3(0,0,0), Vector3(29,2,0), Vector3(58,3,0), Vector3(88,4,0)]
const ANCHOR_POINTS: Array[Vector3] = [Vector3(11,9,0), Vector3(43,12,0), Vector3(73,14,0)]

var player
var hud
var camera: Camera3D
var anchors: Array[Node3D] = []
var anchor_hoops: Array[MeshInstance3D] = []
var cores: Array = []
var collected_count := 0
var elapsed := 0.0
var started := false
var finished := false
var reduced_motion := false
var beam: MeshInstance3D
var receiver: Area3D
var receiver_label: Label3D
var message_time := 0.0
var sound_pool: Array[AudioStreamPlayer] = []

func _ready() -> void:
	build_environment()
	for i in DECKS.size():
		build_deck(DECKS[i], 8.0 if i == 0 else (18.0 if i == 3 else 14.0), i)
	for i in ANCHOR_POINTS.size():
		build_anchor(ANCHOR_POINTS[i], i)
		var core = CoreScript.new()
		add_child(core)
		core.position = ANCHOR_POINTS[i] + Vector3(0, -3, 0)
		core.collected.connect(_on_core_collected)
		cores.append(core)
	build_receiver()
	player = PlayerScript.new()
	add_child(player)
	player.anchors = anchors
	player.position = Vector3(-1, 0.1, 0)
	player.fell.connect(func(): restart_run("FIELD LOST / TRY A DIFFERENT RELEASE TIMING"))
	player.jumped.connect(func(): play_sound("jump", -18, 0.8))
	player.attached.connect(func(): play_sound("coin", -19, 0.7))
	player.released.connect(func(): play_sound("jump", -21, 1.2))
	player.landed.connect(func(): play_sound("land", -17, 0.85))
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	camera.fov = 62
	camera.far = 500
	reset_camera()
	hud = HudScript.new()
	add_child(hud)
	hud.restart_requested.connect(func(): restart_run())
	hud.resume_requested.connect(func(): set_paused(false))
	hud.pause_requested.connect(func():
		if not finished:
			set_paused(not get_tree().paused)
	)
	hud.motion_changed.connect(func(value): reduced_motion = value)
	hud.hint.text = "MOVE RIGHT / JUMP / HOLD E / RELEASE AFTER COLLECTING THE CORE"
	message_time = 6
	beam = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.045
	mesh.bottom_radius = 0.045
	mesh.height = 1
	mesh.radial_segments = 8
	beam.mesh = mesh
	beam.material_override = material(MINT, true)
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(beam)
	beam.visible = false
	for i in 6:
		var audio := AudioStreamPlayer.new()
		add_child(audio)
		sound_pool.append(audio)

func _process(delta: float) -> void:
	if not player or not hud:
		return
	if not started and not finished and (Input.get_vector("move_left", "move_right", "move_forward", "move_back").length() > 0 or Input.is_action_pressed("jump") or Input.is_action_pressed("magnet")):
		started = true
	if started and not finished:
		elapsed += delta
	hud.update_run(elapsed, collected_count, cores.size(), player.velocity.length(), player.active_anchor != null, player.candidate != null)
	message_time = maxf(0, message_time - delta)
	if message_time <= 0:
		hud.hint.text = "ALL CORES RECOVERED / REACH THE RECEIVER" if collected_count == cores.size() else "HOLD E TO PULL / RELEASE TO LAUNCH / AIR CONTROL IS LIMITED"
	var target: Vector3 = player.position + Vector3(3, 8, 16.5)
	camera.position = camera.position.lerp(target, 1 - exp(-6 * delta))
	camera.look_at(player.position + Vector3(5, 4.5, 0))
	camera.fov = lerpf(camera.fov, 62.0 if reduced_motion else 62.0 + minf(player.velocity.length(), 22) * 0.18, minf(1, delta * 5))
	for i in anchors.size():
		var selected: Node3D = player.active_anchor if player.active_anchor else player.candidate
		var chosen: bool = selected == anchors[i]
		anchor_hoops[i].scale = Vector3.ONE * (1.18 if chosen else 1.0)
		anchor_hoops[i].material_override = active_material if chosen else idle_material
	beam.visible = player.active_anchor != null and not finished
	if beam.visible:
		var start: Vector3 = player.global_position + Vector3.UP * 0.8
		var end: Vector3 = player.active_anchor.global_position
		var offset: Vector3 = end - start
		beam.position = start.lerp(end, 0.5)
		beam.quaternion = Quaternion(Vector3.UP, offset.normalized())
		beam.scale = Vector3(1, offset.length(), 1)
	# Poll overlaps as well, so completing collection while inside the receiver is valid.
	if not finished and receiver.overlaps_body(player):
		try_finish()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Engine.max_fps = 15
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		Engine.max_fps = 60

func _exit_tree() -> void:
	for audio in sound_pool:
		audio.stop()
		audio.stream = null

func reset_camera() -> void:
	camera.position = player.position + Vector3(3, 8, 16.5)
	camera.look_at(player.position + Vector3(5, 4.5, 0))

func set_paused(value: bool) -> void:
	get_tree().paused = value
	hud.show_overlay(value)

func restart_run(message := "COLLECT ALL 3 ORANGE CORES / THEN REACH THE EXIT") -> void:
	get_tree().paused = false
	finished = false
	started = false
	elapsed = 0
	collected_count = 0
	update_receiver_label()
	for core in cores:
		core.reset_core()
	player.reset_to(Vector3(-1, 0.1, 0))
	beam.visible = false
	reset_camera()
	hud.show_overlay(false)
	hud.hint.text = message
	message_time = 4

func _on_core_collected(_core) -> void:
	collected_count += 1
	update_receiver_label()
	play_sound("coin", -10, 0.9 + collected_count * 0.2)
	hud.hint.text = "CORE %d / %d  /  RELEASE E TO COAST, HOLD A TO BRAKE" % [collected_count, cores.size()]
	message_time = 2

func try_finish() -> bool:
	if finished:
		return false
	if collected_count != cores.size():
		hud.hint.text = "EXIT LOCKED / COLLECT %d MORE ORANGE CORE(S)" % (cores.size() - collected_count)
		message_time = 3
		return false
	finished = true
	player.release_magnet()
	player.controls_enabled = false
	player.velocity = Vector3.ZERO
	if player.animation:
		player.animation.play("idle", 0.15)
	beam.visible = false
	hud.show_overlay(true, true, elapsed)
	play_sound("coin", -9, 1.5)
	return true

func play_sound(sound: String, volume: float, pitch: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for audio in sound_pool:
		if not audio.playing:
			audio.stream = load("res://sounds/%s.ogg" % sound)
			audio.volume_db = volume
			audio.pitch_scale = pitch
			audio.play()
			break

func material(color: Color, unlit := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	if unlit:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

func box(parent: Node3D, at: Vector3, size_value: Vector3, color: Color, unlit := false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	instance.mesh = mesh
	instance.position = at
	instance.material_override = material(color, unlit)
	parent.add_child(instance)
	return instance

func build_deck(at: Vector3, width: float, index: int) -> void:
	var deck := StaticBody3D.new()
	add_child(deck)
	deck.position = at
	deck.collision_layer = 1
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, 1.1, 7)
	collider.shape = shape
	collider.position.y = -0.5
	deck.add_child(collider)
	box(deck, Vector3(0,-0.5,0), Vector3(width,1,7), Color("153f46"))
	box(deck, Vector3(0,0.025,0), Vector3(width,0.05,7), Color("47696a"))
	box(deck, Vector3(0,-0.45,3.55), Vector3(width,0.15,0.1), AMBER, true)
	box(deck, Vector3(0,-0.45,-3.55), Vector3(width,0.15,0.1), AMBER, true)
	for edge in [-1,1]:
		for stripe in int(width / 0.65):
			var slab := box(deck, Vector3(-width/2+0.35+stripe*0.65,0.065,edge*3.1), Vector3(0.3,0.025,0.7), AMBER if stripe % 2 == 0 else Color("18383b"), true)
			slab.rotation.y = -0.25
	for support in [-1,1]:
		solid_box(deck, Vector3(support*(width/2-1),-4.5,0), Vector3(0.65,8,0.65), Color("1b3b41"))
	var label := Label3D.new()
	label.text = ["01 / INDUCTION", "02 / CARRY", "03 / TRANSFER", "04 / RECEIVER"][index]
	label.font_size = 48
	label.pixel_size = 0.012
	label.rotation_degrees.x = -90
	label.position = Vector3(0, 0.08, 1)
	label.modulate = Color("cae3d8")
	deck.add_child(label)

var active_material: StandardMaterial3D
var idle_material: StandardMaterial3D

func solid_box(parent: Node3D, at: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	var body := StaticBody3D.new()
	parent.add_child(body)
	body.position = at
	body.collision_layer = 1
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collider.shape = shape
	body.add_child(collider)
	return box(body, Vector3.ZERO, dimensions, color)

func build_anchor(at: Vector3, index: int) -> void:
	var anchor := Node3D.new()
	add_child(anchor)
	anchor.position = at
	anchors.append(anchor)
	if not active_material:
		active_material = material(MINT, true)
		idle_material = material(Color("4a9a8d"), true)
	var hoop := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.65
	torus.outer_radius = 0.85
	torus.rings = 32
	torus.ring_segments = 12
	hoop.mesh = torus
	hoop.rotation.x = PI/2
	hoop.material_override = idle_material
	anchor.add_child(hoop)
	anchor_hoops.append(hoop)
	box(anchor, Vector3.ZERO, Vector3(0.5,0.5,0.5), MINT, true)
	solid_box(anchor, Vector3(0,1.5,0), Vector3(0.12,3,0.12), Color("355257"))
	solid_box(anchor, Vector3(0,3,-2.5), Vector3(3,0.6,7), Color("c18a54"))
	solid_box(anchor, Vector3(0,-5,-6), Vector3(0.65,16,0.65), Color("355257"))
	var label := Label3D.new()
	label.text = "FIELD %02d" % (index+1)
	label.font_size = 40
	label.modulate = MINT
	label.position.y = 1.3
	anchor.add_child(label)

func build_receiver() -> void:
	receiver = Area3D.new()
	add_child(receiver)
	receiver.position = DECKS[-1] + Vector3(3,2,0)
	receiver.collision_layer = 0
	receiver.collision_mask = 2
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4,5,5)
	collision.shape = shape
	receiver.add_child(collision)
	box(receiver, Vector3(-1.5,0,0), Vector3(0.3,4.5,0.3), MINT, true)
	box(receiver, Vector3(1.5,0,0), Vector3(0.3,4.5,0.3), MINT, true)
	box(receiver, Vector3(0,2.1,0), Vector3(3.3,0.3,0.3), MINT, true)
	receiver_label = Label3D.new()
	receiver_label.position = Vector3(0,3.3,0)
	receiver_label.font_size = 40
	receiver.add_child(receiver_label)
	update_receiver_label()

func update_receiver_label() -> void:
	var remaining := cores.size() - collected_count
	receiver_label.text = "EXIT UNLOCKED" if remaining == 0 else "EXIT LOCKED\n%d CORES STILL REQUIRED" % remaining
	receiver_label.modulate = MINT if remaining == 0 else AMBER

func build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("103b43")
	sky_mat.sky_horizon_color = Color("8eb8ac")
	sky_mat.ground_bottom_color = Color("0c3039")
	sky_mat.ground_horizon_color = Color("8eb8ac")
	sky_mat.sun_angle_max = 0
	sky.sky_material = sky_mat
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("cae2db")
	environment.ambient_light_energy = 0.65
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42,-35,0)
	sun.light_energy = 1.25
	sun.light_color = Color("ffe3b5")
	sun.shadow_enabled = true
	add_child(sun)
	var rng := RandomNumberGenerator.new()
	rng.seed = 813
	for i in 26:
		var tower := Vector3(rng.randf_range(-30,120), -10, rng.randf_range(-65,-25))
		var height := rng.randf_range(8,28)
		box(self, tower, Vector3(rng.randf_range(3,8),height,rng.randf_range(3,6)), Color("28535a"))
		box(self, tower+Vector3(0,height/2+0.2,0), Vector3(0.18,0.5,0.18), AMBER,true)
	box(self, Vector3(42,-15,-18), Vector3(180,0.8,1), Color("355e5f"))
	box(self, Vector3(42,-7,-22), Vector3(180,0.2,0.2), Color("50716b"))
