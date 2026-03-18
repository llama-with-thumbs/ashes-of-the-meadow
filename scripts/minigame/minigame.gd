extends Node2D

## 80s Arcade Mini-Game — Sheep dodges asteroids flying right-to-left

const ProceduralSprites = preload("res://scripts/world/procedural_sprites.gd")

# Game state
var score: int = 0
var high_score: int = 0
var game_over: bool = false
var game_started: bool = false
var speed_multiplier: float = 1.0
var difficulty_timer: float = 0.0
var spawn_timer: float = 0.0
var spawn_interval: float = 0.8
var _sheep_sprites: Dictionary = {}

# Player
var sheep_pos: Vector2 = Vector2(120, 360)
var sheep_speed: float = 300.0
var sheep_hitbox_radius: float = 14.0

# Asteroids
var asteroids: Array = []
var asteroid_base_speed: float = 250.0

# Stars (parallax background)
var stars: Array = []

# Screen bounds
var screen_w: float = 1280.0
var screen_h: float = 720.0

# Nodes
var sheep_sprite: Sprite2D
var score_label: Label
var title_label: Label
var gameover_label: Label
var scanline_rect: ColorRect

# Audio
var synth_player: AudioStreamPlayer
var bass_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var _synth_time: float = 0.0
var _bass_time: float = 0.0
var _sfx_time: float = 0.0
var _sfx_playing: bool = false
var _sfx_type: String = ""
var _beat_count: int = 0
var _beat_timer: float = 0.0
var _beat_interval: float = 0.4  # 150 BPM

# Near-miss tracking
var _near_miss_cooldown: float = 0.0

func _ready() -> void:
	# Load sheep sprites
	var front_tex = load("res://assets/sprites/sheep_front.png")
	if front_tex:
		_sheep_sprites = {
			"front": front_tex,
			"side_right": load("res://assets/sprites/sheep_side_right.png"),
			"front_right": load("res://assets/sprites/sheep_front_right.png"),
			"back_right": load("res://assets/sprites/sheep_back_right.png"),
			"back": load("res://assets/sprites/sheep_back.png"),
		}

	_build_ui()
	_build_stars()
	_setup_audio()
	_show_title()

func _build_ui() -> void:
	# Scanline overlay for CRT effect
	scanline_rect = ColorRect.new()
	scanline_rect.z_index = 100
	scanline_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scanline_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	scanline_rect.offset_left = 0
	scanline_rect.offset_top = 0
	scanline_rect.offset_right = screen_w
	scanline_rect.offset_bottom = screen_h
	scanline_rect.color = Color(0, 0, 0, 0)  # Drawn in _draw instead

	# Sheep sprite
	sheep_sprite = Sprite2D.new()
	sheep_sprite.scale = Vector2(0.5, 0.5)
	sheep_sprite.z_index = 10
	add_child(sheep_sprite)

	# Score label — top-right, 80s arcade font style
	score_label = Label.new()
	score_label.z_index = 50
	score_label.anchor_left = 1.0
	score_label.anchor_right = 1.0
	score_label.offset_left = -250
	score_label.offset_right = -20
	score_label.offset_top = 15
	score_label.offset_bottom = 50
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8))
	score_label.text = "SCORE: 0"
	add_child(score_label)

	# Title label — center
	title_label = Label.new()
	title_label.z_index = 50
	title_label.anchor_left = 0.5
	title_label.anchor_right = 0.5
	title_label.anchor_top = 0.5
	title_label.anchor_bottom = 0.5
	title_label.offset_left = -400
	title_label.offset_right = 400
	title_label.offset_top = -120
	title_label.offset_bottom = 120
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	add_child(title_label)

	# Game over label
	gameover_label = Label.new()
	gameover_label.z_index = 50
	gameover_label.anchor_left = 0.5
	gameover_label.anchor_right = 0.5
	gameover_label.anchor_top = 0.5
	gameover_label.anchor_bottom = 0.5
	gameover_label.offset_left = -300
	gameover_label.offset_right = 300
	gameover_label.offset_top = -80
	gameover_label.offset_bottom = 80
	gameover_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gameover_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gameover_label.add_theme_font_size_override("font_size", 36)
	gameover_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.3))
	gameover_label.visible = false
	add_child(gameover_label)

