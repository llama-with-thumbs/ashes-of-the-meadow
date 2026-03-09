extends StaticBody2D

## Floating space debris — remnants of the lost home
## Purely visual/physical obstacle with gentle drift

@export var drift_speed: float = 5.0
@export var drift_direction: Vector2 = Vector2(1, 0)
@export var rotate_speed: float = 0.2

var time: float = 0.0

func _ready() -> void:
	time = randf() * TAU
	rotate_speed = randf_range(-0.3, 0.3)
	drift_speed = randf_range(2.0, 8.0)

func _process(delta: float) -> void:
	time += delta
	rotation += rotate_speed * delta
	position += drift_direction * drift_speed * delta * sin(time * 0.3)
