
const NONE := Vector2(INF, INF)

const OFFSETS := {
	&"idle": [Vector2(0, -2), Vector2(0, -2), Vector2(0, -2), Vector2(0, -2), Vector2(0, -1), Vector2(0, -1), Vector2(0, -1), Vector2(0, -1), Vector2(0, -1)],
	&"idle_a": [Vector2(0, -2), Vector2(-1, -2), Vector2(-2, -2), Vector2(-2, -2), Vector2(-2, -2), Vector2(-2, -1), Vector2(-2, -1), Vector2(-2, -1), Vector2(-2, -1), Vector2(-1, -1), Vector2(0, -1), Vector2(0, -1)],
	&"idle_b": [Vector2(0, -2), Vector2(-1, -2), Vector2(-1, -2), Vector2(-1, -2), Vector2(-1, -2), Vector2(-1, -2), Vector2(-1, -2), Vector2(-1, -2), Vector2(-1, -2), Vector2(-2, -2), Vector2(-2, -2), Vector2(-2, -2), Vector2(-2, -2), Vector2(-1, -2), Vector2(-1, -2), Vector2(-1, -2), Vector2(-1, -2), Vector2(0, -2), Vector2(0, -2), Vector2(0, -1), Vector2(0, -1), Vector2(0, -1), Vector2(0, -1), Vector2(0, -1)],
	&"idle_c": [Vector2(-1, -2), Vector2(-2, -2), Vector2(-2, -2), Vector2(-2, -2), Vector2(-2, -2), Vector2(-2, -2), Vector2(2, -1), Vector2(3, 0), Vector2(0, 0), Vector2(-1, -1), Vector2(0, -1), Vector2(0, -2)],
	&"run_slow": [Vector2(1, -2), Vector2(1, -1), Vector2(1, -1), Vector2(1, -1), Vector2(1, -3), Vector2(1, -2), Vector2(1, -1), Vector2(1, -1), Vector2(1, -1), Vector2(1, -1), Vector2(1, -3), Vector2(1, -2)],
	&"run_fast": [Vector2(1, -2), Vector2(1, -1), Vector2(1, -1), Vector2(1, -1), Vector2(1, -3), Vector2(1, -2), Vector2(1, -1), Vector2(1, -1), Vector2(1, -1), Vector2(1, -1), Vector2(1, -3), Vector2(1, -2)],
	&"run_stumble": [Vector2(1, 0), Vector2(1, 2), Vector2(1, 1), Vector2(1, 0), Vector2(1, -2), Vector2(1, -2), Vector2(1, -1), Vector2(1, -1), Vector2(1, -1), Vector2(1, -1), Vector2(1, -3), Vector2(1, -2)],
	&"jump_slow": [Vector2(1, -3), Vector2(1, -3), Vector2(1, -2), Vector2(0, -2)],
	&"jump_fast": [Vector2(1, -3), Vector2(1, -3), Vector2(1, -2), Vector2(0, -2)],
	&"fall_slow": [Vector2(1, -2), Vector2(1, -2), Vector2(1, -2), Vector2(1, -2), Vector2(1, -2), Vector2(1, -2), Vector2(1, -2), Vector2(1, -2)],
	&"fall_fast": [Vector2(1, -2), Vector2(1, -2), Vector2(1, -2), Vector2(1, -2)],
	&"dash": [Vector2(2, -1), Vector2(2, -1), Vector2(2, -1), Vector2(2, 0)],
	&"duck": [Vector2(0, 2)],
	&"wall_slide": [Vector2(1, -2)],
	&"climb_up": [Vector2(1, -2), Vector2(1, -2), Vector2(1, -2), Vector2(0, -2), Vector2(0, -2), Vector2(1, -2), Vector2(1, -2), Vector2(1, -2)],
	&"climb_look_back_start": [Vector2(0, -2), Vector2(-1, -2)],
	&"climb_look_back": [Vector2(-2, -2)],
	&"dangling": [Vector2(1, -2), Vector2(1, -2), Vector2(1, -2), Vector2(1, -2), Vector2(0, -2), Vector2(0, -2), Vector2(0, -2), Vector2(0, -2), Vector2(0, -2), Vector2(0, -2)],
	&"push": [Vector2(1, -2), Vector2(1, -1), Vector2(1, -1), Vector2(1, -1), Vector2(1, -2), Vector2(1, -2), Vector2(1, -2), Vector2(1, -2), Vector2(1, -1), Vector2(1, -1), Vector2(1, -1), Vector2(1, -1), Vector2(1, -2), Vector2(1, -2), Vector2(1, -2), Vector2(1, -2)],
	&"look_up": [Vector2(0, -2), Vector2(0, -1), Vector2(0, -2), Vector2(0, -2), Vector2(-1, -2), Vector2(-1, -2), Vector2(-1, -3), Vector2(-1, -3)],
	&"edge": [Vector2(-1, -2), Vector2(-1, -2), Vector2(-1, -2), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -2), Vector2(0, -2), Vector2(1, -2), Vector2(0, -2), Vector2(0, -1), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -2)],
	&"edge_back": [Vector2(1, -2), Vector2(1, -2), Vector2(0, -2), Vector2(0, -1), Vector2(-1, -2), Vector2(0, -2), Vector2(1, -2), Vector2(0, -2), Vector2(1, -2), Vector2(1, -2), Vector2(2, -1), Vector2(2, -1), Vector2(2, -1), Vector2(2, -2)],
	&"flip": [Vector2(-2, -1), Vector2(-1, -1), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), Vector2(2, 0), Vector2(2, 0), Vector2(2, 0), Vector2(2, 0)],
	&"skid": [Vector2(-2, -1), Vector2(-1, -1), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), Vector2(2, 0), Vector2(2, 0), Vector2(2, 0), Vector2(2, 0)],
}

const BANGS := {
	&"wall_slide": 2,
	&"climb_up": 2,
	&"dangling": 2,
	&"look_up": 1,
}


static func get_offset(animation: StringName, frame: int) -> Vector2:
	var frames: Array = OFFSETS.get(animation, [])
	if frame >= frames.size():
		return NONE
	return frames[frame]


static func get_bangs(animation: StringName) -> int:
	return BANGS.get(animation, 0)