func _build_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	for i in 120:
		var star := {
			"pos": Vector2(rng.randf() * screen_w, rng.randf() * screen_h),
			"speed": rng.randf_range(20.0, 80.0),
			"size": rng.randf_range(0.5, 2.0),
			"brightness": rng.randf_range(0.3, 1.0),
		}
		stars.append(star)

func _setup_audio() -> void:
	# 80s synth melody
	synth_player = AudioStreamPlayer.new()
	var synth_gen := AudioStreamGenerator.new()
	synth_gen.mix_rate = 22050.0
	synth_gen.buffer_length = 1.0
	synth_player.stream = synth_gen
	synth_player.volume_db = -6.0
	synth_player.bus = &"Master"
	add_child(synth_player)
	synth_player.play()

	# Bass line
	bass_player = AudioStreamPlayer.new()
	var bass_gen := AudioStreamGenerator.new()
	bass_gen.mix_rate = 22050.0
	bass_gen.buffer_length = 1.0
	bass_player.stream = bass_gen
	bass_player.volume_db = -2.0
	bass_player.bus = &"Master"
	add_child(bass_player)
	bass_player.play()

	# SFX
	sfx_player = AudioStreamPlayer.new()
	var sfx_gen := AudioStreamGenerator.new()
	sfx_gen.mix_rate = 22050.0
	sfx_gen.buffer_length = 0.5
	sfx_player.stream = sfx_gen
	sfx_player.volume_db = 0.0
	sfx_player.bus = &"Master"
	add_child(sfx_player)
	sfx_player.play()

func _show_title() -> void:
	title_label.text = "SPACE  SHEEP\n\n\nDodge the asteroids!\n\nW / S  or  UP / DOWN  to move\n\n\nPress SPACE to start"
	title_label.visible = true
	score_label.visible = false
	sheep_sprite.visible = false

func _start_game() -> void:
	score = 0
	speed_multiplier = 1.0
	difficulty_timer = 0.0
	spawn_timer = 0.0
	spawn_interval = 0.8
	game_over = false
	game_started = true
	sheep_pos = Vector2(120, screen_h / 2.0)
	_beat_count = 0
	_beat_timer = 0.0

	# Clear asteroids
	for a in asteroids:
		if a.sprite and is_instance_valid(a.sprite):
			a.sprite.queue_free()
	asteroids.clear()

	title_label.visible = false
	gameover_label.visible = false
	score_label.visible = true
	score_label.text = "SCORE: 0"
	sheep_sprite.visible = true

func _trigger_game_over() -> void:
	game_over = true
	game_started = false
	if score > high_score:
		high_score = score
	gameover_label.text = "GAME OVER\n\nSCORE: %d\nHIGH SCORE: %d\n\nPress SPACE to retry" % [score, high_score]
	gameover_label.visible = true
	_play_sfx("gameover")
	# Flash sheep red
	sheep_sprite.modulate = Color(1.0, 0.3, 0.3)

func _play_sfx(type: String) -> void:
	_sfx_playing = true
	_sfx_type = type
	_sfx_time = 0.0

