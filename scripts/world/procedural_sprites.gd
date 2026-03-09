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

# ─── Cassette-Bass Device (64x64) ───

static func generate_cassette() -> ImageTexture:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2.0
	var cy := s / 2.0

	# Outer glow
	_soft_ellipse(img, cx, cy, 28.0, 22.0, Color(1.0, 0.8, 0.4, 0.08), 0.5)

	# Main cassette body — warm brown/amber
	_rect_rounded(img, 10, 14, 54, 42, Color(0.55, 0.38, 0.22), 4.0)
	# Top label area — lighter
	_rect_rounded(img, 13, 16, 51, 28, Color(0.72, 0.6, 0.42), 2.0)
	# Label text lines (decorative)
	_soft_line_h(img, 19, 16, 48, Color(0.5, 0.4, 0.28, 0.5), 1.0)
	_soft_line_h(img, 22, 16, 42, Color(0.5, 0.4, 0.28, 0.3), 1.0)
	_soft_line_h(img, 25, 16, 45, Color(0.5, 0.4, 0.28, 0.4), 1.0)

	# Tape window
	_rect_rounded(img, 18, 30, 46, 40, Color(0.12, 0.1, 0.08), 2.0)

	# Tape reels
	_soft_circle(img, cx - 8, 35, 4.5, Color(0.25, 0.2, 0.15))
	_soft_circle(img, cx + 8, 35, 4.5, Color(0.25, 0.2, 0.15))
	# Reel centers
	_soft_circle(img, cx - 8, 35, 2.0, Color(0.4, 0.35, 0.25))
	_soft_circle(img, cx + 8, 35, 2.0, Color(0.4, 0.35, 0.25))
	# Reel hubs
	_soft_circle(img, cx - 8, 35, 0.8, Color(0.15, 0.12, 0.1))
	_soft_circle(img, cx + 8, 35, 0.8, Color(0.15, 0.12, 0.1))
	# Tape between reels
	_soft_line_h(img, 32, int(cx - 3), int(cx + 3), Color(0.35, 0.25, 0.15, 0.6), 1.5)

	# Bass strings below — 4 strings with warm golden color
	for i in 4:
		var string_y := 46 + i * 3
		var gold := 0.7 + i * 0.05
		_soft_line_h(img, string_y, 14, 50, Color(gold, gold * 0.85, 0.3, 0.8 - i * 0.1), 1.2 + i * 0.3)

	# Bass bridge
	_rect_rounded(img, 12, 44, 52, 46, Color(0.4, 0.3, 0.2, 0.7), 1.0)

	# Sound hole (between cassette and strings)
	_soft_ellipse(img, cx, 44, 6.0, 2.0, Color(0.08, 0.06, 0.05, 0.6))

	# Tuning pegs at bottom
	_soft_circle(img, 16, 57, 2.0, Color(0.5, 0.4, 0.25))
	_soft_circle(img, 24, 58, 2.0, Color(0.5, 0.4, 0.25))
	_soft_circle(img, 40, 58, 2.0, Color(0.5, 0.4, 0.25))
	_soft_circle(img, 48, 57, 2.0, Color(0.5, 0.4, 0.25))

	# Magical shimmer spots
	_soft_circle(img, 20, 18, 1.5, Color(1.0, 0.95, 0.7, 0.5), 0.5)
	_soft_circle(img, 44, 36, 1.2, Color(1.0, 0.9, 0.6, 0.4), 0.5)
	_soft_circle(img, 30, 48, 1.0, Color(1.0, 0.95, 0.75, 0.3), 0.5)

	# Corner screws
	_soft_circle(img, 13, 17, 1.2, Color(0.4, 0.35, 0.3))
	_soft_circle(img, 51, 17, 1.2, Color(0.4, 0.35, 0.3))
	_soft_circle(img, 13, 40, 1.2, Color(0.4, 0.35, 0.3))
	_soft_circle(img, 51, 40, 1.2, Color(0.4, 0.35, 0.3))

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
