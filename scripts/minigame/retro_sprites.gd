@tool
extends Node

## 16-bit Mega Drive style pixel art sprites — hard edges, restricted palette

# Mega Drive palette quantization (9-bit color: 3 bits per channel)
static func _md(r: float, g: float, b: float, a: float = 1.0) -> Color:
	return Color(
		roundf(r * 7.0) / 7.0,
		roundf(g * 7.0) / 7.0,
		roundf(b * 7.0) / 7.0,
		a
	)

static func _px(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, col)

static func _px_rect(img: Image, x0: int, y0: int, x1: int, y1: int, col: Color) -> void:
	for x in range(maxi(x0, 0), mini(x1 + 1, img.get_width())):
		for y in range(maxi(y0, 0), mini(y1 + 1, img.get_height())):
			img.set_pixel(x, y, col)

static func _px_circle(img: Image, cx: int, cy: int, r: int, col: Color) -> void:
	for x in range(cx - r, cx + r + 1):
		for y in range(cy - r, cy + r + 1):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
				_px(img, x, y, col)

# ─── Pixel Sheep (48x48) — Storybook lamb with gear ───
# Wavy woolly body, curved horns, floppy ear, goggles, headphones,
# flowing superhero cape. Directional variants for up/down tilt.
# dir: 0=neutral, 1=tilted up, 2=tilted down

