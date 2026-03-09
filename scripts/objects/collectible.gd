extends Area2D

## Floating collectible resource in space

@export_enum("salvage", "tape_fragment", "wool_fiber", "stardust") var item_type: String = "salvage"
@export var bob_speed: float = 1.5
@export var bob_amount: float = 4.0
@export var glow_color: Color = Color(1, 0.85, 0.5, 0.6)

var base_pos: Vector2
var time: float = 0.0
var collected: bool = false

func _ready() -> void:
	base_pos = position
	time = randf() * TAU  # Random phase offset
	# Set color tint based on type
	match item_type:
		"salvage":
			$Sprite2D.modulate = Color(0.7, 0.75, 0.85)
		"tape_fragment":
			$Sprite2D.modulate = Color(0.85, 0.65, 0.45)
		"wool_fiber":
			$Sprite2D.modulate = Color(0.95, 0.92, 0.88)
		"stardust":
			$Sprite2D.modulate = Color(0.7, 0.8, 1.0)

func _process(delta: float) -> void:
	if collected:
		return
	time += delta * bob_speed
	position.y = base_pos.y + sin(time) * bob_amount
	# Subtle rotation
	rotation = sin(time * 0.7) * 0.1
	queue_redraw()

func _draw() -> void:
	if collected:
		return
	# Soft glow behind the sprite
	var col := glow_color
	col.a = 0.25 + sin(time * 2.0) * 0.1
	draw_circle(Vector2.ZERO, 14.0, col)

func interact(player) -> void:
	if collected:
		return
	collected = true
	GameState.add_item(item_type)
	# Collect animation — float toward player then vanish
	var tween := create_tween()
	tween.tween_property(self, "global_position", player.global_position, 0.3)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
