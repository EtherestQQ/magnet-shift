extends SceneTree

var failures := 0
func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + message)

func run() -> void:
	if not ResourceLoader.exists("res://magnet/player.gd"):
		push_error("FAIL: magnetic controller is not implemented")
		quit(1)
		return
	var player = load("res://magnet/player.gd").new()
	player.set_physics_process(false)
	root.add_child(player)
	player.global_position = Vector3(0, 10, 0)
	var anchor := Node3D.new()
	root.add_child(anchor)
	anchor.position = Vector3(8, 15, 0)
	await physics_frame
	check(player.attach_to(anchor), "Visible in-range anchor accepts attachment")
	player.velocity = Vector3(3, 2, 1)
	player.apply_attraction(0.1)
	check(player.velocity.x > 3 and player.velocity.y > 2, "Attraction accelerates toward the anchor")
	var carried: Vector3 = player.velocity
	player.release_magnet()
	check(player.velocity == carried, "Release itself must preserve exact velocity")
	check(player.active_anchor == null, "Release clears attachment")
	anchor.position = Vector3(100, 15, 0)
	check(not player.attach_to(anchor), "Out-of-range attachment must fail")
	anchor.position = Vector3(8, 15, 0)
	player.reset_to(Vector3(0,10,0))
	player.anchors.assign([anchor])
	anchor.position = Vector3(100,15,0)
	player.set_physics_process(true)
	Input.action_press("magnet")
	await physics_frame
	await physics_frame
	anchor.position = Vector3(8,15,0)
	await physics_frame
	await physics_frame
	check(player.active_anchor == anchor, "Holding E before entering range must attach when valid")
	Input.action_release("magnet")
	await physics_frame
	player.set_physics_process(false)
	player.reset_to(Vector3(0,10,0))
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1, 12, 8)
	collision.shape = box
	wall.add_child(collision)
	root.add_child(wall)
	wall.position = Vector3(4, 12, 0)
	await physics_frame
	await physics_frame
	check(not player.attach_to(anchor), "Solid scenery must block magnetic targeting")
	wall.queue_free()
	await physics_frame
	await physics_frame
	var hanger := StaticBody3D.new()
	anchor.add_child(hanger)
	var hanger_collision := CollisionShape3D.new()
	var rod := BoxShape3D.new()
	rod.size = Vector3(0.12,3,0.12)
	hanger_collision.shape = rod
	hanger_collision.position.y = 1.5
	hanger.add_child(hanger_collision)
	await physics_frame
	await physics_frame
	check(player.attach_to(anchor), "Anchor surface must remain reachable below its own hanger")
	player.reset_to(Vector3(1, 2, 3))
	check(player.velocity == Vector3.ZERO and player.active_anchor == null, "Reset clears attachment and momentum")
	player.queue_free()
	anchor.queue_free()
	await process_frame
	print("MAGNET CONTROLLER: %d failures" % failures)
	quit(1 if failures else 0)
