extends Node2D

## Visual sound ring that expands outward when the sheep pulses

var rings: Array[Dictionary] = []

func trigger(strength: float) -> void:
	rings.append({
		"radius": 10.0,
		"max_radius": 60.0 + strength * 40.0,
		"alpha": 0.6 + strength * 0.2,
		"width": 1.5 + strength,
		"color": Color(0.9, 0.75, 0.5, 1.0),
		"speed": 120.0 + strength * 60.0
	})

func _process(delta: float) -> void:
	var to_remove := []
	for i in rings.size():
		rings[i]["radius"] += rings[i]["speed"] * delta
		rings[i]["alpha"] -= delta * 1.2
		if rings[i]["alpha"] <= 0 or rings[i]["radius"] >= rings[i]["max_radius"]:
			to_remove.append(i)

	for i in range(to_remove.size() - 1, -1, -1):
		rings.remove_at(to_remove[i])

	if not rings.is_empty():
		queue_redraw()

func _draw() -> void:
	for ring in rings:
		var col: Color = ring["color"]
		col.a = maxf(ring["alpha"], 0.0)
		draw_arc(Vector2.ZERO, ring["radius"], 0, TAU, 32, col, ring["width"], true)