static func _draw_sheep_body(img: Image, leg_frame: int, dir: int = 0) -> void:
	var s := 48

	# Palette
	var wool := _md(0.95, 0.92, 0.88)
	var wool_light := _md(1.0, 1.0, 0.98)
	var wool_mid := _md(0.88, 0.84, 0.78)
	var wool_shadow := _md(0.78, 0.72, 0.65)
	var face := _md(0.95, 0.88, 0.82)
	var face_light := _md(1.0, 0.95, 0.9)
	var face_shadow := _md(0.82, 0.72, 0.62)
	var eye := _md(0.12, 0.1, 0.12)
	var eye_shine := _md(1.0, 1.0, 1.0)
	var nose := _md(0.3, 0.25, 0.22)
	var ear_dark := _md(0.3, 0.28, 0.25)
	var ear_inner := _md(0.55, 0.45, 0.4)
	var horn := _md(0.3, 0.28, 0.25)
	var legs := _md(0.82, 0.75, 0.65)
	var legs_dark := _md(0.65, 0.55, 0.45)
	var hooves := _md(0.45, 0.35, 0.28)
	var outline := _md(0.2, 0.18, 0.15)
	# Gear colors
	var goggle_frame := _md(0.45, 0.35, 0.25)
	var goggle_lens := _md(0.4, 0.7, 0.9)
	var goggle_shine := _md(0.7, 0.9, 1.0)
	var goggle_strap := _md(0.35, 0.28, 0.2)
	var hp_band := _md(0.25, 0.22, 0.2)
	var hp_cup := _md(0.3, 0.28, 0.25)
	var hp_pad := _md(0.5, 0.45, 0.4)
	var hp_detail := _md(0.6, 0.55, 0.5)
	var cape := _md(0.7, 0.15, 0.15)
	var cape_light := _md(0.85, 0.25, 0.2)
	var cape_dark := _md(0.5, 0.1, 0.1)
	var cape_deep := _md(0.35, 0.08, 0.08)

	# Direction offsets for perspective tilt
	var dy_head := 0   # Head vertical shift
	var dy_body := 0   # Body vertical shift
	var dy_legs := 0   # Leg vertical shift
	if dir == 1:   # Tilted UP — head rises, rear dips
		dy_head = -2
		dy_body = -1
		dy_legs = 1
	elif dir == 2: # Tilted DOWN — head dips, rear rises
		dy_head = 2
		dy_body = 1
		dy_legs = -1

	# ═══ CAPE (drawn first, behind everything) ═══
	# Flowing cape attached at neck area, billowing behind
	var cape_x := 4
	var cape_y := 14 + dy_body
	# Main cape body — large flowing shape
	_px_circle(img, cape_x + 4, cape_y + 6, 6, cape)
	_px_circle(img, cape_x + 2, cape_y + 10, 5, cape)
	_px_circle(img, cape_x + 6, cape_y + 4, 5, cape)
	_px_circle(img, cape_x, cape_y + 14, 4, cape)
	_px_circle(img, cape_x + 3, cape_y + 12, 5, cape_dark)
	# Cape folds and waves
	_px_rect(img, cape_x - 2, cape_y + 3, cape_x + 8, cape_y + 16, cape)
	_px_rect(img, cape_x - 3, cape_y + 8, cape_x + 3, cape_y + 18, cape)
	# Wavy bottom edge
	_px_circle(img, cape_x - 2, cape_y + 17, 3, cape)
	_px_circle(img, cape_x + 3, cape_y + 19, 3, cape_dark)
	_px_circle(img, cape_x + 7, cape_y + 16, 2, cape)
	if dir == 1:
		# Cape billows down more when going up
		_px_circle(img, cape_x - 1, cape_y + 20, 3, cape_dark)
		_px_circle(img, cape_x + 4, cape_y + 21, 2, cape_deep)
	elif dir == 2:
		# Cape flutters up when going down
		_px_circle(img, cape_x + 1, cape_y - 2, 3, cape)
		_px_circle(img, cape_x + 5, cape_y - 1, 2, cape_light)
	# Shading — highlights on left/top folds
	_px_circle(img, cape_x + 5, cape_y + 4, 3, cape_light)
	_px_circle(img, cape_x + 2, cape_y + 6, 2, cape_light)
	# Deep shadow on right/bottom folds
	_px_circle(img, cape_x, cape_y + 15, 3, cape_deep)
	_px_circle(img, cape_x + 5, cape_y + 12, 2, cape_dark)

	# ═══ WOOLLY BODY ═══
	var bx := 16
	var by := 18 + dy_body
	# Main mass
	_px_circle(img, bx, by, 10, wool)
	_px_circle(img, bx - 3, by - 2, 8, wool)
	_px_circle(img, bx + 4, by - 2, 8, wool)
	_px_circle(img, bx, by - 4, 7, wool)
	# Wavy top edge
	_px_circle(img, bx - 6, by - 7, 4, wool)
	_px_circle(img, bx - 1, by - 9, 4, wool)
	_px_circle(img, bx + 4, by - 8, 4, wool)
	_px_circle(img, bx + 8, by - 6, 3, wool)
	_px_circle(img, bx - 4, by - 9, 3, wool)
	_px_circle(img, bx + 2, by - 10, 3, wool)
	# Wavy sides
	_px_circle(img, bx - 9, by - 3, 4, wool)
	_px_circle(img, bx - 9, by + 1, 3, wool)
	_px_circle(img, bx + 9, by - 3, 4, wool)
	_px_circle(img, bx + 10, by + 1, 3, wool)
	# Wavy bottom
	_px_circle(img, bx - 6, by + 6, 3, wool)
	_px_circle(img, bx - 1, by + 7, 3, wool)
	_px_circle(img, bx + 4, by + 6, 3, wool)
	_px_circle(img, bx + 8, by + 5, 3, wool)
	# Shading
	_px_circle(img, bx - 4, by - 7, 3, wool_light)
	_px_circle(img, bx, by - 9, 2, wool_light)
	_px_circle(img, bx - 7, by - 2, 3, wool_light)
	_px_circle(img, bx + 3, by + 1, 4, wool_mid)
	_px_circle(img, bx + 6, by + 4, 3, wool_shadow)
	_px_circle(img, bx, by + 6, 3, wool_shadow)
	# Fluff details
	_px(img, bx - 5, by - 8, wool_light); _px(img, bx + 1, by - 10, wool_light)
	_px(img, bx - 8, by - 1, wool_light); _px(img, bx + 6, by - 7, wool_mid)
	_px(img, bx - 2, by + 5, wool_mid); _px(img, bx + 7, by - 1, wool_shadow)

	# ═══ HEAD / FACE ═══
	var hx := 35
	var hy := 15 + dy_head
	_px_circle(img, hx, hy, 7, face)
	_px_circle(img, hx + 1, hy - 1, 6, face)
	_px_circle(img, hx - 1, hy - 2, 4, face_light)
	_px_circle(img, hx + 1, hy + 3, 3, face_shadow)
	# Wool overlap onto head
	_px_circle(img, hx - 6, hy - 2, 4, wool)
	_px_circle(img, hx - 5, hy + 2, 3, wool)
	_px_circle(img, hx - 5, hy - 5, 3, wool)

	# ── Curved horns ──
	_px(img, hx - 2, hy - 8, horn); _px(img, hx - 1, hy - 9, horn)
	_px(img, hx, hy - 10, horn); _px(img, hx + 1, hy - 10, horn)
	_px(img, hx + 2, hy - 9, horn); _px(img, hx + 2, hy - 8, horn)
	# Second horn (behind)
	_px(img, hx - 5, hy - 7, horn); _px(img, hx - 6, hy - 8, horn)
	_px(img, hx - 6, hy - 9, horn); _px(img, hx - 5, hy - 9, horn)

	# ── Floppy ear ──
	_px_rect(img, hx - 5, hy - 1, hx - 3, hy + 5, ear_dark)
	_px(img, hx - 6, hy, ear_dark); _px(img, hx - 6, hy + 1, ear_dark)
	_px(img, hx - 6, hy + 2, ear_dark); _px(img, hx - 2, hy, ear_dark)
	_px(img, hx - 4, hy + 1, ear_inner); _px(img, hx - 4, hy + 2, ear_inner)
	_px(img, hx - 3, hy + 2, ear_inner)

	# ── Goggles — round lenses on forehead ──
	# Strap going around head
	_px_rect(img, hx - 4, hy - 5, hx + 5, hy - 4, goggle_strap)
	_px(img, hx - 5, hy - 4, goggle_strap); _px(img, hx + 6, hy - 4, goggle_strap)
	# Left lens frame (circle)
	_px_circle(img, hx + 1, hy - 3, 3, goggle_frame)
	_px_circle(img, hx + 1, hy - 3, 2, goggle_lens)
	_px(img, hx, hy - 4, goggle_shine); _px(img, hx + 1, hy - 4, goggle_shine)
	# Right lens frame (peeking)
	_px_circle(img, hx - 3, hy - 3, 2, goggle_frame)
	_px_circle(img, hx - 3, hy - 3, 1, goggle_lens)
	_px(img, hx - 3, hy - 4, goggle_shine)
	# Bridge between lenses
	_px(img, hx - 1, hy - 3, goggle_frame)

	# ── Headphones — over ear with band ──
	# Band over top of head (behind horns)
	_px_rect(img, hx - 3, hy - 7, hx + 2, hy - 7, hp_band)
	_px(img, hx - 4, hy - 6, hp_band); _px(img, hx + 3, hy - 6, hp_band)
	# Ear cup (visible side — on the ear area)
	_px_rect(img, hx - 7, hy - 2, hx - 5, hy + 3, hp_cup)
	_px_rect(img, hx - 6, hy - 1, hx - 6, hy + 2, hp_pad)
	_px(img, hx - 6, hy, hp_detail)
	# Far ear cup hint
	_px_rect(img, hx + 4, hy - 1, hx + 5, hy + 2, hp_cup)
	_px(img, hx + 4, hy, hp_pad)

	# ── Eyes — round with spiral hint ──
	var ey := hy + 0
	if dir == 1: ey -= 1   # Looking up
	if dir == 2: ey += 1   # Looking down
	_px(img, hx + 2, ey, eye); _px(img, hx + 3, ey, eye)
	_px(img, hx + 2, ey + 1, eye); _px(img, hx + 3, ey + 1, eye)
	_px(img, hx + 4, ey, eye); _px(img, hx + 4, ey + 1, eye)
	# Sparkle
	_px(img, hx + 2, ey, eye_shine)
	_px(img, hx + 3, ey, _md(0.3, 0.25, 0.25))

	# ── Snout / nose ──
	var ny := hy + 2
	if dir == 1: ny -= 1
	if dir == 2: ny += 1
	_px_circle(img, hx + 6, ny, 2, face)
	_px(img, hx + 7, ny, nose); _px(img, hx + 7, ny - 1, nose)
	_px(img, hx + 6, ny + 2, nose)
	# Tiny mouth
	_px(img, hx + 5, ny + 3, _md(0.4, 0.35, 0.3))

	# ── Cheek blush ──
	_px(img, hx + 3, ny + 1, _md(1.0, 0.7, 0.68))
	_px(img, hx + 4, ny + 1, _md(1.0, 0.7, 0.68))

	# ═══ LEGS ═══
	var ly := 27 + dy_legs
	if leg_frame == 0:
		_px_rect(img, 10, ly, 11, ly + 8, legs)
		_px_rect(img, 15, ly, 16, ly + 8, legs)
		_px_rect(img, 20, ly, 21, ly + 7, legs)
		_px_rect(img, 24, ly - 2, 25, ly + 7, legs)
		_px_rect(img, 11, ly + 2, 11, ly + 8, legs_dark)
		_px_rect(img, 16, ly + 2, 16, ly + 8, legs_dark)
		_px_rect(img, 21, ly + 2, 21, ly + 7, legs_dark)
		_px_rect(img, 25, ly, 25, ly + 7, legs_dark)
		_px_rect(img, 10, ly + 8, 12, ly + 9, hooves)
		_px_rect(img, 15, ly + 8, 17, ly + 9, hooves)
		_px_rect(img, 20, ly + 7, 22, ly + 8, hooves)
		_px_rect(img, 24, ly + 7, 26, ly + 8, hooves)
	else:
		_px_rect(img, 9, ly, 10, ly + 7, legs)
		_px_rect(img, 16, ly, 17, ly + 9, legs)
		_px_rect(img, 19, ly, 20, ly + 6, legs)
		_px_rect(img, 25, ly - 2, 26, ly + 9, legs)
		_px_rect(img, 10, ly + 2, 10, ly + 7, legs_dark)
		_px_rect(img, 17, ly + 2, 17, ly + 9, legs_dark)
		_px_rect(img, 20, ly + 2, 20, ly + 6, legs_dark)
		_px_rect(img, 26, ly, 26, ly + 9, legs_dark)
		_px_rect(img, 9, ly + 7, 11, ly + 8, hooves)
		_px_rect(img, 16, ly + 9, 18, ly + 10, hooves)
		_px_rect(img, 19, ly + 6, 21, ly + 7, hooves)
		_px_rect(img, 25, ly + 9, 27, ly + 10, hooves)

	# ═══ TAIL — woolly puff ═══
	var ty := 17 + dy_body
	_px_circle(img, 5, ty, 3, wool)
	_px_circle(img, 4, ty - 1, 2, wool_light)
	_px_circle(img, 5, ty + 1, 2, wool_mid)

	# ═══ OUTLINE ═══
	_auto_outline(img, s, outline)

