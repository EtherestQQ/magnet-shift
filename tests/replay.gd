extends SceneTree
## Test-only pilot. Positions and velocities are never overridden during traversal.

var course
var frame := 0
var capture := false
var failed := false

func _initialize() -> void:
	call_deferred("run")

func steer(amount: float) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	if amount > 0:
		Input.action_press("move_right", minf(amount,1))
	elif amount < 0:
		Input.action_press("move_left", minf(-amount,1))

func tick(count := 1) -> void:
	for i in count:
		await physics_frame
		frame += 1
		if capture and frame in [60,130,175,260,390,520,720]:
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../magnet-preview-%04d.png" % frame)

func tap(action: String) -> void:
	Input.action_press(action)
	await tick()
	Input.action_release(action)

func run() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	course = load("res://magnet/course.tscn").instantiate()
	root.add_child(course)
	current_scene = course
	await tick(70)
	for hop in 3:
		var start: Vector3 = course.DECKS[hop]
		var target: Vector3 = course.DECKS[hop+1]
		var edge: float = start.x + (3.0 if hop == 0 else 6.0)
		steer(1)
		var guard := 0
		while course.player.position.x < edge and guard < 180:
			await tick()
			guard += 1
		await tap("jump")
		Input.action_press("magnet")
		var got_core := false
		for i in 180:
			await tick()
			if "--trace" in OS.get_cmdline_user_args() and i % 12 == 0:
				print("PULL %d.%d p=%s v=%s latched=%s" % [hop+1,i,course.player.position,course.player.velocity,course.player.active_anchor != null])
			if course.cores[hop].consumed:
				got_core = true
				break
			if course.player.position.y < -8:
				break
		Input.action_release("magnet")
		print("RELEASE %d: core=%s p=%s v=%s" % [hop+1,got_core,course.player.position,course.player.velocity])
		if not got_core:
			failed = true
			break
		var landed := false
		for i in 240:
			var p: Vector3 = course.player.position
			var v: Vector3 = course.player.velocity
			var height: float = p.y - (target.y + 0.05)
			var discriminant: float = maxf(0, v.y * v.y + 2 * course.player.gravity_force * height)
			var flight: float = maxf(0.1, (v.y + sqrt(discriminant)) / course.player.gravity_force)
			var predicted: float = p.x + v.x * flight
			steer(clampf((target.x-predicted)*0.3,-1,1))
			await tick()
			if course.player.is_on_floor() and absf(course.player.position.x-target.x) < 7.2:
				landed = true
				break
			if course.finished:
				landed = true
				break
			if p.y < -8:
				break
		print("HOP %d: %s p=%s cores=%d" % [hop+1,"FINISHED IN AIR" if course.finished and not course.player.is_on_floor() else ("LANDED" if landed else "FAILED"),course.player.position,course.collected_count])
		if not landed:
			failed = true
			break
		steer(0)
		await tick(35)
	if not failed:
		steer(1)
		for i in 180:
			await tick()
			if course.finished:
				break
		failed = not course.finished
	steer(0)
	Input.action_release("magnet")
	print("MAGNET REPLAY %s | cores %d/3 | %.2fs" % ["FAIL" if failed else "PASS",course.collected_count,course.elapsed])
	await tick(100)
	if capture:
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../magnet-preview-finish.png")
	course.queue_free()
	await process_frame
	await process_frame
	quit(1 if failed else 0)