func _process(delta: float) -> void:
	_fill_synth_buffer()
	_fill_bass_buffer()
	_fill_sfx_buffer()

	if not game_started:
		# Scroll stars even on title
		for star in stars:
			star.pos.x -= star.speed * delta * 0.5
			if star.pos.x < 0:
				star.pos.x += screen_w
		queue_redraw()
		return

	# Beat timer for music
	_beat_timer += delta
	if _beat_timer >= _beat_interval:
		_beat_timer -= _beat_interval
		_beat_count += 1

	# Difficulty ramp
	difficulty_timer += delta
	speed_multiplier = 1.0 + difficulty_timer * 0.03
	spawn_interval = maxf(0.25, 0.8 - difficulty_timer * 0.01)

	# Player movement
	var move_dir := 0.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		move_dir -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		move_dir += 1.0
	sheep_pos.y += move_dir * sheep_speed * delta
	sheep_pos.y = clampf(sheep_pos.y, 30.0, screen_h - 30.0)
	sheep_sprite.position = sheep_pos

	# Update sheep sprite direction
	if _sheep_sprites.size() > 0:
		if move_dir < -0.1:
			if _sheep_sprites.has("back_right"):
				sheep_sprite.texture = _sheep_sprites["back_right"]
		elif move_dir > 0.1:
			if _sheep_sprites.has("front_right"):
				sheep_sprite.texture = _sheep_sprites["front_right"]
		else:
			if _sheep_sprites.has("side_right"):
				sheep_sprite.texture = _sheep_sprites["side_right"]

	# Spawn asteroids
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer -= spawn_interval
		_spawn_asteroid()

	# Near-miss cooldown
	if _near_miss_cooldown > 0:
		_near_miss_cooldown -= delta

	# Update asteroids
	var to_remove: Array[int] = []
	for i in asteroids.size():
		var a = asteroids[i]
		a.pos.x -= a.speed * speed_multiplier * delta
		if a.sprite and is_instance_valid(a.sprite):
			a.sprite.position = a.pos
			a.sprite.rotation += a.rot_speed * delta

		# Off screen left
		if a.pos.x < -80:
			to_remove.append(i)
			continue

		# Collision check
		var dist := sheep_pos.distance_to(a.pos)
		if dist < sheep_hitbox_radius + a.radius:
			_trigger_game_over()
			return

		# Near miss bonus
		if dist < sheep_hitbox_radius + a.radius + 20.0 and a.pos.x < sheep_pos.x and _near_miss_cooldown <= 0:
			score += 5
			_near_miss_cooldown = 0.3
			_play_sfx("nearmiss")

	# Remove off-screen (reverse order)
	for i in range(to_remove.size() - 1, -1, -1):
		var idx = to_remove[i]
		if asteroids[idx].sprite and is_instance_valid(asteroids[idx].sprite):
			asteroids[idx].sprite.queue_free()
		asteroids.remove_at(idx)

	# Score ticks up
	score += 1

	# Update stars
	for star in stars:
		star.pos.x -= star.speed * speed_multiplier * delta
		if star.pos.x < 0:
			star.pos.x += screen_w
			star.pos.y = randf() * screen_h

	score_label.text = "SCORE: %d" % score
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			if not game_started:
				_start_game()
		if event.keycode == KEY_ESCAPE:
			# Return to main game
			get_tree().change_scene_to_file("res://scenes/main.tscn")

func _spawn_asteroid() -> void:
	var rng_y := randf_range(30.0, screen_h - 30.0)
	var size_roll := randf()
	var pixel_size: int
	var radius: float
	var spd: float

	if size_roll < 0.5:
		pixel_size = randi_range(20, 28)
		radius = 10.0
		spd = asteroid_base_speed * randf_range(0.9, 1.3)
	elif size_roll < 0.85:
		pixel_size = randi_range(36, 48)
		radius = 18.0
		spd = asteroid_base_speed * randf_range(0.7, 1.1)
	else:
		pixel_size = randi_range(56, 72)
		radius = 28.0
		spd = asteroid_base_speed * randf_range(0.5, 0.9)

	var sprite := Sprite2D.new()
	sprite.texture = ProceduralSprites.generate_asteroid(pixel_size, randf() * 1000.0)
	sprite.z_index = 5
	sprite.modulate = Color(1.0, randf_range(0.7, 1.0), randf_range(0.6, 1.0))
	add_child(sprite)

	var a := {
		"pos": Vector2(screen_w + 60, rng_y),
		"speed": spd,
		"radius": radius,
		"rot_speed": randf_range(-2.0, 2.0),
		"sprite": sprite,
	}
	sprite.position = a.pos
	asteroids.append(a)

func _draw() -> void:
	# Dark space background
	draw_rect(Rect2(0, 0, screen_w, screen_h), Color(0.01, 0.01, 0.04))

	# Stars
	for star in stars:
		var col := Color(0.7, 0.8, 1.0, star.brightness)
		draw_circle(star.pos, star.size, col)

	# CRT scanlines
	for y in range(0, int(screen_h), 3):
		draw_line(Vector2(0, y), Vector2(screen_w, y), Color(0, 0, 0, 0.08))

	# Bottom HUD bar — 80s neon style
	draw_rect(Rect2(0, screen_h - 4, screen_w, 4), Color(0.0, 1.0, 0.8, 0.3))
	draw_rect(Rect2(0, 0, screen_w, 2), Color(1.0, 0.2, 0.8, 0.2))

	# Speed indicator — left bar
	if game_started:
		var bar_h := clampf(speed_multiplier / 4.0, 0.0, 1.0) * (screen_h - 80)
		draw_rect(Rect2(5, screen_h - 40 - bar_h, 6, bar_h), Color(1.0, 0.3, 0.5, 0.5))

