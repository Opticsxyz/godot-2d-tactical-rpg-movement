## Represents a unit on the game board.
## The board manages its position inside the game grid.
## The unit itself holds stats and a visual representation that moves smoothly in the game world.
@tool
class_name Unit
extends Path2D

## Emitted when the unit reached the end of a path along which it was walking.
signal walk_finished


@export var left_animation: Animation
@export var right_animation: Animation
@export var up_animation: Animation
@export var down_animation: Animation

## Shared resource of type Grid, used to calculate map coordinates.
@export var grid: Resource
## Distance to which the unit can walk in cells.
@export var move_range := 6
## The unit's move speed when it's moving along a path.
@export var move_speed := 600.0
## Texture representing the unit.


## Coordinates of the current cell the cursor moved to.
var cell := Vector2.ZERO:
	set(value):
		# When changing the cell's value, we don't want to allow coordinates outside
		#	the grid, so we clamp them
		cell = grid.grid_clamp(value)
## Toggles the "selected" animation on the unit.
var is_selected := false:
	set(value):
		is_selected = value
		if is_selected:
			_anim_player.play("selected")
		else:
			_anim_player.play("idle")

var _is_walking := false:
	set(value):
		_is_walking = value
		set_process(_is_walking)

@onready var _sprite: AnimatedSprite2D = $PathFollow2D/AnimatedSprite2D
@onready var _anim_player: AnimationPlayer = $AnimationPlayer
@onready var _path_follow: PathFollow2D = $PathFollow2D


func _ready() -> void:
	set_process(false)
	_path_follow.rotates = false

	cell = grid.calculate_grid_coordinates(position)
	position = grid.calculate_map_position(cell)

	# We create the curve resource here because creating it in the editor prevents us from
	# moving the unit.
	if not Engine.is_editor_hint():
		curve = Curve2D.new()


func _process(delta: float) -> void:
	var old_pos = _path_follow.position
	_path_follow.progress += move_speed * delta
	var new_pos = _path_follow.position
	print(get_animation_for(new_pos-old_pos))
	_sprite.play(get_animation_for(new_pos-old_pos))

	if _path_follow.progress_ratio >= 1.0:
		_is_walking = false
		_sprite.stop()
		# Setting this value to 0.0 causes a Zero Length Interval error
		_path_follow.progress = 0.00001
		position = grid.calculate_map_position(cell)
		curve.clear_points()
		emit_signal("walk_finished")


## Starts walking along the `path`.
## `path` is an array of grid coordinates that the function converts to map coordinates.
func walk_along(path: PackedVector2Array) -> void:
	if path.is_empty():
		return

	curve.add_point(Vector2.ZERO)
	for point in path:
		curve.add_point(grid.calculate_map_position(point) - position)
	cell = path[-1]
	_is_walking = true
	
func get_animation_for(direction: Vector2):
	# moving left
	if direction.x < 0 and abs(direction.x) > abs(direction.y):
		return "left_animation"

	# moving right
	if direction.x > 0 and abs(direction.x) > abs(direction.y):
		return "right_animation"

	# moving up
	if direction.y < 0 and abs(direction.y) > abs(direction.x):
		return "up_animation"
		
	# moving down
	if direction.y > 0 and abs(direction.y) > abs(direction.x):
		return "down_animation"
