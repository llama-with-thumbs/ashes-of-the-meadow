@tool
extends Node

## Generates detailed painterly sprites at runtime.
## Higher resolution, soft edges, layered shading — still zero imports.

# ─── Helpers ───

static func _soft_circle(img: Image, cx: float, cy: float, r: float, col: Color, falloff: float = 0.3) -> void:
	var ri := int(ceil(r + falloff * r))
	var x0 := int(max(cx - ri, 0))
	var y0 := int(max(cy - ri, 0))
	var x1 := int(min(cx + ri, img.get_width() - 1))
	var y1 := int(min(cy + ri, img.get_height() - 1))
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			var d := Vector2(x, y).distance_to(Vector2(cx, cy))
			if d <= r:
				var a := col.a
				if d > r * (1.0 - falloff):
					a *= 1.0 - (d - r * (1.0 - falloff)) / (r * falloff)
				var existing := img.get_pixel(x, y)
				var blended := existing.blend(Color(col.r, col.g, col.b, a))
				img.set_pixel(x, y, blended)

static func _soft_ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, col: Color, falloff: float = 0.3) -> void:
	var rxi := int(ceil(rx * (1.0 + falloff)))
	var ryi := int(ceil(ry * (1.0 + falloff)))
	for x in range(int(max(cx - rxi, 0)), int(min(cx + rxi, img.get_width() - 1)) + 1):
		for y in range(int(max(cy - ryi, 0)), int(min(cy + ryi, img.get_height() - 1)) + 1):
			var dx := (x - cx) / rx
			var dy := (y - cy) / ry
			var d := sqrt(dx * dx + dy * dy)
			if d <= 1.0 + falloff:
				var a := col.a
				if d > 1.0 - falloff:
					a *= clampf(1.0 - (d - (1.0 - falloff)) / (falloff * 2.0), 0.0, 1.0)
				var existing := img.get_pixel(x, y)
				img.set_pixel(x, y, existing.blend(Color(col.r, col.g, col.b, a)))

static func _noise_at(x: float, y: float, seed_val: float = 0.0) -> float:
	var v := sin((x + seed_val) * 127.1 + y * 311.7) * 43758.5453
	return v - floor(v)

static func _soft_line_v(img: Image, x: int, y0: int, y1: int, col: Color, width: float = 1.0) -> void:
	var hw := width / 2.0
	for y in range(y0, y1 + 1):
		for dx in range(int(-ceil(hw)), int(ceil(hw)) + 1):
			var px := x + dx
			if px < 0 or px >= img.get_width():
				continue
			var dist := absf(dx)
			var a := col.a * clampf(1.0 - dist / hw, 0.0, 1.0)
			var existing := img.get_pixel(px, y)
			img.set_pixel(px, y, existing.blend(Color(col.r, col.g, col.b, a)))

static func _soft_line_h(img: Image, y: int, x0: int, x1: int, col: Color, width: float = 1.0) -> void:
	var hw := width / 2.0
	for x in range(x0, x1 + 1):
		for dy in range(int(-ceil(hw)), int(ceil(hw)) + 1):
			var py := y + dy
			if py < 0 or py >= img.get_height():
				continue
			var dist := absf(dy)
			var a := col.a * clampf(1.0 - dist / hw, 0.0, 1.0)
			var existing := img.get_pixel(x, py)
			img.set_pixel(x, py, existing.blend(Color(col.r, col.g, col.b, a)))

static func _rect_rounded(img: Image, x0: int, y0: int, x1: int, y1: int, col: Color, corner_r: float = 3.0) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			var inside := true
			# Check corners
			if x < x0 + corner_r and y < y0 + corner_r:
				inside = Vector2(x, y).distance_to(Vector2(x0 + corner_r, y0 + corner_r)) <= corner_r
			elif x > x1 - corner_r and y < y0 + corner_r:
				inside = Vector2(x, y).distance_to(Vector2(x1 - corner_r, y0 + corner_r)) <= corner_r
			elif x < x0 + corner_r and y > y1 - corner_r:
				inside = Vector2(x, y).distance_to(Vector2(x0 + corner_r, y1 - corner_r)) <= corner_r
			elif x > x1 - corner_r and y > y1 - corner_r:
				inside = Vector2(x, y).distance_to(Vector2(x1 - corner_r, y1 - corner_r)) <= corner_r
			if inside:
				var existing := img.get_pixel(x, y)
				img.set_pixel(x, y, existing.blend(col))

# ─── Fluffy Sheep (96x96) ───

