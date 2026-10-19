extends SceneTree

var failures := 0
func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + message)

func press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame

func run() -> void:
	var course = load("res://magnet/course.tscn").instantiate()
	root.add_child(course)
	current_scene = course
	await process_frame
	await physics_frame
	var girder_center: Vector3 = course.anchors[0].position + Vector3(0,3,0)
	var ray := PhysicsRayQueryParameters3D.create(girder_center + Vector3(3,0,0), girder_center - Vector3(3,0,0), 1)
	check(not course.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "Foreground gantry must have solid collision")
	check(not course.try_finish(), "Missing cores must block completion")
	check(course.hud.hint.text.contains("3 MORE") and course.message_time > 0, "Locked exit explains the missing core count")
	check(course.receiver_label.text.contains("LOCKED"), "Receiver starts locked")
	# Core pickup must happen through a physics overlap and only once.
	course.player.set_physics_process(false)
	course.player.position = course.cores[0].position
	for i in 4:
		await physics_frame
	check(course.collected_count == 1, "Player overlap collects one core")
	check(course.receiver_label.text.contains("2 CORES"), "Receiver updates the required count after pickup")
	for i in 4:
		await physics_frame
	check(course.collected_count == 1, "Remaining inside core does not count twice")
	course.player.attach_to(course.anchors[0])
	course.player.velocity = Vector3(20,10,1)
	course.elapsed = 12
	course.restart_run()
	check(course.player.active_anchor == null and course.player.velocity == Vector3.ZERO, "Restart clears field and momentum")
	check(course.collected_count == 0 and course.elapsed == 0, "Restart clears progress and clock")
	check(not course.cores[0].consumed and course.cores[0].mesh.visible, "Restart restores core visibility")
	course.started = true
	course.elapsed = 4
	course.set_paused(true)
	await create_timer(0.15, true).timeout
	check(course.elapsed == 4, "Pause freezes timer")
	await press("pause_run")
	check(not paused, "Escape resumes from pause")
	course.set_paused(true)
	await press("restart")
	check(not paused and course.elapsed == 0, "R restarts while paused")
	# Move into receiver while airborne using physics; no direct try_finish call.
	course.collected_count = course.cores.size()
	course.update_receiver_label()
	await process_frame
	check(course.receiver_label.text == "EXIT UNLOCKED" and course.hud.objective.text.begins_with("EXIT UNLOCKED"), "All cores visibly unlock the exit")
	course.player.reset_to(course.receiver.position + Vector3(-4,0,0))
	course.player.velocity = Vector3(12,2,0)
	course.player.set_physics_process(true)
	for i in 30:
		await physics_frame
		if course.finished:
			break
	check(course.finished and not course.player.is_on_floor(), "Receiver accepts an airborne approach")
	check(course.player.active_anchor == null and not course.beam.visible, "Victory clears the magnetic beam")
	course.restart_run()
	check(not course.finished and course.player.controls_enabled, "Restart after victory restores movement")
	await create_timer(0.4).timeout
	course.queue_free()
	await process_frame
	print("MAGNET COURSE: %d failures" % failures)
	quit(1 if failures else 0)
