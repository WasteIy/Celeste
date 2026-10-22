extends Node

var _timer := 0.0
var _last_ticks := 0


func _ready() -> void:
	add_to_group(&"freeze")
	process_mode = Node.PROCESS_MODE_ALWAYS


func freeze(duration: float) -> void:
	_timer = maxf(_timer, duration)
	_last_ticks = Time.get_ticks_usec()
	Engine.time_scale = 0.0


func _process(_delta: float) -> void:
	if _timer <= 0.0:
		return
	var now := Time.get_ticks_usec()
	_timer -= (now - _last_ticks) / 1_000_000.0
	_last_ticks = now
	if _timer <= 0.0:
		Engine.time_scale = 1.0
