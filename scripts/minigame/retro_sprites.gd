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

# ─── Pixel Sheep (40x40) — Children's book lamb ───
# Wavy woolly edges, small curved horns, floppy ear, round spiral eyes,
# thin stick legs — like a classic storybook illustration.

static func _draw_sheep_body(img: Image, leg_frame: int) -> void:
	var s := 40

	# Storybook palette — bright white wool, dark outlines, warm accents
	var wool := _md(0.95, 0.92, 0.88)          # Off-white wool
	var wool_light := _md(1.0, 1.0, 0.98)      # Bright highlight
	var wool_mid := _md(0.88, 0.84, 0.78)      # Mid tone
	var wool_shadow := _md(0.78, 0.72, 0.65)   # Shadow
	var face := _md(0.95, 0.88, 0.82)          # Warm cream face
	var face_light := _md(1.0, 0.95, 0.9)      # Highlight
	var eye := _md(0.12, 0.1, 0.12)            # Dark — simple dots
	var eye_shine := _md(1.0, 1.0, 1.0)        # Sparkle
	var nose := _md(0.3, 0.25, 0.22)           # Dark nose
	var ear_dark := _md(0.3, 0.28, 0.25)       # Dark floppy ear
	var ear_inner := _md(0.55, 0.45, 0.4)      # Inner ear
	var horn := _md(0.3, 0.28, 0.25)           # Dark curved horns
	var legs := _md(0.82, 0.75, 0.65)          # Warm legs
	var legs_dark := _md(0.65, 0.55, 0.45)     # Leg shadow
	var hooves := _md(0.45, 0.35, 0.28)        # Hooves
	var outline := _md(0.2, 0.18, 0.15)        # Dark outline (storybook ink)

	# ── Woolly body — wavy bumpy edges like the reference ──
	# Main body mass (slightly wider, left of center for head room)
	_px_circle(img, 14, 18, 10, wool)
	_px_circle(img, 11, 16, 8, wool)
	_px_circle(img, 18, 16, 8, wool)
	_px_circle(img, 14, 14, 7, wool)

	# Wavy top edge — bumpy cloud-like silhouette
	_px_circle(img, 8, 11, 4, wool)
	_px_circle(img, 13, 9, 4, wool)
	_px_circle(img, 18, 10, 4, wool)
	_px_circle(img, 22, 12, 3, wool)
	_px_circle(img, 10, 9, 3, wool)
	_px_circle(img, 16, 8, 3, wool)

	# Wavy side edges
	_px_circle(img, 5, 15, 4, wool)
	_px_circle(img, 5, 19, 3, wool)
	_px_circle(img, 23, 15, 4, wool)
	_px_circle(img, 24, 19, 3, wool)

	# Wavy bottom edge
	_px_circle(img, 8, 24, 3, wool)
	_px_circle(img, 13, 25, 3, wool)
	_px_circle(img, 18, 24, 3, wool)
	_px_circle(img, 22, 23, 3, wool)

	# ── Wool shading — top-left highlight, bottom shadow ──
	_px_circle(img, 10, 11, 3, wool_light)
	_px_circle(img, 14, 9, 2, wool_light)
	_px_circle(img, 7, 15, 3, wool_light)
	_px_circle(img, 17, 19, 4, wool_mid)
	_px_circle(img, 20, 22, 3, wool_shadow)
	_px_circle(img, 14, 24, 3, wool_shadow)
	# Fluff detail dots
	_px(img, 9, 10, wool_light); _px(img, 15, 8, wool_light)
	_px(img, 6, 14, wool_light); _px(img, 20, 11, wool_mid)
	_px(img, 12, 22, wool_mid); _px(img, 21, 17, wool_shadow)

	# ── Head/face — right side, round ──
	_px_circle(img, 30, 15, 7, face)
	_px_circle(img, 31, 14, 6, face)
	_px_circle(img, 29, 13, 4, face_light)

	# Wool overlapping onto head
	_px_circle(img, 25, 13, 4, wool)
	_px_circle(img, 25, 17, 3, wool)
	_px_circle(img, 26, 10, 3, wool)

	# ── Curved horns — small, dark, curving outward ──
	# Right horn (C-curve going up-right)
	_px(img, 29, 7, horn); _px(img, 30, 6, horn); _px(img, 31, 5, horn)
	_px(img, 32, 5, horn); _px(img, 33, 6, horn); _px(img, 33, 7, horn)
	# Left horn (peeking behind, shorter)
	_px(img, 27, 7, horn); _px(img, 26, 6, horn); _px(img, 25, 6, horn)
	_px(img, 25, 7, horn)

	# ── Floppy ear — dark, drooping to the left ──
	_px_rect(img, 26, 13, 27, 19, ear_dark)
	_px(img, 25, 14, ear_dark); _px(img, 25, 15, ear_dark)
	_px(img, 25, 16, ear_dark); _px(img, 25, 17, ear_dark)
	_px(img, 28, 14, ear_dark); _px(img, 28, 15, ear_dark)
	# Ear inner detail
	_px(img, 27, 15, ear_inner); _px(img, 27, 16, ear_inner)
	_px(img, 26, 16, ear_inner)

	# ── Eyes — round, with spiral hint (like the reference) ──
	# Main eye
	_px(img, 32, 12, eye); _px(img, 33, 12, eye)
	_px(img, 32, 13, eye); _px(img, 33, 13, eye)
	_px(img, 34, 12, eye); _px(img, 34, 13, eye)
	# Spiral hint (small inner mark)
	_px(img, 33, 12, eye_shine)
	_px(img, 32, 13, _md(0.25, 0.22, 0.2))

	# ── Snout/nose — small, dark ──
	_px_circle(img, 36, 16, 2, face)
	_px(img, 37, 16, nose); _px(img, 37, 15, nose)
	# Little mouth line
	_px(img, 36, 18, nose); _px(img, 35, 19, _md(0.4, 0.35, 0.3))

	# ── Legs — thin stick legs, like the illustration ──
	if leg_frame == 0:
		# Frame 1: standing / walking
		_px_rect(img, 8, 26, 9, 34, legs)
		_px_rect(img, 13, 26, 14, 34, legs)
		_px_rect(img, 18, 26, 19, 33, legs)
		_px_rect(img, 22, 24, 23, 33, legs)
		# Shadow side
		_px_rect(img, 9, 28, 9, 34, legs_dark)
		_px_rect(img, 14, 28, 14, 34, legs_dark)
		_px_rect(img, 19, 28, 19, 33, legs_dark)
		_px_rect(img, 23, 26, 23, 33, legs_dark)
		# Hooves
		_px_rect(img, 8, 34, 10, 35, hooves)
		_px_rect(img, 13, 34, 15, 35, hooves)
		_px_rect(img, 18, 33, 20, 34, hooves)
		_px_rect(img, 22, 33, 24, 34, hooves)
	else:
		# Frame 2: trotting — legs spread
		_px_rect(img, 7, 26, 8, 33, legs)
		_px_rect(img, 14, 26, 15, 35, legs)
		_px_rect(img, 17, 26, 18, 32, legs)
		_px_rect(img, 23, 24, 24, 35, legs)
		_px_rect(img, 8, 28, 8, 33, legs_dark)
		_px_rect(img, 15, 28, 15, 35, legs_dark)
		_px_rect(img, 18, 28, 18, 32, legs_dark)
		_px_rect(img, 24, 26, 24, 35, legs_dark)
		_px_rect(img, 7, 33, 9, 34, hooves)
		_px_rect(img, 14, 35, 16, 36, hooves)
		_px_rect(img, 17, 32, 19, 33, hooves)
		_px_rect(img, 23, 35, 25, 36, hooves)

	# ── Tail — woolly puff on the left, slightly wavy ──
	_px_circle(img, 4, 17, 3, wool)
	_px_circle(img, 3, 16, 2, wool_light)
	_px_circle(img, 4, 19, 2, wool_mid)
	_px(img, 2, 16, wool_light)

	# ── Auto-outline — dark ink-like, storybook feel ──
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

static func generate_pixel_sheep() -> ImageTexture:
	var s := 40
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_sheep_body(img, 0)
	return ImageTexture.create_from_image(img)

# ─── Pixel Sheep Frame 2 (walking stride) ───

static func generate_pixel_sheep_frame2() -> ImageTexture:
	var s := 40
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_sheep_body(img, 1)
	return ImageTexture.create_from_image(img)

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