static func _auto_outline(img: Image, s: int, outline: Color) -> void:
	var edge_pixels: Array = []
	for x in range(s):
		for y in range(s):
			if img.get_pixel(x, y).a > 0.5:
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						if dx == 0 and dy == 0:
							continue
						var nx: int = x + dx
						var ny: int = y + dy
						if nx >= 0 and ny >= 0 and nx < s and ny < s:
							if img.get_pixel(nx, ny).a < 0.1:
								edge_pixels.append(Vector2i(nx, ny))
	for p in edge_pixels:
		_px(img, p.x, p.y, outline)

static func generate_pixel_sheep(leg_frame: int = 0, dir: int = 0) -> ImageTexture:
	var s := 48
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_sheep_body(img, leg_frame, dir)
	return ImageTexture.create_from_image(img)

# Convenience aliases for backward compatibility
static func generate_pixel_sheep_frame2() -> ImageTexture:
	return generate_pixel_sheep(1, 0)

# ─── Meteors (variable size) ───

static func generate_meteor(size: int, seed_val: float) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := size / 2
	var cy := size / 2
	var r := size / 2 - 1

	var dark := _md(0.3, 0.2, 0.15)
	var mid := _md(0.5, 0.35, 0.25)
	var light := _md(0.65, 0.5, 0.35)
	var highlight := _md(0.8, 0.7, 0.55)
	var outline := _md(0.15, 0.1, 0.08)

	# Build jagged circle
	var rng := RandomNumberGenerator.new()
	rng.seed = int(seed_val * 1000.0)

	for x in range(size):
		for y in range(size):
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			var angle := atan2(dy, dx)
			# Jagged edge — perturb radius by angle
			var edge_r := float(r) + sin(angle * 5.0 + seed_val) * float(r) * 0.2 + sin(angle * 3.0 + seed_val * 2.0) * float(r) * 0.15
			if dist <= edge_r:
				# Shading — top-left lighter
				var shade := clampf(0.5 - float(dx) / float(size) * 0.4 - float(dy) / float(size) * 0.3, 0.0, 1.0)
				var col: Color
				if shade > 0.6:
					col = highlight
				elif shade > 0.4:
					col = light
				elif shade > 0.2:
					col = mid
				else:
					col = dark
				_px(img, x, y, col)
				# Outline
				if dist > edge_r - 1.5:
					_px(img, x, y, outline)

	# Crater details
	for i in range(rng.randi_range(1, 3)):
		var cr_x := cx + rng.randi_range(-r / 2, r / 2)
		var cr_y := cy + rng.randi_range(-r / 2, r / 2)
		var cr_r := rng.randi_range(1, maxi(r / 4, 2))
		_px_circle(img, cr_x, cr_y, cr_r, dark)

	return ImageTexture.create_from_image(img)

# ─── Mini Collectibles (10x10) ───

static func generate_mini_collectible(type: String) -> ImageTexture:
	var s := 10
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	match type:
		"cassette":
			_draw_cassette_mini(img)
		"headphones":
			_draw_headphones_mini(img)
		"wool":
			_draw_wool_mini(img)
		"debris":
			_draw_debris_mini(img)
		"salvage":
			_draw_salvage_mini(img)
		"music_note":
			_draw_music_note_mini(img)

	return ImageTexture.create_from_image(img)

static func _draw_cassette_mini(img: Image) -> void:
	var body := _md(0.7, 0.5, 0.2)
	var dark := _md(0.4, 0.25, 0.1)
	var label := _md(1.0, 0.85, 0.3)
	# Body
	_px_rect(img, 1, 2, 8, 7, body)
	# Label strip
	_px_rect(img, 2, 3, 7, 4, label)
	# Reels
	_px(img, 3, 6, dark)
	_px(img, 6, 6, dark)
	# Top edge
	_px_rect(img, 2, 2, 7, 2, dark)

static func _draw_headphones_mini(img: Image) -> void:
	var band := _md(1.0, 0.1, 0.45)       # Hot pink
	var pad := _md(1.0, 0.6, 0.05)        # Orange
	# Band arc
	_px(img, 3, 1, band)
	_px(img, 4, 1, band)
	_px(img, 5, 1, band)
	_px(img, 6, 1, band)
	_px(img, 2, 2, band)
	_px(img, 7, 2, band)
	# Left pad
	_px_rect(img, 1, 3, 2, 6, pad)
	# Right pad
	_px_rect(img, 7, 3, 8, 6, pad)

static func _draw_wool_mini(img: Image) -> void:
	var wool := _md(1.0, 0.9, 1.0)
	var wool_dark := _md(0.8, 0.7, 0.85)
	# Fluffy puff cluster
	_px_circle(img, 5, 5, 3, wool)
	_px_circle(img, 3, 4, 2, wool)
	_px_circle(img, 6, 3, 2, wool)
	_px_circle(img, 4, 6, 2, wool_dark)

static func _draw_debris_mini(img: Image) -> void:
	var metal := _md(0.5, 0.55, 0.65)
	var dark := _md(0.3, 0.35, 0.4)
	var light := _md(0.7, 0.75, 0.85)
	# Angular shard
	_px_rect(img, 2, 3, 7, 6, metal)
	_px_rect(img, 3, 2, 6, 7, metal)
	_px(img, 3, 3, light)
	_px(img, 4, 3, light)
	_px(img, 6, 6, dark)
	_px(img, 7, 6, dark)

static func _draw_salvage_mini(img: Image) -> void:
	var blue := _md(0.35, 0.5, 0.75)
	var rivet := _md(0.7, 0.7, 0.75)
	var dark := _md(0.2, 0.3, 0.5)
	# Metal plate
	_px_rect(img, 2, 2, 8, 7, blue)
	_px_rect(img, 2, 2, 8, 2, dark)
	# Rivets
	_px(img, 3, 4, rivet)
	_px(img, 7, 4, rivet)
	_px(img, 3, 6, rivet)
	_px(img, 7, 6, rivet)

static func _draw_music_note_mini(img: Image) -> void:
	var gold := _md(1.0, 0.85, 0.15)
	var gold_light := _md(1.0, 1.0, 0.5)
	# Eighth note
	_px_circle(img, 4, 7, 2, gold)
	_px_circle(img, 4, 7, 1, gold_light)
	# Stem
	_px(img, 6, 2, gold)
	_px(img, 6, 3, gold)
	_px(img, 6, 4, gold)
	_px(img, 6, 5, gold)
	_px(img, 6, 6, gold)
	_px(img, 6, 7, gold)
	# Flag
	_px(img, 7, 2, gold)
	_px(img, 8, 3, gold)
	_px(img, 8, 4, gold)

# ─── Golden Star (The Little Prince) — 12x12 ───