# --- 80s Synth Music (procedural) ---

# Pentatonic melody notes in Hz — dreamy 80s arpeggios
var _melody_notes: Array[float] = [
	329.63, 392.0, 440.0, 523.25, 587.33,  # E4 G4 A4 C5 D5
	659.25, 587.33, 523.25, 440.0, 392.0,   # E5 D5 C5 A4 G4
	349.23, 440.0, 523.25, 659.25, 783.99,  # F4 A4 C5 E5 G5
	659.25, 523.25, 440.0, 349.23, 329.63,  # E5 C5 A4 F4 E4
]

# Bass notes — root progression
var _bass_notes: Array[float] = [
	82.41, 82.41, 110.0, 110.0,  # E2 E2 A2 A2
	87.31, 87.31, 98.0, 98.0,    # F2 F2 G2 G2
]

func _fill_synth_buffer() -> void:
	if not synth_player.playing:
		return
	var playback := synth_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frames := playback.get_frames_available()
	if frames <= 0:
		return

	var sr := 22050.0
	var note_idx := (_beat_count) % _melody_notes.size()
	var freq := _melody_notes[note_idx]

	for i in frames:
		var t := _synth_time
		# Saw wave with filter — classic 80s synth lead
		var saw := fmod(t * freq, 1.0) * 2.0 - 1.0
		# Simple low-pass: blend with sine
		var sine := sin(TAU * freq * t)
		var value := saw * 0.3 + sine * 0.4

		# Tremolo — wobbly 80s vibrato
		value *= 0.5 + sin(TAU * 5.5 * t) * 0.15

		# Beat envelope — note attack/decay
		var beat_pos := fmod(_synth_time, _beat_interval)
		var env := clampf(1.0 - beat_pos / (_beat_interval * 0.8), 0.0, 1.0)
		env = env * env
		value *= env * 0.35

		# Chorus/detune — thicken the sound
		value += sin(TAU * freq * 1.005 * t) * 0.1 * env

		if game_over or not game_started:
			value *= 0.15

		_synth_time += 1.0 / sr
		playback.push_frame(Vector2(value, value))

func _fill_bass_buffer() -> void:
	if not bass_player.playing:
		return
	var playback := bass_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frames := playback.get_frames_available()
	if frames <= 0:
		return

	var sr := 22050.0
	var bass_idx := (_beat_count / 2) % _bass_notes.size()
	var freq := _bass_notes[bass_idx]

	for i in frames:
		var t := _bass_time
		# Thick sub bass — sine + octave
		var value := sin(TAU * freq * t) * 0.5
		value += sin(TAU * freq * 2.0 * t) * 0.2
		# Pumping sidechain-style envelope
		var beat_pos := fmod(_bass_time, _beat_interval * 2.0)
		var pump := clampf(beat_pos / (_beat_interval * 0.5), 0.0, 1.0)
		value *= pump * 0.5

		if game_over or not game_started:
			value *= 0.15

		_bass_time += 1.0 / sr
		playback.push_frame(Vector2(value, value))

func _fill_sfx_buffer() -> void:
	if not sfx_player.playing:
		return
	var playback := sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frames := playback.get_frames_available()
	if frames <= 0:
		return

	var sr := 22050.0

	for i in frames:
		var value := 0.0
		if _sfx_playing:
			var t := _sfx_time
			match _sfx_type:
				"nearmiss":
					# Quick ascending bleep
					var freq := 800.0 + t * 3000.0
					var env := clampf(1.0 - t / 0.12, 0.0, 1.0)
					value = sin(TAU * freq * t) * env * 0.4
					if t > 0.12:
						_sfx_playing = false
				"gameover":
					# Descending wah-wah
					var freq := 600.0 - t * 400.0
					var env := clampf(1.0 - t / 1.0, 0.0, 1.0)
					value = sin(TAU * freq * t) * env * 0.5
					value += sin(TAU * freq * 0.5 * t) * env * 0.3
					# Wobble
					value *= 0.7 + sin(TAU * 8.0 * t) * 0.3
					if t > 1.0:
						_sfx_playing = false
			_sfx_time += 1.0 / sr
		playback.push_frame(Vector2(value, value))
