extends Resource

enum ColorMode { STATIC, CHOOSE, BLINK, FADE }
enum FadeMode { NONE, LINEAR, LATE, IN_AND_OUT }

@export var textures: Array[Texture2D] = []
@export var color := Color.WHITE
@export var color2 := Color.WHITE
@export var color_mode := ColorMode.STATIC
@export var fade_mode := FadeMode.NONE
@export var size := 1.0
@export var size_range := 0.0
@export var life_min := 1.0
@export var life_max := 1.0
@export var speed_min := 0.0
@export var speed_max := 0.0
@export var acceleration := Vector2.ZERO
@export var friction := 0.0
@export var direction := 0.0
@export var direction_range := 0.0
@export var scale_out := false
@export var random_rotation := false