static func generate_golden_star() -> ImageTexture:
	var s := 12
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var gold := _md(1.0, 0.85, 0.15)
	var gold_light := _md(1.0, 1.0, 0.5)
	var gold_dark := _md(0.8, 0.6, 0.05)
	var glow := _md(1.0, 0.95, 0.7)
	# Five-pointed star shape
	# Top point
	_px(img, 5, 0, gold_light); _px(img, 6, 0, gold_light)
	_px(img, 5, 1, gold); _px(img, 6, 1, gold)
	# Upper body
	_px_rect(img, 4, 2, 7, 3, gold)
	_px_rect(img, 3, 3, 8, 4, gold)
	# Arms
	_px(img, 0, 4, gold); _px(img, 1, 4, gold); _px(img, 2, 4, gold)
	_px_rect(img, 3, 4, 8, 5, gold)
	_px(img, 9, 4, gold); _px(img, 10, 4, gold); _px(img, 11, 4, gold)
	# Mid body
	_px_rect(img, 3, 5, 8, 6, gold)
	# Lower spread
	_px_rect(img, 2, 7, 9, 7, gold)
	_px(img, 1, 8, gold); _px(img, 2, 8, gold)
	_px(img, 9, 8, gold); _px(img, 10, 8, gold)
	# Bottom points (two feet)
	_px(img, 1, 9, gold_dark); _px(img, 10, 9, gold_dark)
	# Central highlight
	_px(img, 5, 3, gold_light); _px(img, 6, 3, gold_light)
	_px(img, 5, 4, gold_light); _px(img, 6, 4, gold_light)
	# Warm glow center
	_px(img, 5, 5, glow); _px(img, 6, 5, glow)
	# Shadow on lower half
	_px_rect(img, 4, 6, 7, 7, gold_dark)
	return ImageTexture.create_from_image(img)

# ─── Shield Power-Up Icon (10x10) ───

static func generate_shield_icon() -> ImageTexture:
	var s := 10
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cyan := _md(0.2, 0.9, 1.0)
	var cyan_light := _md(0.6, 1.0, 1.0)
	var cyan_dark := _md(0.1, 0.5, 0.7)
	# Shield shape
	_px_rect(img, 2, 1, 7, 2, cyan)
	_px_rect(img, 1, 2, 8, 5, cyan)
	_px_rect(img, 2, 5, 7, 7, cyan)
	_px_rect(img, 3, 7, 6, 8, cyan)
	_px(img, 4, 9, cyan); _px(img, 5, 9, cyan)
	# Highlight
	_px_rect(img, 3, 2, 4, 4, cyan_light)
	# Shadow
	_px_rect(img, 6, 5, 7, 7, cyan_dark)
	return ImageTexture.create_from_image(img)

# ─── Magnet Power-Up Icon (10x10) ───

static func generate_magnet_icon() -> ImageTexture:
	var s := 10
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var red := _md(1.0, 0.2, 0.2)
	var blue := _md(0.2, 0.3, 1.0)
	var metal := _md(0.75, 0.75, 0.8)
	# U-shape magnet
	_px_rect(img, 1, 1, 2, 6, red)
	_px_rect(img, 7, 1, 8, 6, blue)
	_px_rect(img, 2, 6, 7, 7, metal)
	_px_rect(img, 3, 7, 6, 8, metal)
	# Tips
	_px_rect(img, 1, 1, 2, 2, _md(1.0, 0.5, 0.5))
	_px_rect(img, 7, 1, 8, 2, _md(0.5, 0.5, 1.0))
	return ImageTexture.create_from_image(img)

# ─── The Rose (The Little Prince) — 14x16 with glass dome ───