static func generate_sheep() -> ImageTexture:
	var s := 96
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2.0
	var cy := s / 2.0 + 6.0

	# Shadow underneath
	_soft_ellipse(img, cx, cy + 20, 22.0, 5.0, Color(0.0, 0.0, 0.05, 0.12))

	# Legs (behind body) — dangling in zero-g
	var leg_color := Color(0.18, 0.15, 0.2, 1.0)
	# Back legs — slightly splayed out
	_soft_ellipse(img, cx - 13, cy + 17, 3.5, 11.0, leg_color)
	_soft_ellipse(img, cx + 13, cy + 17, 3.5, 11.0, leg_color)
	# Front legs
	_soft_ellipse(img, cx - 8, cy + 15, 3.2, 12.0, leg_color)
	_soft_ellipse(img, cx + 8, cy + 15, 3.2, 12.0, leg_color)
	# Hooves — little dark tips
	_soft_ellipse(img, cx - 13, cy + 27, 4.0, 2.5, Color(0.1, 0.08, 0.12))
	_soft_ellipse(img, cx + 13, cy + 27, 4.0, 2.5, Color(0.1, 0.08, 0.12))
	_soft_ellipse(img, cx - 8, cy + 26, 3.5, 2.5, Color(0.1, 0.08, 0.12))
	_soft_ellipse(img, cx + 8, cy + 26, 3.5, 2.5, Color(0.1, 0.08, 0.12))

	# Body — large fluffy wool
	var wool_base := Color(0.92, 0.89, 0.82)
	_soft_ellipse(img, cx, cy, 24.0, 17.0, wool_base, 0.2)

	# Wool puffs for fluffiness
	var puff_positions := [
		Vector2(-14, -8), Vector2(-6, -13), Vector2(6, -13), Vector2(14, -8),
		Vector2(-18, 0), Vector2(-10, -4), Vector2(0, -9), Vector2(10, -4), Vector2(18, 0),
		Vector2(-16, 7), Vector2(-6, 9), Vector2(6, 9), Vector2(16, 7),
		Vector2(-8, 3), Vector2(8, 3), Vector2(0, 1),
		Vector2(-12, -11), Vector2(12, -11), Vector2(0, -15),
	]
	for p in puff_positions:
		var puff_r := randf_range(5.0, 8.5)
		var brightness := randf_range(0.86, 0.96)
		var puff_col := Color(brightness, brightness * 0.97, brightness * 0.91, 0.65)
		_soft_circle(img, cx + p.x, cy + p.y, puff_r, puff_col, 0.4)

	# Wool shading
	for x in s:
		for y in s:
			var px := img.get_pixel(x, y)
			if px.a > 0.1:
				var vert := (y - (cy - 17)) / 34.0
				var shade := 1.0 - vert * 0.12
				var noise := _noise_at(x * 0.5, y * 0.5) * 0.04 - 0.02
				img.set_pixel(x, y, Color(
					clampf(px.r * shade + noise, 0, 1),
					clampf(px.g * shade + noise * 0.8, 0, 1),
					clampf(px.b * shade - noise * 0.5, 0, 1),
					px.a
				))

	# Head — dark face
	var head_base := Color(0.16, 0.13, 0.18)
	_soft_ellipse(img, cx, cy - 18, 11.0, 10.0, head_base, 0.15)
	# Head highlight
	_soft_ellipse(img, cx, cy - 22, 7.0, 4.0, Color(0.22, 0.19, 0.24, 0.35), 0.5)

	# Ears — floppy, slightly drooping
	_soft_ellipse(img, cx - 14, cy - 20, 6.5, 3.5, Color(0.2, 0.16, 0.22))
	_soft_ellipse(img, cx + 14, cy - 20, 6.5, 3.5, Color(0.2, 0.16, 0.22))
	# Inner ear
	_soft_ellipse(img, cx - 14, cy - 20, 3.5, 2.0, Color(0.45, 0.3, 0.35, 0.45))
	_soft_ellipse(img, cx + 14, cy - 20, 3.5, 2.0, Color(0.45, 0.3, 0.35, 0.45))

	# Eyes — warm, gentle, slightly sad
	_soft_circle(img, cx - 5, cy - 18, 3.2, Color(1.0, 0.92, 0.75), 0.2)
	_soft_circle(img, cx + 5, cy - 18, 3.2, Color(1.0, 0.92, 0.75), 0.2)
	# Pupils
	_soft_circle(img, cx - 5, cy - 17.5, 1.6, Color(0.08, 0.06, 0.1), 0.1)
	_soft_circle(img, cx + 5, cy - 17.5, 1.6, Color(0.08, 0.06, 0.1), 0.1)
	# Eye highlights
	_soft_circle(img, cx - 4, cy - 19, 1.0, Color(1.0, 1.0, 1.0, 0.85), 0.3)
	_soft_circle(img, cx + 6, cy - 19, 1.0, Color(1.0, 1.0, 1.0, 0.85), 0.3)

	# Nose
	_soft_ellipse(img, cx, cy - 13, 2.0, 1.5, Color(0.38, 0.26, 0.28))

	# Wool tuft on top of head
	_soft_circle(img, cx - 2, cy - 26, 4.0, Color(0.94, 0.91, 0.84, 0.7), 0.4)
	_soft_circle(img, cx + 3, cy - 27, 3.5, Color(0.96, 0.93, 0.86, 0.6), 0.4)

	# Tail puff
	_soft_circle(img, cx + 22, cy + 3, 4.5, Color(0.94, 0.91, 0.85, 0.75), 0.4)
	_soft_circle(img, cx + 24, cy + 2, 3.0, Color(0.97, 0.94, 0.88, 0.5), 0.5)

	return ImageTexture.create_from_image(img)

# ─── Walkman-style Cassette Player with Orange Headphones (96x80) ───

