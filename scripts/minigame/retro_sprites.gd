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

# ─── Pixel Sheep (24x24) — side-facing, clearly a sheep ───

static func generate_pixel_sheep() -> ImageTexture:
	var s := 24
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var wool := _md(0.9, 0.6, 1.0)         # Lavender wool
	var wool_light := _md(1.0, 0.8, 1.0)    # Highlight
	var wool_dark := _md(0.7, 0.4, 0.8)     # Shadow
	var face := _md(1.0, 0.5, 0.3)          # Tangerine face
	var face_dark := _md(0.7, 0.3, 0.15)    # Face shadow
	var eye := _md(0.1, 0.15, 0.6)          # Deep indigo eye
	var eye_white := _md(1.0, 1.0, 1.0)
	var ear := _md(0.85, 0.15, 0.4)         # Hot pink ear
	var legs := _md(0.15, 0.85, 0.5)        # Emerald legs
	var outline := _md(0.15, 0.1, 0.2)      # Dark outline

	# Wool body — big fluffy mass (main shape)
	_px_rect(img, 5, 8, 18, 16, wool)
	_px_rect(img, 6, 7, 17, 17, wool)
	_px_rect(img, 7, 6, 16, 18, wool)
	# Wool puffs — bumpy top edge
	_px_rect(img, 7, 5, 9, 6, wool)
	_px_rect(img, 11, 5, 13, 6, wool)
	_px_rect(img, 15, 5, 17, 6, wool)
	# Wool puffs — bumpy bottom
	_px_rect(img, 8, 18, 10, 19, wool)
	_px_rect(img, 13, 18, 15, 19, wool)

	# Wool highlight (top-left)
	_px_rect(img, 7, 7, 10, 9, wool_light)
	_px_rect(img, 8, 6, 9, 7, wool_light)
	# Wool shadow (bottom-right)
	_px_rect(img, 14, 15, 17, 17, wool_dark)
	_px_rect(img, 16, 13, 18, 16, wool_dark)

	# Head/face — poking out right side
	_px_rect(img, 18, 8, 22, 14, face)
	_px_rect(img, 19, 7, 21, 15, face)
	# Face shadow
	_px_rect(img, 19, 13, 22, 14, face_dark)

	# Eye
	_px(img, 20, 9, eye_white)
	_px(img, 21, 9, eye_white)
	_px(img, 21, 10, eye)
	_px(img, 20, 10, eye)

	# Ear — sticking up from head
	_px_rect(img, 20, 5, 21, 7, ear)
	_px(img, 20, 4, ear)

	# Tiny nose/mouth
	_px(img, 22, 12, face_dark)
	_px(img, 22, 11, face_dark)

	# Legs — two pairs
	_px_rect(img, 8, 19, 9, 22, legs)
	_px_rect(img, 14, 19, 15, 22, legs)
	# Hooves
	_px(img, 8, 22, outline)
	_px(img, 9, 22, outline)
	_px(img, 14, 22, outline)
	_px(img, 15, 22, outline)

	# Outline — bottom of body and head
	for x in range(5, 23):
		for y in range(3, 23):
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				# Check if edge pixel
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						if dx == 0 and dy == 0:
							continue
						var nx: int = x + dx
						var ny: int = y + dy
						if nx >= 0 and ny >= 0 and nx < s and ny < s:
							if img.get_pixel(nx, ny).a < 0.1:
								_px(img, nx, ny, outline)

	return ImageTexture.create_from_image(img)

# ─── Pixel Sheep Frame 2 (legs shifted) ───

static func generate_pixel_sheep_frame2() -> ImageTexture:
	var s := 24
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var wool := _md(0.9, 0.6, 1.0)
	var wool_light := _md(1.0, 0.8, 1.0)
	var wool_dark := _md(0.7, 0.4, 0.8)
	var face := _md(1.0, 0.5, 0.3)
	var face_dark := _md(0.7, 0.3, 0.15)
	var eye := _md(0.1, 0.15, 0.6)
	var eye_white := _md(1.0, 1.0, 1.0)
	var ear := _md(0.85, 0.15, 0.4)
	var legs := _md(0.15, 0.85, 0.5)
	var outline := _md(0.15, 0.1, 0.2)

	# Same body as frame 1
	_px_rect(img, 5, 8, 18, 16, wool)
	_px_rect(img, 6, 7, 17, 17, wool)
	_px_rect(img, 7, 6, 16, 18, wool)
	_px_rect(img, 7, 5, 9, 6, wool)
	_px_rect(img, 11, 5, 13, 6, wool)
	_px_rect(img, 15, 5, 17, 6, wool)
	_px_rect(img, 8, 18, 10, 19, wool)
	_px_rect(img, 13, 18, 15, 19, wool)
	_px_rect(img, 7, 7, 10, 9, wool_light)
	_px_rect(img, 8, 6, 9, 7, wool_light)
	_px_rect(img, 14, 15, 17, 17, wool_dark)
	_px_rect(img, 16, 13, 18, 16, wool_dark)
	_px_rect(img, 18, 8, 22, 14, face)
	_px_rect(img, 19, 7, 21, 15, face)
	_px_rect(img, 19, 13, 22, 14, face_dark)
	_px(img, 20, 9, eye_white)
	_px(img, 21, 9, eye_white)
	_px(img, 21, 10, eye)
	_px(img, 20, 10, eye)
	_px_rect(img, 20, 5, 21, 7, ear)
	_px(img, 20, 4, ear)
	_px(img, 22, 12, face_dark)
	_px(img, 22, 11, face_dark)

	# Legs — shifted positions for run cycle
	_px_rect(img, 7, 19, 8, 22, legs)
	_px_rect(img, 10, 19, 11, 21, legs)
	_px_rect(img, 13, 19, 14, 21, legs)
	_px_rect(img, 16, 19, 17, 22, legs)
	_px(img, 7, 22, outline)
	_px(img, 8, 22, outline)
	_px(img, 16, 22, outline)
	_px(img, 17, 22, outline)

	# Outline
	for x in range(5, 23):
		for y in range(3, 23):
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						if dx == 0 and dy == 0:
							continue
						var nx: int = x + dx
						var ny: int = y + dy
						if nx >= 0 and ny >= 0 and nx < s and ny < s:
							if img.get_pixel(nx, ny).a < 0.1:
								_px(img, nx, ny, outline)

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
