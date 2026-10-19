extends Node
## Reserve a localhost-only port before loading the level, including across build folders.
const INSTANCE_PORT := 43761
var instance_guard := TCPServer.new()

func claim_instance() -> bool:
	return instance_guard.listen(INSTANCE_PORT, "127.0.0.1") == OK

func _ready() -> void:
	if DisplayServer.get_name() != "headless" and not claim_instance():
		print("Magnet Shift is already running, or its instance port is unavailable. Closing this copy.")
		get_tree().quit()
		return

func _exit_tree() -> void:
	instance_guard.stop()
