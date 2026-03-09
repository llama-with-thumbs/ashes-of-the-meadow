extends Area2D

## The cassette-bass device the sheep finds at the start

var time: float = 0.0
var picked_up: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if picked_up:
		return
	time += delta
	# Magical floating glow
	position.y += sin(time * 1.5) * 0.3
	rotation = sin(time * 0.8) * 0.08
	queue_redraw()

func _draw() -> void:
	if picked_up:
		return
	# Warm magical glow
	var alpha := 0.15 + sin(time * 2.0) * 0.08
	draw_circle(Vector2.ZERO, 25.0, Color(1.0, 0.8, 0.4, alpha))
	draw_circle(Vector2.ZERO, 15.0, Color(1.0, 0.9, 0.6, alpha * 1.5))

func _on_body_entered(body: Node2D) -> void:
	if picked_up:
		return
	if body.is_in_group("player") and body.has_method("receive_cassette"):
		picked_up = true
		# Animate pickup
		var tween := create_tween()
		tween.tween_property(self, "global_position", body.global_position, 0.5)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.parallel().tween_property(self, "scale", Vector2(0.1, 0.1), 0.5)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func():
			body.receive_cassette()
			queue_free()
		)