static func generate_cassette() -> ImageTexture:
	var w := 96
	var h := 80
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := w / 2.0
	var cy := (24 + 68) / 2.0  # vertical center of body
	var body_top := 24
	var body_bot := 68
	var body_left := 20
	var body_right := 76

	# ── HEADPHONE BAND — thin silver arc over the top ──
	# Arc from left pad to right pad
	for i in 60:
		var t := float(i) / 59.0
		var bx := 10.0 + t * 76.0
		var by := 22.0 - sin(t * PI) * 20.0
		_soft_circle(img, bx, by, 1.2, Color(0.7, 0.7, 0.72, 0.7), 0.3)
	# Band highlight
	for i in 40:
		var t := float(i) / 39.0
		var bx := 20.0 + t * 56.0
		var by := 20.0 - sin(t * PI) * 18.0
		_soft_circle(img, bx, by, 0.6, Color(0.85, 0.85, 0.87, 0.3), 0.5)

	# ── HEADPHONE YOKES — black arms connecting band to pads ──
	# Left yoke
	_soft_ellipse(img, 14, 18, 2.5, 8.0, Color(0.1, 0.1, 0.12))
	_soft_ellipse(img, 12, 28, 2.0, 6.0, Color(0.1, 0.1, 0.12))
	# Right yoke
	_soft_ellipse(img, 82, 18, 2.5, 8.0, Color(0.1, 0.1, 0.12))
	_soft_ellipse(img, 84, 28, 2.0, 6.0, Color(0.1, 0.1, 0.12))

	# ── ORANGE HEADPHONE PADS — large, fuzzy, warm ──
	# Left pad — outer
	_soft_circle(img, 10, 38, 10.0, Color(0.92, 0.6, 0.12), 0.2)
	# Left pad — foam texture (lighter center)
	_soft_circle(img, 10, 38, 7.0, Color(0.95, 0.65, 0.15, 0.6), 0.3)
	_soft_circle(img, 9, 36, 4.0, Color(0.98, 0.72, 0.2, 0.4), 0.4)
	# Left pad — speaker center dark
	_soft_circle(img, 10, 38, 3.0, Color(0.3, 0.2, 0.08, 0.3), 0.3)

	# Right pad — outer
	_soft_circle(img, 86, 38, 10.0, Color(0.92, 0.6, 0.12), 0.2)
	# Right pad — foam texture
	_soft_circle(img, 86, 38, 7.0, Color(0.95, 0.65, 0.15, 0.6), 0.3)
	_soft_circle(img, 87, 36, 4.0, Color(0.98, 0.72, 0.2, 0.4), 0.4)
	# Right pad — speaker center
	_soft_circle(img, 86, 38, 3.0, Color(0.3, 0.2, 0.08, 0.3), 0.3)

	# ── WALKMAN BODY — steel blue ──
	var blue := Color(0.42, 0.55, 0.72)
	var blue_dark := Color(0.35, 0.48, 0.65)
	var blue_light := Color(0.5, 0.62, 0.78)
	_rect_rounded(img, body_left, body_top, body_right, body_bot, blue, 4.0)

	# ── SILVER TOP SECTION ──
	var silver := Color(0.72, 0.72, 0.74)
	var silver_light := Color(0.82, 0.82, 0.84)
	_rect_rounded(img, body_left, body_top, body_right, body_top + 12, silver, 4.0)
	# Silver highlight
	_soft_ellipse(img, cx, body_top + 4, 22.0, 3.0, Color(silver_light.r, silver_light.g, silver_light.b, 0.4), 0.4)
	# Dividing line between silver and blue
	_soft_line_h(img, body_top + 12, body_left + 1, body_right - 1, Color(0.3, 0.4, 0.55, 0.5), 1.0)

	# ── VOLUME SLIDER on silver top — vertical toggle (like TPS-L2) ──
	var slider_x := body_left + 6
	var slider_top := body_top + 2
	var slider_bot := body_top + 10
	# Slider track/groove — dark recessed slot
	_rect_rounded(img, slider_x - 2, slider_top, slider_x + 2, slider_bot, Color(0.15, 0.15, 0.17), 1.0)
	# Track inner shadow
	_soft_ellipse(img, slider_x, (slider_top + slider_bot) / 2.0, 1.5, 4.0, Color(0.1, 0.1, 0.12, 0.5), 0.2)
	# Slider knob — silver/white rectangle, positioned at middle
	var knob_y := slider_top + 3
	_rect_rounded(img, slider_x - 2, knob_y, slider_x + 2, knob_y + 3, Color(0.85, 0.85, 0.87), 1.0)
	# Knob highlight
	_soft_ellipse(img, slider_x, knob_y + 1, 1.5, 1.0, Color(0.95, 0.95, 0.97, 0.5), 0.3)
	# Tick marks beside slider — NORM MID MAX (tiny dots)
	_soft_circle(img, slider_x + 4, slider_top + 1, 0.5, Color(0.55, 0.5, 0.4, 0.5))
	_soft_circle(img, slider_x + 4, slider_top + 4, 0.5, Color(0.55, 0.5, 0.4, 0.5))
	_soft_circle(img, slider_x + 4, slider_top + 7, 0.5, Color(0.55, 0.5, 0.4, 0.5))

	# ── PLAY ARROW on blue body ──
	# Triangle arrow pointing right
	for y_off in range(-5, 6):
		var arrow_w := int(5 - absi(y_off) * 0.8)
		if arrow_w > 0:
			var ay := int(cy - 6 + y_off)
			_soft_line_h(img, ay, int(cx - 6), int(cx - 6 + arrow_w), Color(0.8, 0.82, 0.85, 0.6), 1.0)

	# ── TAPE WINDOW — dark rectangle with visible reels ──
	var win_left := 38
	var win_right := 72
	var win_top := 44
	var win_bot := 60
	_rect_rounded(img, win_left, win_top, win_right, win_bot, Color(0.08, 0.08, 0.1), 2.0)
	# Window frame
	_soft_line_h(img, win_top, win_left, win_right, Color(0.3, 0.35, 0.4, 0.3), 1.0)
	_soft_line_h(img, win_bot, win_left, win_right, Color(0.3, 0.35, 0.4, 0.3), 1.0)

	# Tape reels inside window
	var reel_y := (win_top + win_bot) / 2.0
	_soft_circle(img, 47, reel_y, 5.0, Color(0.2, 0.18, 0.16))
	_soft_circle(img, 63, reel_y, 5.0, Color(0.2, 0.18, 0.16))
	# Reel hubs
	_soft_circle(img, 47, reel_y, 2.5, Color(0.35, 0.3, 0.25))
	_soft_circle(img, 63, reel_y, 2.5, Color(0.35, 0.3, 0.25))
	_soft_circle(img, 47, reel_y, 1.0, Color(0.15, 0.12, 0.1))
	_soft_circle(img, 63, reel_y, 1.0, Color(0.15, 0.12, 0.1))
	# Tape strip between reels
	_soft_line_h(img, int(reel_y - 3), 50, 60, Color(0.3, 0.22, 0.15, 0.5), 1.0)
	# Light patch in tape window
	_soft_ellipse(img, 55, reel_y - 2, 5.0, 2.0, Color(0.25, 0.22, 0.2, 0.3), 0.4)

	# ── JACK PORTS on left side ──
	_soft_circle(img, body_left + 3, 42, 1.8, Color(0.2, 0.45, 0.2))  # green
	_soft_circle(img, body_left + 3, 47, 1.8, Color(0.55, 0.2, 0.2))  # red
	# Volume wheel at bottom-left
	_soft_ellipse(img, body_left + 2, 56, 3.0, 5.0, Color(0.12, 0.12, 0.14))
	_soft_ellipse(img, body_left + 2, 56, 2.0, 4.0, Color(0.18, 0.18, 0.2))
	# Wheel grip lines
	for i in 4:
		var wy := 53 + i * 2
		_soft_line_h(img, wy, body_left, body_left + 3, Color(0.25, 0.25, 0.28, 0.4), 0.5)

	# ── LABEL TEXT — "WALKMAN" style on blue body ──
	# Vertical text hint on right side of blue area (just decorative lines)
	for i in 7:
		var ly := 38 + i * 3
		var lw := 2 + (i % 3)
		_soft_line_h(img, ly, body_right - 10, body_right - 10 + lw, Color(0.7, 0.72, 0.75, 0.25), 0.8)

	# ── BODY SHADING ──
	# Slight gradient — lighter at top, darker at bottom
	for x in range(body_left + 1, body_right):
		for y in range(body_top + 13, body_bot):
			var px := img.get_pixel(x, y)
			if px.a > 0.3:
				var grad := (float(y - body_top) / float(body_bot - body_top)) * 0.08
				img.set_pixel(x, y, Color(
					clampf(px.r - grad, 0, 1),
					clampf(px.g - grad, 0, 1),
					clampf(px.b - grad, 0, 1),
					px.a
				))

	# ── BUTTON on top-right of silver section ──
	_soft_circle(img, 65, body_top + 6, 2.0, Color(0.6, 0.6, 0.62))
	_soft_circle(img, 65, body_top + 6, 1.0, Color(0.55, 0.55, 0.57))

	# ── MAGICAL GLOW — subtle warmth from the headphone pads ──
	_soft_circle(img, 10, 38, 14.0, Color(1.0, 0.75, 0.2, 0.06), 0.6)
	_soft_circle(img, 86, 38, 14.0, Color(1.0, 0.75, 0.2, 0.06), 0.6)

	return ImageTexture.create_from_image(img)

