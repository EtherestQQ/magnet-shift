extends CanvasLayer

signal restart_requested
signal resume_requested
signal motion_changed(value)
signal pause_requested

var timer_label: Label
var cores_label: Label
var energy_label: Label
var hint: Label
var objective: Label
var progress: ProgressBar
var overlay: Panel
var overlay_title: Label
var overlay_body: Label
var root: Control
const MINT := Color("7dffdc")
const INK := Color("092e37")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	panel(Vector2(28, 25), Vector2(265, 88))
	text("MAGNET / SHIFT", Vector2(46, 34), 27, Color.WHITE)
	text("ATTRACT. RELEASE. KEEP YOUR MOMENTUM.", Vector2(47, 75), 11, MINT)
	panel(Vector2(920, 25), Vector2(330, 88))
	timer_label = text("00.00", Vector2(940, 34), 30, Color.WHITE)
	cores_label = text("CORES   0 / 3", Vector2(1090, 45), 16, MINT)
	energy_label = text("FIELD READY", Vector2(940, 78), 11, MINT)
	progress = ProgressBar.new()
	progress.position = Vector2(30, 127)
	progress.size = Vector2(1220, 3)
	progress.show_percentage = false
	var track := StyleBoxFlat.new()
	track.bg_color = Color("192943")
	var fill := StyleBoxFlat.new()
	fill.bg_color = MINT
	progress.add_theme_stylebox_override("background", track)
	progress.add_theme_stylebox_override("fill", fill)
	root.add_child(progress)
	progress.size = Vector2(1220, 3)
	objective = text("COLLECT ALL 3 ORANGE CORES TO UNLOCK THE EXIT", Vector2(300, 48), 18, Color("ffb55f"))
	objective.size.x = 610
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint = text("FOLLOW THE MINT RINGS", Vector2(0, 140), 18, Color.WHITE)
	hint.size.x = 1280
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel(Vector2(285, 653), Vector2(710, 42))
	var controls := text("A/D MOVE   W/S DEPTH   SPACE JUMP   HOLD E ATTRACT   RELEASE E COAST   R RESTART   ESC PAUSE", Vector2(300, 665), 12, Color("bfcee0"))
	controls.size.x = 680
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text("01 / FOUNDRY CROSSING", Vector2(30, 676), 11, Color("8ba3c7"))
	text("GODOT 4  /  PROTOTYPE", Vector2(1085, 676), 11, Color("8ba3c7"))
	overlay = panel(Vector2(400, 235), Vector2(480, 270))
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_title = text("PAUSED", Vector2(430, 263), 34, Color.WHITE)
	overlay_body = text("The field is on hold.", Vector2(430, 315), 16, Color("bfcee0"))
	var resume := button("CONTINUE", Vector2(430, 362), func(): resume_requested.emit())
	resume.name = "Continue"
	button("RESTART RUN", Vector2(646, 362), func(): restart_requested.emit())
	var toggle := CheckButton.new()
	toggle.text = "Reduced motion"
	toggle.position = Vector2(430, 426)
	toggle.add_theme_font_size_override("font_size", 14)
	toggle.toggled.connect(func(value): motion_changed.emit(value))
	root.add_child(toggle)
	# Overlay children use a separate group so they can all hide together.
	for child in root.get_children():
		if child == overlay or child.position.y >= 235 and child.position.y <= 470:
			child.add_to_group("pause_ui")
	show_overlay(false)

func _unhandled_input(event: InputEvent) -> void:
	# Input must remain active even while the gameplay tree is paused.
	if event.is_action_pressed("restart"):
		restart_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause_run"):
		pause_requested.emit()
		get_viewport().set_input_as_handled()

func style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = 9
	s.corner_radius_top_right = 9
	s.corner_radius_bottom_left = 9
	s.corner_radius_bottom_right = 9
	return s

func panel(pos: Vector2, dimensions: Vector2) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = dimensions
	p.add_theme_stylebox_override("panel", style(Color(0.015, 0.095, 0.11, 0.94)))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(p)
	return p

func text(content: String, pos: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = content
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(label)
	return label

func button(content: String, pos: Vector2, action: Callable) -> Button:
	var b := Button.new()
	b.text = content
	b.position = pos
	b.size = Vector2(200, 44)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_stylebox_override("normal", style(MINT))
	b.add_theme_stylebox_override("hover", style(Color.WHITE))
	b.pressed.connect(action)
	root.add_child(b)
	return b

func update_run(seconds: float, count: int, total: int, speed: float, latched: bool, in_range: bool) -> void:
	timer_label.text = "%05.2f" % seconds
	cores_label.text = "CORES   %d / %d" % [count, total]
	var unlocked := count >= total
	objective.text = "EXIT UNLOCKED / REACH THE RECEIVER" if unlocked else "COLLECT ALL %d ORANGE CORES TO UNLOCK THE EXIT" % total
	objective.add_theme_color_override("font_color", MINT if unlocked else Color("ffb55f"))
	cores_label.add_theme_color_override("font_color", MINT if unlocked else Color("ffb55f"))
	var state := "FIELD ACTIVE / RELEASE E TO COAST" if latched else ("ANCHOR IN RANGE / HOLD E" if in_range else "MOVE CLOSER TO AN ANCHOR")
	energy_label.text = "%s    %.1f m/s" % [state, speed]
	energy_label.add_theme_color_override("font_color", MINT if latched else Color("ffb55f"))
	progress.value = float(count) / maxf(1, total) * 100

func show_overlay(shown: bool, completed := false, seconds := 0.0) -> void:
	for node in get_tree().get_nodes_in_group("pause_ui"):
		node.visible = shown
	overlay_title.text = "POWER RESTORED" if completed else "PAUSED"
	overlay_title.add_theme_font_size_override("font_size", 28 if completed else 34)
	overlay_body.text = "%.2f seconds. One more run?" % seconds if completed else "The field is on hold."
	root.get_node("Continue").disabled = completed
