extends Node2D

## Rippling sound wave that slowly fades — organic, watery feel

var rings: Array[Dictionary] = []

var wave_color := Color(0.95, 0.65, 0.15, 1.0)

func trigger(strength: float) -> void:
	# Spawn 3 rings with slight delays for a ripple effect
	for i in 3:
		rings.append({
			"radius": 6.0 + i * 4.0,
			"max_radius": 90.0 + strength * 60.0 + i * 15.0,
			"alpha": 0.5 + strength * 0.2 - i * 0.1,
			"width": 2.5 + strength * 1.0 - i * 0.4,
			"speed": 80.0 + strength * 40.0 - i * 10.0,
			"time": 0.0,
			"wobble_freq": 3.0 + i * 1.5,
			"wobble_amp": 1.5 + strength * 0.8,
		})

func _process(delta: float) -> void:
	var to_remove := []
	for i in rings.size():
		rings[i]["radius"] += rings[i]["speed"] * delta
		rings[i]["time"] += delta
		# Slow fade — takes longer to disappear
		rings[i]["alpha"] -= delta * 0.45
		if rings[i]["alpha"] <= 0 or rings[i]["radius"] >= rings[i]["max_radius"]:
			to_remove.append(i)

	for i in range(to_remove.size() - 1, -1, -1):
		rings.remove_at(to_remove[i])

	if not rings.is_empty():
		queue_redraw()

func _draw() -> void:
	for ring in rings:
		var col: Color = wave_color
		col.a = maxf(ring["alpha"], 0.0)
		var r: float = ring["radius"]
		var t: float = ring["time"]
		var wobble_f: float = ring["wobble_freq"]
		var wobble_a: float = ring["wobble_amp"]
		var w: float = ring["width"]

		# Draw rippled circle — vary radius per angle
		var segments := 48
		var points := PackedVector2Array()
		var colors := PackedColorArray()
		for s in segments + 1:
			var angle := float(s) / float(segments) * TAU
			# Ripple: radius wobbles with angle
			var ripple := sin(angle * wobble_f + t * 4.0) * wobble_a
			var ripple2 := sin(angle * (wobble_f + 2.0) - t * 3.0) * wobble_a * 0.5
			var pr := r + ripple + ripple2
			points.append(Vector2(cos(angle) * pr, sin(angle) * pr))
			# Vary alpha slightly along the ring
			var seg_alpha := col.a * (0.85 + sin(angle * 3.0 + t * 2.0) * 0.15)
			colors.append(Color(col.r, col.g, col.b, maxf(seg_alpha, 0.0)))

		# Draw as connected line segments
		for s in segments:
			var mid_col := Color(
				(colors[s].r + colors[s + 1].r) * 0.5,
				(colors[s].g + colors[s + 1].g) * 0.5,
				(colors[s].b + colors[s + 1].b) * 0.5,
				(colors[s].a + colors[s + 1].a) * 0.5,
			)
			draw_line(points[s], points[s + 1], mid_col, w, true)