# ─── Cartoonishly Large Headphones (64x48) — sits on sheep's ears ───

static func generate_headphones() -> ImageTexture:
	var w := 64
	var h := 48
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := w / 2.0

	# ── THICK HEADPHONE BAND — neon hot pink arc ──
	for i in 64:
		var t := float(i) / 63.0
		var bx := 2.0 + t * 60.0
		var by := 40.0 - sin(t * PI) * 36.0
		_soft_circle(img, bx, by, 3.0, Color(1.0, 0.1, 0.45), 0.2)
	# Band highlight — electric gleam
	for i in 40:
		var t := float(i) / 39.0
		var bx := 12.0 + t * 40.0
		var by := 37.0 - sin(t * PI) * 33.0
		_soft_circle(img, bx, by, 1.5, Color(1.0, 0.6, 0.75, 0.6), 0.4)

	# ── YOKES — vivid magenta arms ──
	_soft_ellipse(img, 8, 28, 3.5, 10.0, Color(0.95, 0.05, 0.4))
	_soft_ellipse(img, 56, 28, 3.5, 10.0, Color(0.95, 0.05, 0.4))
	# Yoke highlight
	_soft_ellipse(img, 7, 26, 1.5, 7.0, Color(1.0, 0.5, 0.65, 0.4), 0.4)
	_soft_ellipse(img, 55, 26, 1.5, 7.0, Color(1.0, 0.5, 0.65, 0.4), 0.4)

	# ── GIANT ORANGE PADS — neon orange, super bright ──
	# Left pad — outer glow
	_soft_circle(img, 6, 38, 10.0, Color(1.0, 0.5, 0.0), 0.15)
	# Left pad — main body
	_soft_circle(img, 6, 38, 8.0, Color(1.0, 0.6, 0.05), 0.2)
	# Left pad — hot center
	_soft_circle(img, 5, 36, 5.0, Color(1.0, 0.85, 0.25, 0.8), 0.3)
	# Left pad — speaker dot
	_soft_circle(img, 6, 38, 3.0, Color(0.6, 0.25, 0.0, 0.5), 0.3)
	# Left pad — white cartoon shine
	_soft_circle(img, 3, 34, 2.5, Color(1.0, 1.0, 1.0, 0.7), 0.5)

	# Right pad — outer glow
	_soft_circle(img, 58, 38, 10.0, Color(1.0, 0.5, 0.0), 0.15)
	# Right pad — main body
	_soft_circle(img, 58, 38, 8.0, Color(1.0, 0.6, 0.05), 0.2)
	# Right pad — hot center
	_soft_circle(img, 59, 36, 5.0, Color(1.0, 0.85, 0.25, 0.8), 0.3)
	# Right pad — speaker dot
	_soft_circle(img, 58, 38, 3.0, Color(0.6, 0.25, 0.0, 0.5), 0.3)
	# Right pad — white cartoon shine
	_soft_circle(img, 61, 34, 2.5, Color(1.0, 1.0, 1.0, 0.7), 0.5)

	# Big neon glow around pads
	_soft_circle(img, 6, 38, 14.0, Color(1.0, 0.6, 0.0, 0.1), 0.6)
	_soft_circle(img, 58, 38, 14.0, Color(1.0, 0.6, 0.0, 0.1), 0.6)

	return ImageTexture.create_from_image(img)

# ─── Cartoonishly Large Walkman (72x64) — clipped to sheep's belt ───

