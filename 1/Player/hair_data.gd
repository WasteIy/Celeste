
const NONE := Vector2(INF, INF)

const OFFSETS := {
	&"idle": [Vector2(0, -2), Vector2(0, -2), Vector2(0, -2), Vector2(0, -2), Vector2(0, -1), Vector2(0, -1), Vector2(0, -1), Vector2(0, -1), Vector2(0, -1)],
	&"run_fast": [Vector2(1, -2), Vector2(1, -1), Vector2(1, -1), Vector2(1, -1), Vector2(1, -3), Vector2(1, -2), Vector2(1, -1), Vector2(1, -1), Vector2(1, -1), Vector2(1, -1), Vector2(1, -3), Vector2(1, -2)],
	&"jump_fast": [Vector2(1, -3), Vector2(1, -3), Vector2(1, -2), Vector2(0, -2)],
	&"fall_slow": [Vector2(1, -2), Vector2(1, -2), Vector2(1, -2), Vector2(1, -2), Vector2(1, -2), Vector2(1, -2), Vector2(1, -2), Vector2(1, -2)],
	&"dash": [Vector2(2, -1), Vector2(2, -1), Vector2(2, -1), Vector2(2, 0)],
}

const BANGS := {
}


static func get_offset(animation: StringName, frame: int) -> Vector2:
	var frames: Array = OFFSETS.get(animation, [])
	if frame >= frames.size():
		return NONE
	return frames[frame]


static func get_bangs(animation: StringName) -> int:
	return BANGS.get(animation, 0)
