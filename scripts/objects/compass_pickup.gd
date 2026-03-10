extends Area2D

## A compass the sheep can pick up to navigate toward home

var time: float = 0.0
var picked_up: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if picked_up:
		return
	time += delta
	position.y += sin(time * 1.2) * 0.25
	rotation = sin(time * 0.6) * 0.1
	queue_redraw()

func _draw() -> void:
	if picked_up:
		return
	# Cool cyan-green glow
	var alpha := 0.12 + sin(time * 1.8) * 0.06
	draw_circle(Vector2.ZERO, 22.0, Color(0.2, 0.9, 0.4, alpha))
	draw_circle(Vector2.ZERO, 12.0, Color(0.3, 1.0, 0.5, alpha * 1.5))

func _on_body_entered(body: Node2D) -> void:
	if picked_up:
		return
	if body.is_in_group("player") and body.has_method("receive_compass"):
		picked_up = true
		var tween := create_tween()
		tween.tween_property(self, "global_position", body.global_position, 0.5)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.parallel().tween_property(self, "scale", Vector2(0.1, 0.1), 0.5)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func():
			body.receive_compass()
			queue_free()
		)