static func generate_walkman_body() -> ImageTexture:
	var w := 72
	var h := 64
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := w / 2.0

	var body_top := 3
	var body_bot := 61
	var body_left := 4
	var body_right := 68

	# ── BELT CLIP — little tab sticking up from top ──
	_rect_rounded(img, 28, 0, 44, 6, Color(0.55, 0.55, 0.58), 1.5)
	_soft_ellipse(img, 36, 2, 6.0, 1.5, Color(0.7, 0.7, 0.73, 0.4), 0.4)

	# ── WALKMAN BODY — bright candy blue ──
	var blue := Color(0.35, 0.6, 0.9)
	_rect_rounded(img, body_left, body_top, body_right, body_bot, blue, 5.0)

	# ── Cartoon outline — dark border ──
	for x in range(body_left - 1, body_right + 2):
		for y in range(body_top - 1, body_bot + 2):
			if x < 0 or y < 0 or x >= w or y >= h:
				continue
			var px := img.get_pixel(x, y)
			if px.a < 0.1:
				# Check if adjacent to body
				var near_body := false
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						var nx := x + dx
						var ny := y + dy
						if nx >= 0 and ny >= 0 and nx < w and ny < h:
							if img.get_pixel(nx, ny).a > 0.5:
								near_body = true
				if near_body:
					img.set_pixel(x, y, Color(0.15, 0.25, 0.45, 0.6))

	# ── SILVER TOP — shiny metallic section ──
	_rect_rounded(img, body_left + 1, body_top + 1, body_right - 1, body_top + 14, Color(0.78, 0.78, 0.82), 4.0)
	_soft_ellipse(img, cx, body_top + 5, 26.0, 4.0, Color(0.92, 0.92, 0.95, 0.5), 0.4)
	_soft_line_h(img, body_top + 14, body_left + 2, body_right - 2, Color(0.2, 0.35, 0.55, 0.6), 1.5)

	# ── BIG VOLUME SLIDER — chunky and fun ──
	var slider_x := body_left + 8
	_rect_rounded(img, slider_x - 3, body_top + 2, slider_x + 3, body_top + 12, Color(0.12, 0.12, 0.15), 1.5)
	# Slider knob — bright yellow
	_rect_rounded(img, slider_x - 3, body_top + 5, slider_x + 3, body_top + 9, Color(1.0, 0.85, 0.2), 1.5)
	_soft_ellipse(img, slider_x, body_top + 7, 2.0, 1.5, Color(1.0, 1.0, 0.6, 0.5), 0.3)

	# ── BIG PLAY BUTTON — bright green triangle ──
	var mid_y := (body_top + 15 + body_bot) / 2.0 - 6
	for y_off in range(-7, 8):
		var arrow_w := int(7 - absi(y_off) * 0.8)
		if arrow_w > 0:
			_soft_line_h(img, int(mid_y + y_off), int(cx - 8), int(cx - 8 + arrow_w * 2), Color(0.2, 0.85, 0.3, 0.8), 1.5)
	# Play button highlight
	_soft_circle(img, cx - 3, mid_y - 2, 3.0, Color(0.5, 1.0, 0.6, 0.3), 0.4)

	# ── TAPE WINDOW — big dark rectangle with chunky reels ──
	var win_left := 18
	var win_right := 60
	var win_top := 32
	var win_bot := 50
	_rect_rounded(img, win_left, win_top, win_right, win_bot, Color(0.06, 0.06, 0.1), 3.0)
	# Window border — bright
	_soft_line_h(img, win_top, win_left, win_right, Color(0.4, 0.5, 0.7, 0.4), 1.5)
	_soft_line_h(img, win_bot, win_left, win_right, Color(0.4, 0.5, 0.7, 0.4), 1.5)

	# Big chunky reels
	var reel_y := (win_top + win_bot) / 2.0
	_soft_circle(img, 30, reel_y, 6.5, Color(0.25, 0.2, 0.18))
	_soft_circle(img, 48, reel_y, 6.5, Color(0.25, 0.2, 0.18))
	# Reel hubs — bright copper
	_soft_circle(img, 30, reel_y, 3.5, Color(0.7, 0.5, 0.25))
	_soft_circle(img, 48, reel_y, 3.5, Color(0.7, 0.5, 0.25))
	# Hub centers
	_soft_circle(img, 30, reel_y, 1.5, Color(0.15, 0.12, 0.1))
	_soft_circle(img, 48, reel_y, 1.5, Color(0.15, 0.12, 0.1))
	# Tape strip
	_soft_line_h(img, int(reel_y - 4), 34, 44, Color(0.4, 0.28, 0.18, 0.6), 1.5)
	# Reel shine
	_soft_circle(img, 28, reel_y - 2, 2.0, Color(0.5, 0.4, 0.3, 0.3), 0.4)
	_soft_circle(img, 46, reel_y - 2, 2.0, Color(0.5, 0.4, 0.3, 0.3), 0.4)

	# ── JACK PORTS — bright colored dots ──
	_soft_circle(img, body_left + 4, 30, 2.5, Color(0.2, 0.8, 0.3))  # green
	_soft_circle(img, body_left + 4, 36, 2.5, Color(0.9, 0.2, 0.25))  # red

	# ── BODY SHADING — cartoon gradient ──
	for x in range(body_left + 1, body_right):
		for y in range(body_top + 15, body_bot):
			var px := img.get_pixel(x, y)
			if px.a > 0.3:
				var grad := (float(y - body_top) / float(body_bot - body_top)) * 0.1
				img.set_pixel(x, y, Color(
					clampf(px.r - grad, 0, 1),
					clampf(px.g - grad, 0, 1),
					clampf(px.b - grad, 0, 1),
					px.a
				))

	# ── BUTTON — bright red circle ──
	_soft_circle(img, 56, body_top + 7, 3.0, Color(0.9, 0.2, 0.2))
	_soft_circle(img, 55, body_top + 6, 1.5, Color(1.0, 0.5, 0.5, 0.4), 0.4)

	# ── Cartoon shine on body — big white gleam ──
	_soft_ellipse(img, cx + 8, body_top + 20, 4.0, 8.0, Color(1.0, 1.0, 1.0, 0.12), 0.5)

	return ImageTexture.create_from_image(img)

# ─── Collectibles (32x32) ───

static func generate_collectible(type: String) -> ImageTexture:
	var s := 32
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2.0
	var cy := s / 2.0

	match type:
		"salvage":
			_generate_salvage(img, cx, cy)
		"tape_fragment":
			_generate_tape_fragment(img, cx, cy)
		"wool_fiber":
			_generate_wool_fiber(img, cx, cy)
		"stardust":
			_generate_stardust(img, cx, cy)
		_:
			_soft_circle(img, cx, cy, 10.0, Color(0.8, 0.8, 0.8), 0.3)

	return ImageTexture.create_from_image(img)