static func generate_rose() -> ImageTexture:
	var img := Image.create(14, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var red := _md(1.0, 0.15, 0.25)
	var red_light := _md(1.0, 0.4, 0.45)
	var red_dark := _md(0.7, 0.05, 0.15)
	var stem := _md(0.15, 0.7, 0.25)
	var stem_dark := _md(0.1, 0.5, 0.15)
	var leaf := _md(0.2, 0.8, 0.3)
	var glass := _md(0.7, 0.85, 1.0)
	var glass_dim := _md(0.4, 0.55, 0.7)
	# Glass dome
	_px(img, 5, 1, glass); _px(img, 6, 1, glass); _px(img, 7, 1, glass); _px(img, 8, 1, glass)
	_px(img, 4, 2, glass); _px(img, 9, 2, glass)
	_px(img, 3, 3, glass); _px(img, 10, 3, glass)
	_px(img, 3, 4, glass_dim); _px(img, 10, 4, glass_dim)
	_px(img, 3, 5, glass_dim); _px(img, 10, 5, glass_dim)
	_px(img, 3, 6, glass_dim); _px(img, 10, 6, glass_dim)
	_px(img, 3, 7, glass_dim); _px(img, 10, 7, glass_dim)
	_px(img, 3, 8, glass_dim); _px(img, 10, 8, glass_dim)
	_px(img, 3, 9, glass_dim); _px(img, 10, 9, glass_dim)
	# Dome highlight
	_px(img, 4, 2, Color(1, 1, 1, 0.5)); _px(img, 5, 2, Color(1, 1, 1, 0.3))
	# Rose petals (inside dome)
	_px_rect(img, 5, 3, 8, 4, red)
	_px_rect(img, 5, 5, 8, 6, red)
	_px(img, 6, 2, red_light); _px(img, 7, 2, red_light)
	_px(img, 5, 4, red_light); _px(img, 8, 3, red_dark)
	_px(img, 6, 6, red_dark); _px(img, 7, 6, red_dark)
	# Stem
	_px(img, 6, 7, stem); _px(img, 7, 7, stem)
	_px(img, 6, 8, stem); _px(img, 7, 8, stem)
	_px(img, 6, 9, stem_dark); _px(img, 7, 9, stem_dark)
	# Leaves
	_px(img, 5, 8, leaf); _px(img, 8, 7, leaf)
	# Base plate
	_px_rect(img, 2, 10, 11, 11, glass_dim)
	_px_rect(img, 3, 10, 10, 10, glass)
	return ImageTexture.create_from_image(img)

# ─── The Fox (The Little Prince) — 16x12 ───

static func generate_fox() -> ImageTexture:
	var img := Image.create(16, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var orange := _md(1.0, 0.6, 0.15)
	var orange_light := _md(1.0, 0.75, 0.35)
	var orange_dark := _md(0.75, 0.4, 0.05)
	var white := _md(1.0, 0.95, 0.9)
	var eye := _md(0.1, 0.1, 0.12)
	var nose := _md(0.15, 0.12, 0.1)
	var ear_inner := _md(1.0, 0.5, 0.4)
	var outline := _md(0.3, 0.18, 0.08)
	# Body
	_px_rect(img, 4, 5, 11, 8, orange)
	_px_rect(img, 5, 4, 10, 9, orange)
	# Belly
	_px_rect(img, 6, 7, 9, 9, white)
	# Head
	_px_rect(img, 1, 3, 5, 7, orange)
	_px_rect(img, 2, 2, 4, 8, orange)
	# Face highlight
	_px(img, 2, 4, orange_light); _px(img, 3, 4, orange_light)
	# Muzzle
	_px(img, 1, 5, white); _px(img, 1, 6, white); _px(img, 2, 6, white)
	# Nose
	_px(img, 0, 5, nose)
	# Eye
	_px(img, 2, 3, eye)
	_px(img, 2, 4, Color(1, 1, 1))  # Shine
	# Ears (pointed)
	_px(img, 2, 1, orange); _px(img, 3, 0, orange); _px(img, 4, 1, orange)
	_px(img, 3, 1, ear_inner)
	# Tail (big fluffy)
	_px_rect(img, 12, 4, 14, 7, orange)
	_px(img, 15, 5, orange_light); _px(img, 15, 6, orange_light)
	_px(img, 14, 4, orange_light)
	_px(img, 13, 7, white)  # White tail tip
	_px(img, 14, 7, white)
	# Legs
	_px(img, 5, 9, orange_dark); _px(img, 6, 9, orange_dark)
	_px(img, 9, 9, orange_dark); _px(img, 10, 9, orange_dark)
	_px(img, 5, 10, outline); _px(img, 6, 10, outline)
	_px(img, 9, 10, outline); _px(img, 10, 10, outline)
	# Shadow
	_px_rect(img, 8, 8, 11, 8, orange_dark)
	return ImageTexture.create_from_image(img)

# ─── Tiny Planet B-612 (background) — 20x20 ───

static func generate_tiny_planet() -> ImageTexture:
	var img := Image.create(20, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var ground := _md(0.45, 0.6, 0.3)
	var ground_dark := _md(0.3, 0.45, 0.2)
	var ground_light := _md(0.55, 0.7, 0.4)
	# Planet sphere
	_px_circle(img, 10, 12, 7, ground)
	_px_circle(img, 9, 11, 5, ground_light)
	_px_circle(img, 11, 14, 4, ground_dark)
	# Tiny figure (The Prince) standing on top
	var hair := _md(1.0, 0.85, 0.2)
	var scarf := _md(1.0, 0.75, 0.1)
	var coat := _md(0.2, 0.4, 0.8)
	# Head
	_px(img, 10, 3, _md(1.0, 0.85, 0.7))
	_px(img, 10, 2, hair); _px(img, 11, 2, hair); _px(img, 10, 1, hair)
	# Body
	_px(img, 10, 4, coat); _px(img, 10, 5, coat)
	# Scarf flowing
	_px(img, 11, 3, scarf); _px(img, 12, 3, scarf); _px(img, 13, 2, scarf)
	# Legs
	_px(img, 9, 6, coat); _px(img, 11, 6, coat)
	return ImageTexture.create_from_image(img)

# ─── Baobab Tree — 12x14 ───

static func generate_baobab() -> ImageTexture:
	var img := Image.create(12, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var trunk := _md(0.5, 0.35, 0.2)
	var trunk_dark := _md(0.35, 0.22, 0.12)
	var crown := _md(0.25, 0.55, 0.2)
	var crown_light := _md(0.35, 0.7, 0.25)
	var crown_dark := _md(0.15, 0.4, 0.12)
	# Crown (big round)
	_px_circle(img, 6, 3, 4, crown)
	_px_circle(img, 4, 4, 3, crown)
	_px_circle(img, 8, 4, 3, crown)
	_px_circle(img, 5, 2, 2, crown_light)
	_px_circle(img, 7, 5, 2, crown_dark)
	# Trunk (thick)
	_px_rect(img, 5, 7, 7, 12, trunk)
	_px_rect(img, 4, 8, 5, 11, trunk)
	_px(img, 7, 8, trunk_dark); _px(img, 7, 10, trunk_dark)
	# Roots
	_px(img, 3, 12, trunk_dark); _px(img, 4, 13, trunk_dark)
	_px(img, 8, 12, trunk_dark); _px(img, 9, 13, trunk_dark)
	return ImageTexture.create_from_image(img)

# ─── Slow-Mo Power-Up Icon (10x10) ───

static func generate_slowmo_icon() -> ImageTexture:
	var s := 10
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var purple := _md(0.6, 0.3, 1.0)
	var purple_light := _md(0.8, 0.5, 1.0)
	var purple_dark := _md(0.35, 0.15, 0.6)
	# Clock face
	_px_circle(img, 5, 5, 4, purple)
	_px_circle(img, 5, 5, 3, purple_dark)
	_px_circle(img, 5, 5, 2, purple)
	# Clock hands
	_px(img, 5, 3, purple_light)  # 12 o'clock
	_px(img, 5, 4, purple_light)
	_px(img, 6, 5, purple_light)  # 3 o'clock
	# Rim highlight
	_px(img, 4, 1, purple_light); _px(img, 5, 1, purple_light); _px(img, 6, 1, purple_light)
	return ImageTexture.create_from_image(img)

# ─── Heart (8x8) ───

static func generate_heart() -> ImageTexture:
	var s := 8
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var red := _md(1.0, 0.15, 0.2)
	var pink := _md(1.0, 0.5, 0.5)
	var dark := _md(0.6, 0.05, 0.1)
	# Heart shape
	_px(img, 1, 2, red); _px(img, 2, 1, red); _px(img, 3, 1, red)
	_px(img, 4, 1, red); _px(img, 5, 1, red); _px(img, 6, 2, red)
	_px(img, 0, 3, red); _px(img, 1, 3, red); _px(img, 2, 2, red)
	_px(img, 3, 2, red); _px(img, 4, 2, red); _px(img, 5, 2, red)
	_px(img, 6, 3, red); _px(img, 7, 3, red)
	_px(img, 0, 4, red); _px(img, 1, 4, red); _px(img, 2, 3, red)
	_px(img, 3, 3, red); _px(img, 4, 3, red); _px(img, 5, 3, red)
	_px(img, 6, 4, red); _px(img, 7, 4, red)
	_px(img, 1, 5, red); _px(img, 2, 4, red); _px(img, 3, 4, red)
	_px(img, 4, 4, red); _px(img, 5, 4, red); _px(img, 6, 5, red)
	_px(img, 2, 5, red); _px(img, 3, 5, red); _px(img, 4, 5, red); _px(img, 5, 5, red)
	_px(img, 3, 6, red); _px(img, 4, 6, red)
	# Highlight
	_px(img, 2, 2, pink); _px(img, 3, 2, pink)
	# Shadow
	_px(img, 5, 5, dark); _px(img, 4, 6, dark)
	return ImageTexture.create_from_image(img)

static func generate_heart_empty() -> ImageTexture:
	var s := 8
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dim := _md(0.3, 0.1, 0.12)
	_px(img, 1, 2, dim); _px(img, 2, 1, dim); _px(img, 3, 1, dim)
	_px(img, 4, 1, dim); _px(img, 5, 1, dim); _px(img, 6, 2, dim)
	_px(img, 0, 3, dim); _px(img, 7, 3, dim)
	_px(img, 0, 4, dim); _px(img, 7, 4, dim)
	_px(img, 1, 5, dim); _px(img, 6, 5, dim)
	_px(img, 2, 5, dim); _px(img, 5, 5, dim)
	_px(img, 3, 6, dim); _px(img, 4, 6, dim)
	return ImageTexture.create_from_image(img)

# ─── Arcade Terminal (32x32) ───

static func generate_arcade_terminal() -> ImageTexture:
	var s := 32
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var frame := _md(0.25, 0.25, 0.3)
	var screen_bg := _md(0.0, 0.1, 0.15)
	var screen_glow := _md(0.0, 0.7, 0.5)
	var text := _md(0.0, 1.0, 0.8)
	var stand := _md(0.3, 0.3, 0.35)
	var accent := _md(1.0, 0.3, 0.5)

	# Stand
	_px_rect(img, 13, 25, 18, 30, stand)
	_px_rect(img, 10, 29, 21, 31, stand)

	# Monitor frame
	_px_rect(img, 4, 3, 27, 24, frame)
	# Screen
	_px_rect(img, 6, 5, 25, 22, screen_bg)

	# Scanlines on screen
	for y in range(5, 22, 2):
		for x in range(6, 25):
			var px := img.get_pixel(x, y)
			if px.a > 0.5:
				_px(img, x, y, Color(px.r + 0.02, px.g + 0.03, px.b + 0.03, px.a))

	# "PLAY" text approximation
	# P
	_px(img, 9, 10, text); _px(img, 9, 11, text); _px(img, 9, 12, text); _px(img, 9, 13, text)
	_px(img, 10, 10, text); _px(img, 11, 10, text); _px(img, 11, 11, text); _px(img, 10, 11, text)
	# L
	_px(img, 13, 10, text); _px(img, 13, 11, text); _px(img, 13, 12, text); _px(img, 13, 13, text)
	_px(img, 14, 13, text); _px(img, 15, 13, text)
	# A
	_px(img, 17, 10, text); _px(img, 17, 11, text); _px(img, 17, 12, text); _px(img, 17, 13, text)
	_px(img, 18, 10, text); _px(img, 19, 10, text); _px(img, 19, 11, text); _px(img, 19, 12, text); _px(img, 19, 13, text)
	_px(img, 18, 12, text)
	# Y
	_px(img, 21, 10, text); _px(img, 21, 11, text); _px(img, 22, 12, text); _px(img, 22, 13, text)
	_px(img, 23, 10, text); _px(img, 23, 11, text)

	# Screen edge glow
	for x in range(6, 25):
		_px(img, x, 5, screen_glow)
	for y in range(5, 22):
		_px(img, 6, y, Color(screen_glow.r, screen_glow.g, screen_glow.b, 0.3))

	# Accent LED
	_px(img, 15, 24, accent)
	_px(img, 16, 24, accent)

	return ImageTexture.create_from_image(img)

# ─── Boss Baobab on Planet (64x64) — Menacing tree on a Little-Prince planet ───

static func generate_boss_baobab() -> ImageTexture:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Palette — twisted tree with CRT monitors
	var trunk_cream := _md(0.78, 0.68, 0.45)
	var trunk_tan := _md(0.65, 0.52, 0.3)
	var trunk_stripe := _md(0.5, 0.35, 0.18)
	var trunk_dark := _md(0.3, 0.18, 0.08)
	var trunk_deep := _md(0.15, 0.08, 0.03)
	var crevice := _md(0.08, 0.04, 0.02)
	var root := _md(0.55, 0.4, 0.22)
	var root_dark := _md(0.4, 0.25, 0.12)
	var root_tip := _md(0.45, 0.3, 0.15)
	var monitor_frame := _md(0.45, 0.42, 0.5)
	var monitor_dark := _md(0.3, 0.28, 0.35)
	var monitor_light := _md(0.55, 0.52, 0.6)
	var screen_bg := _md(0.02, 0.05, 0.08)
	var static_bright := _md(0.8, 0.85, 0.9)
	var static_mid := _md(0.5, 0.55, 0.6)
	var static_dim := _md(0.25, 0.28, 0.3)
	var warn_red := _md(1.0, 0.15, 0.0)
	var warn_yellow := _md(1.0, 0.85, 0.0)
	var radar_green := _md(0.0, 1.0, 0.3)
	var radar_dim := _md(0.0, 0.55, 0.15)
	var lightning := _md(0.7, 0.85, 1.0)
	var cable := _md(0.2, 0.18, 0.22)
	var led_red := _md(1.0, 0.0, 0.0)
	var led_green := _md(0.0, 1.0, 0.0)
	var led_yellow := _md(1.0, 1.0, 0.0)
	var outline := _md(0.08, 0.06, 0.04)

	# ═══ ROOTS — sprawling tentacle-like at bottom ═══
	# Central root mass
	_px_rect(img, 26, 52, 37, 56, root)
	_px_rect(img, 24, 54, 39, 58, root_dark)
	# Left roots (curving)
	_px_rect(img, 20, 50, 27, 53, root)
	_px_rect(img, 16, 52, 22, 55, root)
	_px_rect(img, 13, 54, 18, 57, root_dark)
	_px_rect(img, 10, 56, 15, 58, root_tip)
	_px(img, 9, 57, root_tip); _px(img, 8, 58, root_tip)
	# More left root tendrils
	_px_rect(img, 18, 56, 21, 59, root_dark)
	_px_rect(img, 15, 58, 19, 60, root_tip)
	_px(img, 14, 59, root_tip); _px(img, 22, 58, root_dark)
	# Right roots (curving)
	_px_rect(img, 36, 50, 43, 53, root)
	_px_rect(img, 41, 52, 47, 55, root)
	_px_rect(img, 45, 54, 50, 57, root_dark)
	_px_rect(img, 48, 56, 53, 58, root_tip)
	_px(img, 54, 57, root_tip); _px(img, 55, 58, root_tip)
	# More right root tendrils
	_px_rect(img, 42, 56, 46, 59, root_dark)
	_px_rect(img, 44, 58, 48, 60, root_tip)
	_px(img, 49, 59, root_tip); _px(img, 41, 58, root_dark)
	# Center dangling roots
	_px_rect(img, 29, 56, 31, 60, root_dark)
	_px_rect(img, 33, 57, 35, 61, root_tip)
	_px(img, 30, 61, root_tip); _px(img, 34, 62, root_tip)

	# ═══ TRUNK — thick gnarled with horizontal bark stripes ═══
	# Main trunk mass
	_px_rect(img, 25, 22, 38, 52, trunk_cream)
	_px_rect(img, 23, 26, 40, 48, trunk_cream)
	# Wider bulge in middle
	_px_rect(img, 22, 30, 41, 42, trunk_tan)
	# Bark stripe patterns — horizontal wrapping bands
	_px_rect(img, 24, 24, 39, 25, trunk_stripe)
	_px_rect(img, 23, 29, 40, 30, trunk_stripe)
	_px_rect(img, 22, 34, 41, 35, trunk_stripe)
	_px_rect(img, 23, 39, 40, 40, trunk_stripe)
	_px_rect(img, 24, 44, 39, 45, trunk_stripe)
	_px_rect(img, 25, 49, 38, 50, trunk_stripe)
	# Darker shading on right side
	_px_rect(img, 37, 23, 40, 51, trunk_tan)
	_px_rect(img, 39, 28, 41, 46, trunk_stripe)
	# Left side light
	_px_rect(img, 24, 27, 26, 43, trunk_cream)

	# ═══ DARK CREVICES in trunk ═══
	_px_rect(img, 29, 32, 34, 37, crevice)
	_px_rect(img, 30, 31, 33, 38, crevice)
	_px(img, 28, 33, crevice); _px(img, 35, 35, crevice)
	_px_rect(img, 31, 33, 32, 36, trunk_deep)
	# Smaller crevice higher up
	_px_rect(img, 27, 26, 30, 28, trunk_deep)
	_px(img, 26, 27, crevice); _px(img, 31, 27, trunk_deep)

	# ═══ TWISTED BRANCHES reaching up and out ═══
	# Left branch — curves up-left to hold monitor
	_px_rect(img, 18, 20, 25, 23, trunk_tan)
	_px_rect(img, 14, 17, 20, 21, trunk_tan)
	_px_rect(img, 11, 14, 16, 18, trunk_stripe)
	_px_rect(img, 15, 20, 19, 20, trunk_stripe)
	# Sub-tendrils off left branch
	_px_rect(img, 12, 18, 13, 22, root_dark)
	_px(img, 11, 22, root_tip); _px(img, 10, 23, root_tip)
	_px_rect(img, 17, 17, 18, 14, root_dark)

	# Right branch — curves up-right to hold monitor
	_px_rect(img, 38, 19, 45, 22, trunk_tan)
	_px_rect(img, 43, 16, 49, 20, trunk_tan)
	_px_rect(img, 47, 13, 52, 17, trunk_stripe)
	_px_rect(img, 44, 19, 48, 19, trunk_stripe)
	# Sub-tendrils off right branch
	_px_rect(img, 50, 17, 51, 21, root_dark)
	_px(img, 52, 21, root_tip); _px(img, 53, 22, root_tip)
	_px_rect(img, 45, 16, 46, 13, root_dark)

	# Upper branch — goes straight up for center monitor
	_px_rect(img, 29, 14, 34, 22, trunk_tan)
	_px_rect(img, 30, 10, 33, 15, trunk_tan)
	_px_rect(img, 30, 18, 33, 18, trunk_stripe)
	_px_rect(img, 31, 13, 32, 13, trunk_stripe)

	# Lower-right branch for 4th monitor
	_px_rect(img, 40, 36, 47, 39, trunk_tan)
	_px_rect(img, 46, 33, 52, 37, trunk_stripe)
	_px_rect(img, 42, 38, 46, 38, trunk_stripe)

	# Cables between trunk and monitors
	_px(img, 13, 13, cable); _px(img, 12, 12, cable)
	_px(img, 50, 12, cable); _px(img, 51, 11, cable)
	_px(img, 31, 9, cable); _px(img, 32, 8, cable)
	_px(img, 52, 32, cable); _px(img, 53, 31, cable)

	# ═══ CRT MONITOR 1 — top-left (static/snow) ═══
	var m1x := 3; var m1y := 4
	# Frame
	_px_rect(img, m1x, m1y, m1x + 13, m1y + 11, monitor_frame)
	_px_rect(img, m1x + 1, m1y + 1, m1x + 12, m1y + 10, monitor_dark)
	_px_rect(img, m1x, m1y, m1x + 13, m1y, monitor_light)
	_px_rect(img, m1x, m1y, m1x, m1y + 11, monitor_light)
	# Screen
	_px_rect(img, m1x + 2, m1y + 2, m1x + 11, m1y + 9, screen_bg)
	# Static snow pattern
	_px(img, m1x + 3, m1y + 3, static_bright); _px(img, m1x + 6, m1y + 3, static_mid)
	_px(img, m1x + 9, m1y + 4, static_bright); _px(img, m1x + 4, m1y + 5, static_dim)
	_px(img, m1x + 7, m1y + 5, static_bright); _px(img, m1x + 10, m1y + 6, static_mid)
	_px(img, m1x + 3, m1y + 7, static_mid); _px(img, m1x + 5, m1y + 6, static_bright)
	_px(img, m1x + 8, m1y + 7, static_dim); _px(img, m1x + 10, m1y + 8, static_bright)
	_px(img, m1x + 4, m1y + 8, static_bright); _px(img, m1x + 7, m1y + 9, static_mid)
	# Antenna
	_px(img, m1x + 4, m1y - 1, cable); _px(img, m1x + 3, m1y - 2, cable)
	_px(img, m1x + 9, m1y - 1, cable); _px(img, m1x + 10, m1y - 2, cable)

	# ═══ CRT MONITOR 2 — top-center (warning ! symbol) ═══
	var m2x := 26; var m2y := 0
	# Frame
	_px_rect(img, m2x, m2y, m2x + 11, m2y + 10, monitor_frame)
	_px_rect(img, m2x + 1, m2y + 1, m2x + 10, m2y + 9, monitor_dark)
	_px_rect(img, m2x, m2y, m2x + 11, m2y, monitor_light)
	_px_rect(img, m2x, m2y, m2x, m2y + 10, monitor_light)
	# Screen — red background with warning triangle
	_px_rect(img, m2x + 2, m2y + 2, m2x + 9, m2y + 8, warn_red)
	# Yellow warning triangle
	_px(img, m2x + 5, m2y + 3, warn_yellow); _px(img, m2x + 6, m2y + 3, warn_yellow)
	_px(img, m2x + 4, m2y + 4, warn_yellow); _px(img, m2x + 7, m2y + 4, warn_yellow)
	_px(img, m2x + 3, m2y + 5, warn_yellow); _px(img, m2x + 8, m2y + 5, warn_yellow)
	_px(img, m2x + 3, m2y + 6, warn_yellow); _px(img, m2x + 4, m2y + 6, warn_yellow)
	_px(img, m2x + 5, m2y + 6, warn_yellow); _px(img, m2x + 6, m2y + 6, warn_yellow)
	_px(img, m2x + 7, m2y + 6, warn_yellow); _px(img, m2x + 8, m2y + 6, warn_yellow)
	# ! mark
	_px(img, m2x + 5, m2y + 4, crevice); _px(img, m2x + 6, m2y + 4, crevice)
	_px(img, m2x + 5, m2y + 5, crevice); _px(img, m2x + 6, m2y + 5, crevice)
	# LEDs at bottom of frame
	_px(img, m2x + 3, m2y + 9, led_red); _px(img, m2x + 5, m2y + 9, led_yellow)

	# ═══ CRT MONITOR 3 — top-right (radar/grid) ═══
	var m3x := 47; var m3y := 3
	# Frame
	_px_rect(img, m3x, m3y, m3x + 13, m3y + 11, monitor_frame)
	_px_rect(img, m3x + 1, m3y + 1, m3x + 12, m3y + 10, monitor_dark)
	_px_rect(img, m3x, m3y, m3x + 13, m3y, monitor_light)
	_px_rect(img, m3x, m3y, m3x, m3y + 11, monitor_light)
	# Screen — dark with green grid
	_px_rect(img, m3x + 2, m3y + 2, m3x + 11, m3y + 9, screen_bg)
	# Grid lines
	for gx in range(m3x + 4, m3x + 11, 3):
		for gy in range(m3y + 2, m3y + 10):
			_px(img, gx, gy, radar_dim)
	for gy in range(m3y + 4, m3y + 9, 3):
		for gx in range(m3x + 2, m3x + 12):
			_px(img, gx, gy, radar_dim)
	# Radar blip
	_px(img, m3x + 7, m3y + 5, radar_green)
	_px(img, m3x + 6, m3y + 5, radar_dim); _px(img, m3x + 8, m3y + 5, radar_dim)
	_px(img, m3x + 7, m3y + 4, radar_dim); _px(img, m3x + 7, m3y + 6, radar_dim)
	# Antenna
	_px(img, m3x + 10, m3y - 1, cable); _px(img, m3x + 11, m3y - 2, cable)
	# LEDs
	_px(img, m3x + 10, m3y + 10, led_green); _px(img, m3x + 8, m3y + 10, led_red)

	# ═══ CRT MONITOR 4 — lower-right (lightning/energy) ═══
	var m4x := 50; var m4y := 26
	# Frame
	_px_rect(img, m4x, m4y, m4x + 12, m4y + 10, monitor_frame)
	_px_rect(img, m4x + 1, m4y + 1, m4x + 11, m4y + 9, monitor_dark)
	_px_rect(img, m4x, m4y, m4x + 12, m4y, monitor_light)
	_px_rect(img, m4x, m4y, m4x, m4y + 10, monitor_light)
	# Screen — dark blue with lightning
	_px_rect(img, m4x + 2, m4y + 2, m4x + 10, m4y + 8, screen_bg)
	# Lightning bolt
	_px(img, m4x + 5, m4y + 2, lightning); _px(img, m4x + 4, m4y + 3, lightning)
	_px(img, m4x + 5, m4y + 4, lightning); _px(img, m4x + 6, m4y + 4, lightning)
	_px(img, m4x + 7, m4y + 5, lightning); _px(img, m4x + 6, m4y + 6, lightning)
	_px(img, m4x + 5, m4y + 7, lightning); _px(img, m4x + 7, m4y + 7, lightning)
	_px(img, m4x + 8, m4y + 8, lightning)
	# Secondary bolt
	_px(img, m4x + 8, m4y + 3, static_mid); _px(img, m4x + 9, m4y + 4, static_bright)
	_px(img, m4x + 8, m4y + 5, static_mid)
	# LEDs
	_px(img, m4x + 2, m4y + 9, led_yellow); _px(img, m4x + 4, m4y + 9, led_green)
	_px(img, m4x + 6, m4y + 9, led_red)

	# ═══ OUTLINE ═══
	_auto_outline(img, s, outline)

	return ImageTexture.create_from_image(img)

# ─── Barbed Wire Segment (32x8) — Horizontal projectile ───

static func generate_barbed_wire() -> ImageTexture:
	var w := 32
	var h := 8
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var wire := _md(0.6, 0.6, 0.65)
	var wire_dark := _md(0.4, 0.4, 0.45)
	var rust := _md(0.7, 0.4, 0.15)
	var rust_dark := _md(0.5, 0.25, 0.1)

	# Main horizontal wire — slightly wavy, two strands twisted
	for x in range(0, 32):
		# Upper strand
		var y1 := 3
		if x % 8 >= 4:
			y1 = 4
		_px(img, x, y1, wire)
		# Lower strand
		var y2 := 4
		if x % 8 >= 4:
			y2 = 3
		_px(img, x, y2, wire_dark)

	# Twist points — where strands cross
	for tx in [3, 11, 19, 27]:
		_px(img, tx, 3, wire)
		_px(img, tx, 4, wire)

	# Barb points at regular intervals — sticking up and down
	for bx in [4, 12, 20, 28]:
		# Barb up-left
		_px(img, bx - 1, 2, wire)
		_px(img, bx - 2, 1, wire)
		# Barb up-right
		_px(img, bx, 2, wire)
		_px(img, bx + 1, 1, wire_dark)
		# Barb down-left
		_px(img, bx - 1, 5, wire)
		_px(img, bx - 2, 6, wire_dark)
		# Barb down-right
		_px(img, bx, 5, wire_dark)
		_px(img, bx + 1, 6, wire)

	# Rust highlights on barbs and wire
	_px(img, 4, 2, rust); _px(img, 5, 1, rust_dark)
	_px(img, 12, 5, rust); _px(img, 13, 6, rust_dark)
	_px(img, 20, 2, rust); _px(img, 21, 1, rust)
	_px(img, 28, 5, rust_dark); _px(img, 29, 6, rust)
	# Rust patches on wire
	_px(img, 7, 3, rust); _px(img, 8, 4, rust_dark)
	_px(img, 15, 4, rust); _px(img, 23, 3, rust_dark)

	return ImageTexture.create_from_image(img)

# ─── Retro TV Set (16x16) — CRT television projectile ───

static func generate_tv_set() -> ImageTexture:
	var s := 16
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var body := _md(0.5, 0.45, 0.35)
	var body_light := _md(0.65, 0.6, 0.5)
	var body_dark := _md(0.35, 0.3, 0.22)
	var wood := _md(0.55, 0.35, 0.18)
	var wood_dark := _md(0.4, 0.25, 0.1)
	var screen_bg := _md(0.1, 0.1, 0.12)
	var screen_glow := _md(0.15, 0.2, 0.25)
	var static_bright := _md(1.0, 1.0, 1.0)
	var static_mid := _md(0.6, 0.65, 0.7)
	var static_dim := _md(0.3, 0.35, 0.4)
	var antenna := _md(0.55, 0.55, 0.6)
	var knob := _md(0.3, 0.3, 0.35)
	var outline := _md(0.15, 0.12, 0.1)

	# ═══ ANTENNA — V-shape on top ═══
	# Left antenna
	_px(img, 5, 0, antenna); _px(img, 6, 1, antenna); _px(img, 7, 2, antenna)
	# Right antenna
	_px(img, 10, 0, antenna); _px(img, 9, 1, antenna); _px(img, 8, 2, antenna)
	# Antenna base
	_px(img, 7, 3, antenna); _px(img, 8, 3, antenna)

	# ═══ TV BODY — boxy shape ═══
	_px_rect(img, 2, 4, 13, 13, body)
	# Top edge highlight
	_px_rect(img, 2, 4, 13, 4, body_light)
	# Left edge highlight
	for y in range(4, 14):
		_px(img, 2, y, body_light)
	# Right/bottom shadow
	_px_rect(img, 13, 5, 13, 13, body_dark)
	_px_rect(img, 3, 13, 13, 13, body_dark)

	# ═══ WOOD-GRAIN SIDES ═══
	_px_rect(img, 2, 5, 3, 12, wood)
	_px(img, 2, 7, wood_dark); _px(img, 2, 10, wood_dark)
	_px(img, 3, 6, wood_dark); _px(img, 3, 9, wood_dark)
	_px_rect(img, 12, 5, 13, 12, wood)
	_px(img, 12, 7, wood_dark); _px(img, 12, 10, wood_dark)
	_px(img, 13, 8, wood_dark); _px(img, 13, 11, wood_dark)

	# ═══ SCREEN — recessed with static ═══
	_px_rect(img, 4, 5, 11, 11, screen_bg)
	# Screen edge glow
	_px_rect(img, 4, 5, 11, 5, screen_glow)
	_px(img, 4, 6, screen_glow); _px(img, 4, 7, screen_glow)

	# Static noise pixels on screen
	_px(img, 5, 6, static_bright); _px(img, 8, 7, static_bright)
	_px(img, 10, 9, static_bright); _px(img, 6, 10, static_bright)
	_px(img, 7, 6, static_mid); _px(img, 9, 8, static_mid)
	_px(img, 5, 9, static_mid); _px(img, 10, 7, static_mid)
	_px(img, 6, 8, static_dim); _px(img, 8, 10, static_dim)
	_px(img, 9, 6, static_dim); _px(img, 5, 8, static_dim)
	_px(img, 11, 10, static_bright); _px(img, 7, 9, static_mid)

	# ═══ CONTROL KNOBS on right side ═══
	_px(img, 12, 6, knob)
	_px(img, 12, 9, knob)

	# ═══ FEET ═══
	_px(img, 4, 14, body_dark); _px(img, 5, 14, body_dark)
	_px(img, 10, 14, body_dark); _px(img, 11, 14, body_dark)

	# ═══ OUTLINE ═══
	_auto_outline(img, s, outline)

	return ImageTexture.create_from_image(img)
