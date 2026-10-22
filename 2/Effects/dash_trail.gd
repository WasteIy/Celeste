extends CanvasGroup

const MadelineHair := preload("res://2/Player/madeline_hair.gd")
const DashTrail := preload("res://2/Effects/dash_trail.gd")

const DURATION := 0.55
const START_ALPHA := 0.75
const SHADER := preload("res://2/Effects/dash_trail.gdshader")

var _texture: Texture2D
var _sprite_position := Vector2.ZERO
var _sprite_scale := Vector2.ONE
var _pieces: Array[Dictionary] = []
var _facing := 1
var _color := Color.WHITE
var _time := 0.0
var _shape: Node2D


static func spawn(player: Node2D, sprite: AnimatedSprite2D, hair: MadelineHair, color: Color) -> void:
	var trail := DashTrail.new()
	trail._texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	trail._sprite_position = sprite.global_position
	trail._sprite_scale = sprite.global_scale
	trail._facing = -1 if sprite.flip_h else 1
	trail._pieces = hair.get_pieces()
	trail._color = color
	var parent := player.get_parent()
	parent.add_child(trail)
	parent.move_child(trail, player.get_index())


func _ready() -> void:
	material = ShaderMaterial.new()
	material.shader = SHADER
	_update_alpha()
	_shape = Node2D.new()
	_shape.draw.connect(_draw_shape)
	add_child(_shape)


func _physics_process(delta: float) -> void:
	_time += delta
	_update_alpha()
	if _time >= DURATION:
		queue_free()


func _update_alpha() -> void:
	var t := clampf(_time / DURATION, 0.0, 1.0)
	var tint := _color
	tint.a = START_ALPHA * (1.0 - t)
	(material as ShaderMaterial).set_shader_parameter(&"tint", tint)


func _draw_shape() -> void:
	MadelineHair.draw_pieces(_shape, _pieces, Vector2.ZERO, _facing, Color.WHITE, Color.WHITE)
	if _texture:
		_shape.draw_set_transform(_sprite_position, 0.0, _sprite_scale * Vector2(_facing, 1))
		_shape.draw_texture(_texture, -_texture.get_size() / 2.0)
		_shape.draw_set_transform(Vector2.ZERO)
