extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var guard_script = load("res://magnet/boot.gd")
	var first = guard_script.new()
	var second = guard_script.new()
	check(first.claim_instance(), "First instance must claim its port")
	check(not second.claim_instance(), "Second instance must not claim the same port")
	first.instance_guard.stop()
	check(second.claim_instance(), "Closing the first instance must permit a restart")
	first.free()
	second.free()
	var course = load("res://magnet/course.tscn").instantiate()
	root.add_child(course)
	course.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(Engine.max_fps == 15, "Background game must be limited to 15 FPS")
	course.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(Engine.max_fps == 60, "Foreground game must be limited to 60 FPS")
	course.queue_free()
	await process_frame
	print("MAGNET RUNTIME: %d failures" % failures)
	quit(1 if failures else 0)