static func _generate_salvage(img: Image, cx: float, cy: float) -> void:
	# Metallic shard — angular, reflective
	# Outer glow
	_soft_circle(img, cx, cy, 14.0, Color(0.5, 0.6, 0.8, 0.1), 0.5)
	# Main shape — irregular polygon approximated with overlapping ellipses
	_soft_ellipse(img, cx - 2, cy, 9.0, 7.0, Color(0.5, 0.55, 0.65))
	_soft_ellipse(img, cx + 2, cy - 2, 7.0, 9.0, Color(0.55, 0.6, 0.7))
	# Highlight streak
	_soft_ellipse(img, cx - 1, cy - 3, 4.0, 2.0, Color(0.75, 0.8, 0.9, 0.6), 0.4)
	# Dark edge details
	_soft_ellipse(img, cx + 4, cy + 4, 3.0, 2.0, Color(0.35, 0.38, 0.45, 0.5), 0.3)
	# Rivets
	_soft_circle(img, cx - 4, cy - 2, 1.2, Color(0.4, 0.42, 0.5))
	_soft_circle(img, cx + 3, cy + 2, 1.0, Color(0.4, 0.42, 0.5))

static func _generate_tape_fragment(img: Image, cx: float, cy: float) -> void:
	# Broken cassette tape piece — warm amber
	_soft_circle(img, cx, cy, 14.0, Color(0.8, 0.6, 0.3, 0.08), 0.5)
	# Tape casing fragment
	_rect_rounded(img, 6, 8, 26, 24, Color(0.6, 0.42, 0.25), 3.0)
	# Tape strip dangling
	_soft_line_h(img, 16, 5, 27, Color(0.3, 0.2, 0.12, 0.8), 2.0)
	_soft_line_h(img, 14, 8, 24, Color(0.35, 0.25, 0.15, 0.6), 1.5)
	# Mini reel
	_soft_circle(img, cx, cy, 4.0, Color(0.2, 0.15, 0.1))
	_soft_circle(img, cx, cy, 2.0, Color(0.35, 0.28, 0.2))
	_soft_circle(img, cx, cy, 0.8, Color(0.15, 0.12, 0.1))
	# Label fragment
	_soft_ellipse(img, cx + 2, 11, 5.0, 2.5, Color(0.75, 0.65, 0.45, 0.5))
	# Shine
	_soft_circle(img, cx - 3, 10, 1.5, Color(0.9, 0.8, 0.5, 0.4), 0.5)

static func _generate_wool_fiber(img: Image, cx: float, cy: float) -> void:
	# Soft fluffy wool clump — cloud-like
	_soft_circle(img, cx, cy, 14.0, Color(1.0, 0.98, 0.92, 0.06), 0.5)
	# Multiple fluffy puffs
	_soft_circle(img, cx, cy, 8.0, Color(0.94, 0.91, 0.85), 0.3)
	_soft_circle(img, cx - 5, cy - 3, 6.0, Color(0.96, 0.93, 0.87), 0.4)
	_soft_circle(img, cx + 5, cy - 2, 5.5, Color(0.92, 0.89, 0.83), 0.35)
	_soft_circle(img, cx - 3, cy + 4, 5.0, Color(0.9, 0.87, 0.81), 0.4)
	_soft_circle(img, cx + 4, cy + 3, 5.5, Color(0.93, 0.9, 0.84), 0.35)
	_soft_circle(img, cx, cy - 5, 4.5, Color(0.97, 0.95, 0.9), 0.4)
	# Wispy strands
	_soft_circle(img, cx - 7, cy, 3.0, Color(0.95, 0.92, 0.86, 0.5), 0.5)
	_soft_circle(img, cx + 7, cy + 1, 2.5, Color(0.95, 0.92, 0.86, 0.4), 0.5)
	# Warm highlight
	_soft_circle(img, cx - 1, cy - 3, 3.0, Color(1.0, 0.97, 0.92, 0.3), 0.5)

static func _generate_stardust(img: Image, cx: float, cy: float) -> void:
	# Shimmering crystal/dust — cool blue-white
	# Outer glow
	_soft_circle(img, cx, cy, 14.0, Color(0.6, 0.7, 1.0, 0.12), 0.5)
	# Central crystal shape — diamond with glow
	# Main facets
	_soft_ellipse(img, cx, cy, 5.0, 8.0, Color(0.65, 0.75, 0.95))
	_soft_ellipse(img, cx, cy, 8.0, 5.0, Color(0.6, 0.7, 0.9, 0.7))
	# Bright center
	_soft_circle(img, cx, cy, 4.0, Color(0.85, 0.9, 1.0, 0.8), 0.3)
	_soft_circle(img, cx, cy, 2.0, Color(1.0, 1.0, 1.0, 0.6), 0.4)
	# Sparkle points
	_soft_ellipse(img, cx, cy - 10, 1.5, 3.0, Color(0.8, 0.85, 1.0, 0.5), 0.5)
	_soft_ellipse(img, cx, cy + 10, 1.5, 3.0, Color(0.8, 0.85, 1.0, 0.5), 0.5)
	_soft_ellipse(img, cx - 10, cy, 3.0, 1.5, Color(0.8, 0.85, 1.0, 0.5), 0.5)
	_soft_ellipse(img, cx + 10, cy, 3.0, 1.5, Color(0.8, 0.85, 1.0, 0.5), 0.5)
	# Tiny sparkle dots
	_soft_circle(img, cx - 6, cy - 6, 1.0, Color(1.0, 1.0, 1.0, 0.6), 0.5)
	_soft_circle(img, cx + 7, cy - 5, 0.8, Color(1.0, 1.0, 1.0, 0.5), 0.5)
	_soft_circle(img, cx + 5, cy + 7, 0.9, Color(1.0, 1.0, 1.0, 0.4), 0.5)

# ─── Asteroid / Space Rock (variable size, sharp edges) ───

static func _build_jagged_outline(cx: float, cy: float, base_r: float, num_verts: int, seed_val: float) -> PackedVector2Array:
	## Generate irregular polygon vertices with jagged rocky edges
	var points := PackedVector2Array()
	for i in num_verts:
		var angle := float(i) / float(num_verts) * TAU
		# Vary radius sharply per vertex for jagged look
		var r_noise := _noise_at(seed_val + float(i) * 13.7, float(i) * 7.3)
		var r := base_r * (0.6 + r_noise * 0.55)
		points.append(Vector2(cx + cos(angle) * r, cy + sin(angle) * r))
	return points

static func _point_in_polygon(p: Vector2, poly: PackedVector2Array) -> bool:
	var n := poly.size()
	var inside := false
	var j := n - 1
	for i in n:
		var pi := poly[i]
		var pj := poly[j]
		if ((pi.y > p.y) != (pj.y > p.y)) and (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x):
			inside = not inside
		j = i
	return inside

static func generate_asteroid(size: int = 48, seed_val: float = 0.0) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := size / 2.0
	var cy := size / 2.0
	var base_r := size * 0.38

	# Rock color with slight variation
	var rock_color := Color(
		0.35 + _noise_at(seed_val, 0.0) * 0.15,
		0.32 + _noise_at(seed_val, 1.0) * 0.12,
		0.30 + _noise_at(seed_val, 2.0) * 0.15
	)

	# Build jagged polygon outline (8-12 vertices)
	var num_verts := 8 + int(_noise_at(seed_val, 3.0) * 5.0)
	var outline := _build_jagged_outline(cx, cy, base_r, num_verts, seed_val)

	# Fill polygon with rock color + per-pixel shading
	var light_angle := _noise_at(seed_val, 100.0) * TAU
	var light_dir := Vector2(cos(light_angle), sin(light_angle))

	for x in size:
		for y in size:
			var p := Vector2(x, y)
			if not _point_in_polygon(p, outline):
				continue

			# Base shading — directional light
			var to_center := (p - Vector2(cx, cy)).normalized()
			var light_factor := to_center.dot(light_dir) * 0.15 + 0.85

			# Surface noise for texture
			var n := _noise_at(x * 0.4 + seed_val * 100.0, y * 0.4) * 0.15 - 0.075

			# Edge darkening
			var edge_dist := p.distance_to(Vector2(cx, cy)) / base_r
			var edge_darken := clampf(edge_dist - 0.4, 0.0, 1.0) * 0.25

			var col := Color(
				clampf(rock_color.r * light_factor + n - edge_darken, 0, 1),
				clampf(rock_color.g * light_factor + n * 0.8 - edge_darken, 0, 1),
				clampf(rock_color.b * light_factor + n * 0.6 - edge_darken, 0, 1),
				1.0
			)
			img.set_pixel(x, y, col)

	# Craters — dark circular dents
	var num_craters := 2 + int(_noise_at(seed_val, 60.0) * 3.0)
	for i in num_craters:
		var angle := _noise_at(seed_val + i, 70.0) * TAU
		var dist := base_r * 0.25 * _noise_at(seed_val + i, 80.0)
		var crater_cx := cx + cos(angle) * dist
		var crater_cy := cy + sin(angle) * dist
		var crater_r := base_r * (0.08 + _noise_at(seed_val + i, 90.0) * 0.12)
		for x in range(int(max(crater_cx - crater_r - 1, 0)), int(min(crater_cx + crater_r + 1, size))):
			for y in range(int(max(crater_cy - crater_r - 1, 0)), int(min(crater_cy + crater_r + 1, size))):
				var px := img.get_pixel(x, y)
				if px.a < 0.1:
					continue
				var d := Vector2(x, y).distance_to(Vector2(crater_cx, crater_cy))
				if d < crater_r:
					var t := 1.0 - d / crater_r
					img.set_pixel(x, y, Color(px.r * (1.0 - t * 0.3), px.g * (1.0 - t * 0.3), px.b * (1.0 - t * 0.3), px.a))

	# Sharp highlight edge on lit side
	for i in outline.size():
		var p1 := outline[i]
		var p2 := outline[(i + 1) % outline.size()]
		var edge_mid := (p1 + p2) / 2.0
		var edge_normal := (edge_mid - Vector2(cx, cy)).normalized()
		if edge_normal.dot(light_dir) > 0.3:
			# Bright edge — draw a thin highlight along this segment
			var steps := int(p1.distance_to(p2))
			for s in steps:
				var t := float(s) / float(max(steps, 1))
				var px := p1.lerp(p2, t)
				var ix := int(px.x)
				var iy := int(px.y)
				if ix >= 0 and ix < size and iy >= 0 and iy < size:
					var existing := img.get_pixel(ix, iy)
					if existing.a > 0.1:
						img.set_pixel(ix, iy, Color(
							minf(existing.r + 0.15, 1.0),
							minf(existing.g + 0.12, 1.0),
							minf(existing.b + 0.1, 1.0),
							existing.a
						))

	return ImageTexture.create_from_image(img)

# ─── Debris (80x40) ───

static func generate_debris() -> ImageTexture:
	var w := 80
	var h := 40
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := w / 2.0
	var cy := h / 2.0

	# Main broken structural piece — dark metallic
	var base_col := Color(0.4, 0.38, 0.45)
	_soft_ellipse(img, cx, cy, 32.0, 14.0, base_col, 0.15)
	_soft_ellipse(img, cx - 8, cy - 3, 22.0, 10.0, Color(0.45, 0.43, 0.5), 0.2)
	_soft_ellipse(img, cx + 10, cy + 2, 20.0, 11.0, Color(0.38, 0.36, 0.42), 0.2)

	# Structural details — panel lines
	_soft_line_h(img, int(cy - 4), int(cx - 25), int(cx + 20), Color(0.3, 0.28, 0.35, 0.3), 1.0)
	_soft_line_h(img, int(cy + 4), int(cx - 20), int(cx + 25), Color(0.3, 0.28, 0.35, 0.25), 1.0)

	# Rivets
	for i in 4:
		_soft_circle(img, cx - 20 + i * 14, cy - 4, 1.2, Color(0.5, 0.48, 0.55, 0.6))

	# Torn/jagged edge on one side
	_soft_ellipse(img, cx + 30, cy, 6.0, 8.0, Color(0.35, 0.33, 0.4), 0.3)
	_soft_ellipse(img, cx + 34, cy - 2, 4.0, 5.0, Color(0.32, 0.3, 0.38), 0.4)

	# Scorch mark
	_soft_ellipse(img, cx - 10, cy + 3, 8.0, 4.0, Color(0.2, 0.18, 0.22, 0.3), 0.4)

	# Highlight — light catching the surface
	_soft_ellipse(img, cx - 5, cy - 6, 15.0, 4.0, Color(0.55, 0.53, 0.6, 0.25), 0.5)

	return ImageTexture.create_from_image(img)

# ─── Home Frame (80x60) ───

static func generate_home_frame() -> ImageTexture:
	var w := 80
	var h := 60
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var frame_col := Color(0.42, 0.38, 0.48)
	var strut_col := Color(0.48, 0.44, 0.52)

	# Outer frame — thick structural beams
	# Top beam
	_soft_ellipse(img, 40, 6, 35.0, 4.0, frame_col, 0.2)
	# Bottom beam
	_soft_ellipse(img, 40, 54, 35.0, 4.0, frame_col, 0.2)
	# Left beam
	_soft_ellipse(img, 6, 30, 4.0, 26.0, frame_col, 0.2)
	# Right beam
	_soft_ellipse(img, 74, 30, 4.0, 26.0, frame_col, 0.2)

	# Cross struts
	_soft_ellipse(img, 40, 30, 2.5, 24.0, strut_col, 0.2)
	_soft_ellipse(img, 40, 30, 34.0, 2.5, strut_col, 0.2)

	# Corner joints — bolted look
	_soft_circle(img, 8, 8, 4.0, Color(0.45, 0.42, 0.5))
	_soft_circle(img, 72, 8, 4.0, Color(0.45, 0.42, 0.5))
	_soft_circle(img, 8, 52, 4.0, Color(0.45, 0.42, 0.5))
	_soft_circle(img, 72, 52, 4.0, Color(0.45, 0.42, 0.5))
	# Bolt centers
	_soft_circle(img, 8, 8, 1.5, Color(0.35, 0.32, 0.4))
	_soft_circle(img, 72, 8, 1.5, Color(0.35, 0.32, 0.4))
	_soft_circle(img, 8, 52, 1.5, Color(0.35, 0.32, 0.4))
	_soft_circle(img, 72, 52, 1.5, Color(0.35, 0.32, 0.4))

	# Center joint
	_soft_circle(img, 40, 30, 3.5, Color(0.5, 0.46, 0.55))
	_soft_circle(img, 40, 30, 1.5, Color(0.38, 0.35, 0.42))

	# Diagonal support wires
	_soft_line_h(img, 18, 12, 36, Color(0.4, 0.37, 0.45, 0.3), 0.8)
	_soft_line_h(img, 42, 44, 68, Color(0.4, 0.37, 0.45, 0.3), 0.8)

	return ImageTexture.create_from_image(img)

# ─── Hull (80x60) ───

static func generate_hull() -> ImageTexture:
	var w := 80
	var h := 60
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Warm, cozy hull — like a little wooden boat/pod
	var hull_base := Color(0.6, 0.5, 0.38)

	# Main hull shape
	_soft_ellipse(img, 40, 32, 34.0, 22.0, hull_base, 0.15)

	# Wooden plank lines
	for i in range(5):
		var ly := 16 + i * 8
		_soft_line_h(img, ly, 12, 68, Color(0.5, 0.42, 0.32, 0.25), 1.0)

	# Porthole window
	_soft_circle(img, 28, 28, 6.0, Color(0.15, 0.18, 0.3))
	_soft_circle(img, 28, 28, 4.5, Color(0.25, 0.35, 0.55, 0.8))
	_soft_circle(img, 28, 28, 4.0, Color(0.3, 0.4, 0.6, 0.5))
	# Window highlight
	_soft_circle(img, 27, 26, 1.5, Color(0.6, 0.7, 0.9, 0.4), 0.5)
	# Porthole rim
	_soft_circle(img, 28, 28, 6.5, Color(0.45, 0.4, 0.35, 0.3))

	# Door outline on right side
	_rect_rounded(img, 45, 20, 58, 42, Color(0.5, 0.42, 0.32, 0.5), 2.0)
	# Door handle
	_soft_circle(img, 55, 31, 1.5, Color(0.7, 0.6, 0.4))

	# Hull highlight — warm light from above
	_soft_ellipse(img, 40, 22, 25.0, 8.0, Color(0.7, 0.6, 0.45, 0.25), 0.5)

	# Bottom keel
	_soft_ellipse(img, 40, 50, 28.0, 4.0, Color(0.45, 0.38, 0.3), 0.2)

	return ImageTexture.create_from_image(img)

# ─── Antenna (24x80) ───

static func generate_antenna() -> ImageTexture:
	var w := 24
	var h := 80
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var cx := w / 2.0

	# Antenna glow at top
	_soft_circle(img, cx, 8, 10.0, Color(1.0, 0.85, 0.5, 0.1), 0.5)

	# Main pole
	_soft_ellipse(img, cx, 45, 2.5, 35.0, Color(0.6, 0.55, 0.45))
	# Pole highlight
	_soft_ellipse(img, cx - 1, 45, 1.0, 30.0, Color(0.7, 0.65, 0.55, 0.3), 0.4)

	# Support bracket at base
	_soft_ellipse(img, cx, 75, 6.0, 3.0, Color(0.5, 0.45, 0.4))
	_soft_ellipse(img, cx, 75, 4.0, 2.0, Color(0.55, 0.5, 0.45))

	# Cross bars
	_soft_ellipse(img, cx, 25, 8.0, 1.5, Color(0.55, 0.5, 0.42))
	_soft_ellipse(img, cx, 40, 6.0, 1.5, Color(0.55, 0.5, 0.42))

	# Glowing orb at top
	_soft_circle(img, cx, 8, 6.0, Color(1.0, 0.85, 0.5, 0.7), 0.3)
	_soft_circle(img, cx, 8, 4.0, Color(1.0, 0.9, 0.6, 0.9), 0.3)
	_soft_circle(img, cx, 8, 2.0, Color(1.0, 0.95, 0.8), 0.2)
	# Orb highlight
	_soft_circle(img, cx - 1, 6, 1.2, Color(1.0, 1.0, 0.95, 0.7), 0.4)

	# Signal waves emanating from orb
	for i in 3:
		var r := 10.0 + i * 4.0
		var a := 0.2 - i * 0.05
		_soft_circle(img, cx, 8, r, Color(1.0, 0.9, 0.6, a), 0.8)

	return ImageTexture.create_from_image(img)
