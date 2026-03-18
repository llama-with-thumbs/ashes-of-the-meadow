extends Node2D

## MEGA SHEEP — 16-bit Mega Drive style side-scrolling space arcade
## A melancholic retro minigame about a sheep drifting through ruins,
## dodging meteors and collecting fragments of a broken world.

const RetroSprites = preload("res://scripts/minigame/retro_sprites.gd")

# ─── State Machine ───

enum State { TITLE, PLAYING, GAMEOVER, RESULTS }
var state: State = State.TITLE

# ─── Screen ───

const W: float = 1280.0
const H: float = 720.0

# ─── Player ───

var sheep_pos: Vector2 = Vector2(140, 360)
var sheep_speed: float = 280.0
var sheep_hitbox: float = 10.0
var sheep_frames: Array[ImageTexture] = []
var sheep_frame_idx: int = 0
var sheep_anim_timer: float = 0.0
var lives: int = 3
const MAX_LIVES: int = 3
var invincible: float = 0.0  # Seconds of i-frames remaining
var blink_timer: float = 0.0

# ─── Meteors ───

var meteors: Array = []
var meteor_timer: float = 0.0
var meteor_interval: float = 0.9

# ─── Collectibles ───

var collectibles: Array = []
var collect_timer: float = 0.0
var collect_interval: float = 2.0
var collected_tally: Dictionary = {}

const COLLECT_TYPES: Array[Dictionary] = [
	{"type": "salvage", "weight": 25, "score": 10},
	{"type": "wool", "weight": 20, "score": 10},
	{"type": "debris", "weight": 20, "score": 15},
	{"type": "cassette", "weight": 15, "score": 25},
	{"type": "headphones", "weight": 10, "score": 30},
	{"type": "music_note", "weight": 10, "score": 50},
]

# ─── Scoring & Difficulty ───

var score: int = 0
var high_score: int = 0
var distance: float = 0.0
var speed_mult: float = 1.0
var play_time: float = 0.0
var near_miss_cd: float = 0.0

# ─── Parallax Stars ───

var star_layers: Array = []  # [{stars: [{pos, size, bright}], speed}]

# ─── UI Nodes ───

var sheep_sprite: Sprite2D
var heart_sprites: Array[Sprite2D] = []
var heart_full_tex: ImageTexture
var heart_empty_tex: ImageTexture
var score_label: Label
var dist_label: Label
var title_label: Label
var results_label: Label
var item_sprites: Dictionary = {}  # type -> ImageTexture cache

# ─── Audio ───

var fm_player: AudioStreamPlayer
var bass_player: AudioStreamPlayer
var drum_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var _fm_time: float = 0.0
var _bass_time: float = 0.0
var _drum_time: float = 0.0
var _sfx_time: float = 0.0
var _sfx_playing: bool = false
var _sfx_type: String = ""

var _beat_count: int = 0
var _beat_timer: float = 0.0
const BEAT_INTERVAL: float = 0.46  # ~130 BPM

# ─── Lifecycle ───

func _ready() -> void:
	# Generate sprites
	sheep_frames = [RetroSprites.generate_pixel_sheep(), RetroSprites.generate_pixel_sheep_frame2()]
	heart_full_tex = RetroSprites.generate_heart()
	heart_empty_tex = RetroSprites.generate_heart_empty()
	for ct in COLLECT_TYPES:
		item_sprites[ct.type] = RetroSprites.generate_mini_collectible(ct.type)

	_build_stars()
	_build_hud()
	_setup_audio()
	_show_title()

func _build_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9999
	for layer_idx in 3:
		var layer := {"stars": [], "speed": (layer_idx + 1) * 25.0}
		var count := 30 + layer_idx * 20
		for i in count:
			layer.stars.append({
				"pos": Vector2(rng.randf() * W, rng.randf() * H),
				"size": 0.5 + layer_idx * 0.5 + rng.randf() * 0.5,
				"bright": 0.15 + layer_idx * 0.2 + rng.randf() * 0.2,
				"color_r": rng.randf_range(0.6, 1.0),
				"color_b": rng.randf_range(0.7, 1.0),
			})
		star_layers.append(layer)

func _build_hud() -> void:
	# Sheep sprite
	sheep_sprite = Sprite2D.new()
	sheep_sprite.texture = sheep_frames[0]
	sheep_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sheep_sprite.scale = Vector2(3.0, 3.0)
	sheep_sprite.z_index = 20
	add_child(sheep_sprite)

	# Hearts
	for i in MAX_LIVES:
		var h := Sprite2D.new()
		h.texture = heart_full_tex
		h.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		h.scale = Vector2(3.0, 3.0)
		h.position = Vector2(30 + i * 30, 30)
		h.z_index = 50
		add_child(h)
		heart_sprites.append(h)

	# Score label
	score_label = Label.new()
	score_label.z_index = 50
	score_label.anchor_left = 1.0
	score_label.anchor_right = 1.0
	score_label.offset_left = -280
	score_label.offset_right = -20
	score_label.offset_top = 10
	score_label.offset_bottom = 40
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8))
	add_child(score_label)

	# Distance label
	dist_label = Label.new()
	dist_label.z_index = 50
	dist_label.anchor_left = 1.0
	dist_label.anchor_right = 1.0
	dist_label.offset_left = -280
	dist_label.offset_right = -20
	dist_label.offset_top = 38
	dist_label.offset_bottom = 60
	dist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dist_label.add_theme_font_size_override("font_size", 16)
	dist_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.8))
	add_child(dist_label)

	# Title label
	title_label = Label.new()
	title_label.z_index = 50
	title_label.anchor_left = 0.5
	title_label.anchor_right = 0.5
	title_label.anchor_top = 0.5
	title_label.anchor_bottom = 0.5
	title_label.offset_left = -420
	title_label.offset_right = 420
	title_label.offset_top = -160
	title_label.offset_bottom = 160
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	add_child(title_label)

	# Results label
	results_label = Label.new()
	results_label.z_index = 50
	results_label.anchor_left = 0.5
	results_label.anchor_right = 0.5
	results_label.anchor_top = 0.5
	results_label.anchor_bottom = 0.5
	results_label.offset_left = -350
	results_label.offset_right = 350
	results_label.offset_top = -180
	results_label.offset_bottom = 180
	results_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	results_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	results_label.add_theme_font_size_override("font_size", 18)
	results_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	results_label.visible = false
	add_child(results_label)

func _setup_audio() -> void:
	fm_player = _make_audio_player(-6.0)
	bass_player = _make_audio_player(-2.0)
	drum_player = _make_audio_player(-4.0)
	sfx_player = _make_audio_player(0.0, 0.5)

func _make_audio_player(vol: float, buf: float = 1.0) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	var g := AudioStreamGenerator.new()
	g.mix_rate = 22050.0
	g.buffer_length = buf
	p.stream = g
	p.volume_db = vol
	p.bus = &"Master"
	add_child(p)
	p.play()
	return p

# ─── Game Flow ───

func _show_title() -> void:
	state = State.TITLE
	title_label.text = "M E G A   S H E E P\n\n\nDrift through the ruins. Collect what remains.\nDodge the meteors. Survive.\n\n\nW / S  to move       A / D  to drift\n\n\nPress SPACE to launch\nPress ESC to return"
	title_label.visible = true
	results_label.visible = false
	score_label.visible = false
	dist_label.visible = false
	sheep_sprite.visible = false
	for h in heart_sprites:
		h.visible = false

func _start_game() -> void:
	state = State.PLAYING
	score = 0
	distance = 0.0
	speed_mult = 1.0
	play_time = 0.0
	lives = MAX_LIVES
	invincible = 0.0
	meteor_timer = 0.0
	meteor_interval = 0.9
	collect_timer = 0.0
	collect_interval = 2.0
	_beat_count = 0
	_beat_timer = 0.0
	sheep_pos = Vector2(140, H / 2.0)
	collected_tally.clear()

	# Clear entities
	for m in meteors:
		if m.sprite and is_instance_valid(m.sprite):
			m.sprite.queue_free()
	meteors.clear()
	for c in collectibles:
		if c.sprite and is_instance_valid(c.sprite):
			c.sprite.queue_free()
	collectibles.clear()

	title_label.visible = false
	results_label.visible = false
	score_label.visible = true
	dist_label.visible = true
	sheep_sprite.visible = true
	sheep_sprite.modulate = Color.WHITE

	for i in MAX_LIVES:
		heart_sprites[i].texture = heart_full_tex
		heart_sprites[i].visible = true

func _take_damage() -> void:
	if invincible > 0:
		return
	lives -= 1
	invincible = 1.8
	_play_sfx("damage")

	# Update hearts
	for i in MAX_LIVES:
		heart_sprites[i].texture = heart_full_tex if i < lives else heart_empty_tex

	if lives <= 0:
		_game_over()

func _game_over() -> void:
	state = State.GAMEOVER
	sheep_sprite.modulate = Color(1.0, 0.3, 0.3)
	_play_sfx("gameover")
	if score > high_score:
		high_score = score
	# Delay then show results
	get_tree().create_timer(2.0).timeout.connect(_show_results)

func _show_results() -> void:
	state = State.RESULTS

	# Transfer resources to main game
	_transfer_resources()

	var text := "M I S S I O N   R E P O R T\n\n"
	text += "Distance: %dm\n" % int(distance)
	text += "Score: %d\n" % score
	text += "High Score: %d\n\n" % high_score

	if collected_tally.size() > 0:
		for type in collected_tally:
			text += "%s: x%d\n" % [type.capitalize(), collected_tally[type]]
		text += "\nResources transferred to inventory.\n"
	else:
		text += "No items collected.\n"

	text += "\n\nSPACE to retry    ESC to exit"

	results_label.text = text
	results_label.visible = true
	title_label.visible = false

func _transfer_resources() -> void:
	for type in collected_tally:
		var count: int = collected_tally[type]
		match type:
			"cassette":
				GameState.add_item("tape_fragment", count)
			"wool":
				GameState.add_item("wool_fiber", count)
			"salvage":
				GameState.add_item("salvage", count)
			"debris":
				GameState.add_item("salvage", maxi(count / 2, 1))
			"headphones":
				GameState.add_item("tape_fragment", maxi(count / 2, 1))
			"music_note":
				GameState.add_item("stardust", count)

# ─── Input ───

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			if state == State.TITLE or state == State.RESULTS:
				_start_game()
		if event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/main.tscn")

# ─── Main Loop ───

func _process(delta: float) -> void:
	_fill_fm_buffer()
	_fill_bass_buffer()
	_fill_drum_buffer()
	_fill_sfx_buffer()

	# Scroll stars always
	for layer in star_layers:
		var spd: float = layer.speed * (speed_mult if state == State.PLAYING else 0.4)
		for star in layer.stars:
			star.pos.x -= spd * delta
			if star.pos.x < -2:
				star.pos.x += W + 4
				star.pos.y = randf() * H

	if state != State.PLAYING:
		queue_redraw()
		return

	play_time += delta
	_beat_timer += delta
	if _beat_timer >= BEAT_INTERVAL:
		_beat_timer -= BEAT_INTERVAL
		_beat_count += 1

	# Difficulty ramp
	speed_mult = 1.0 + play_time * 0.025
	meteor_interval = maxf(0.2, 0.9 - play_time * 0.008)
	collect_interval = maxf(0.8, 2.0 - play_time * 0.01)

	# Player movement
	var move := Vector2.ZERO
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		move.y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		move.y += 1.0
	if Input.is_key_pressed(KEY_A):
		move.x -= 0.5
	if Input.is_key_pressed(KEY_D):
		move.x += 0.5

	sheep_pos += move * sheep_speed * delta
	sheep_pos.x = clampf(sheep_pos.x, 40.0, W * 0.3)
	sheep_pos.y = clampf(sheep_pos.y, 30.0, H - 30.0)
	sheep_sprite.position = sheep_pos

	# Sheep animation
	sheep_anim_timer += delta
	if sheep_anim_timer > 0.2:
		sheep_anim_timer -= 0.2
		sheep_frame_idx = (sheep_frame_idx + 1) % sheep_frames.size()
		sheep_sprite.texture = sheep_frames[sheep_frame_idx]

	# Invincibility blink
	if invincible > 0:
		invincible -= delta
		blink_timer += delta
		sheep_sprite.visible = int(blink_timer * 10) % 2 == 0
		if invincible <= 0:
			sheep_sprite.visible = true
			sheep_sprite.modulate = Color.WHITE

	# Near-miss cooldown
	if near_miss_cd > 0:
		near_miss_cd -= delta

	# Spawn meteors
	meteor_timer += delta
	if meteor_timer >= meteor_interval:
		meteor_timer -= meteor_interval
		_spawn_meteor()

	# Spawn collectibles
	collect_timer += delta
	if collect_timer >= collect_interval:
		collect_timer -= collect_interval
		_spawn_collectible()

	# Update meteors
	var m_remove: Array[int] = []
	for i in meteors.size():
		var m = meteors[i]
		m.pos.x -= m.speed * speed_mult * delta
		m.rot += m.rot_speed * delta
		if m.sprite and is_instance_valid(m.sprite):
			m.sprite.position = m.pos
			m.sprite.rotation = m.rot

		if m.pos.x < -60:
			m_remove.append(i)
			continue

		# Collision
		var dist_to := sheep_pos.distance_to(m.pos)
		if dist_to < sheep_hitbox + m.radius:
			_take_damage()
			m_remove.append(i)
			continue

		# Near miss
		if dist_to < sheep_hitbox + m.radius + 25.0 and m.pos.x < sheep_pos.x and near_miss_cd <= 0:
			score += 5
			near_miss_cd = 0.4
			_play_sfx("nearmiss")

	for i in range(m_remove.size() - 1, -1, -1):
		var idx = m_remove[i]
		if meteors[idx].sprite and is_instance_valid(meteors[idx].sprite):
			meteors[idx].sprite.queue_free()
		meteors.remove_at(idx)

	# Update collectibles
	var c_remove: Array[int] = []
	for i in collectibles.size():
		var c = collectibles[i]
		c.pos.x -= c.speed * speed_mult * delta
		c.pos.y += sin(play_time * 3.0 + c.bob_offset) * 0.5  # Gentle bob
		if c.sprite and is_instance_valid(c.sprite):
			c.sprite.position = c.pos

		if c.pos.x < -30:
			c_remove.append(i)
			continue

		# Collect on overlap
		if sheep_pos.distance_to(c.pos) < sheep_hitbox + 12.0:
			_collect_item(c.type, c.score_val)
			c_remove.append(i)
			continue

	for i in range(c_remove.size() - 1, -1, -1):
		var idx = c_remove[i]
		if collectibles[idx].sprite and is_instance_valid(collectibles[idx].sprite):
			collectibles[idx].sprite.queue_free()
		collectibles.remove_at(idx)

	# Score & distance
	score += 1
	distance += 60.0 * speed_mult * delta

	score_label.text = "SCORE: %d" % score
	dist_label.text = "%dm" % int(distance)

	queue_redraw()

# ─── Spawning ───

func _spawn_meteor() -> void:
	var y := randf_range(30.0, H - 30.0)
	var roll := randf()
	var pixel_size: int
	var radius: float
	var spd: float

	if roll < 0.5:
		pixel_size = randi_range(10, 14)
		radius = 8.0
		spd = randf_range(200.0, 320.0)
	elif roll < 0.85:
		pixel_size = randi_range(16, 22)
		radius = 14.0
		spd = randf_range(150.0, 260.0)
	else:
		pixel_size = randi_range(24, 32)
		radius = 22.0
		spd = randf_range(100.0, 200.0)

	var spr := Sprite2D.new()
	spr.texture = RetroSprites.generate_meteor(pixel_size, randf() * 999.0)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(2.0, 2.0)
	spr.z_index = 10
	add_child(spr)

	meteors.append({
		"pos": Vector2(W + 60, y),
		"speed": spd,
		"radius": radius,
		"rot": randf() * TAU,
		"rot_speed": randf_range(-2.5, 2.5),
		"sprite": spr,
	})

func _spawn_collectible() -> void:
	# Weighted random type
	var total_weight := 0
	for ct in COLLECT_TYPES:
		total_weight += ct.weight
	var roll := randi() % total_weight
	var chosen: Dictionary = COLLECT_TYPES[0]
	var accum := 0
	for ct in COLLECT_TYPES:
		accum += ct.weight
		if roll < accum:
			chosen = ct
			break

	var y := randf_range(40.0, H - 40.0)
	var spr := Sprite2D.new()
	spr.texture = item_sprites[chosen.type]
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(3.0, 3.0)
	spr.z_index = 15
	add_child(spr)

	collectibles.append({
		"pos": Vector2(W + 30, y),
		"speed": randf_range(120.0, 200.0),
		"type": chosen.type,
		"score_val": chosen.score,
		"bob_offset": randf() * TAU,
		"sprite": spr,
	})

func _collect_item(type: String, score_val: int) -> void:
	score += score_val
	if collected_tally.has(type):
		collected_tally[type] += 1
	else:
		collected_tally[type] = 1
	_play_sfx("collect_" + type)

# ─── Drawing ───

func _draw() -> void:
	# Space background
	draw_rect(Rect2(0, 0, W, H), Color(0.01, 0.01, 0.04))

	# Star layers
	for layer_idx in star_layers.size():
		var layer = star_layers[layer_idx]
		for star in layer.stars:
			var col := Color(star.color_r, 0.7, star.color_b, star.bright)
			if star.size <= 1.0:
				draw_rect(Rect2(star.pos.x, star.pos.y, 1, 1), col)
			else:
				draw_rect(Rect2(star.pos.x, star.pos.y, star.size, star.size), col)

	# Distant nebula wisps (layer 0.5)
	if state == State.PLAYING or state == State.TITLE:
		var t := play_time if state == State.PLAYING else Time.get_ticks_msec() / 1000.0
		for i in 5:
			var nx := fmod(600.0 + i * 280.0 - t * 8.0, W + 200.0) - 100.0
			var ny := 100.0 + i * 120.0 + sin(t * 0.3 + i) * 30.0
			draw_circle(Vector2(nx, ny), 40.0 + sin(t * 0.2 + i * 2.0) * 10.0,
				Color(0.15, 0.08, 0.25, 0.04))
			draw_circle(Vector2(nx + 20, ny - 10), 25.0,
				Color(0.1, 0.05, 0.2, 0.03))

	# CRT scanlines
	for y in range(0, int(H), 2):
		draw_line(Vector2(0, y), Vector2(W, y), Color(0, 0, 0, 0.06))

	# Top and bottom neon borders
	draw_rect(Rect2(0, 0, W, 2), Color(0.6, 0.2, 0.8, 0.3))
	draw_rect(Rect2(0, H - 3, W, 3), Color(0.0, 0.8, 0.6, 0.25))

	# Speed bar (left edge)
	if state == State.PLAYING:
		var bar_h := clampf((speed_mult - 1.0) / 3.0, 0.0, 1.0) * (H - 80)
		draw_rect(Rect2(3, H - 40 - bar_h, 4, bar_h), Color(1.0, 0.3, 0.6, 0.4))

# ─── Audio: FM Synth Melody (melancholic minor key) ───

# A minor pentatonic with passing tones — wistful and lonely
var _melody: Array[float] = [
	440.0, 523.25, 587.33, 659.25, 784.0,     # A4 C5 D5 E5 G5
	659.25, 587.33, 523.25, 440.0, 392.0,      # E5 D5 C5 A4 G4
	349.23, 392.0, 440.0, 523.25, 587.33,      # F4 G4 A4 C5 D5
	523.25, 440.0, 392.0, 349.23, 329.63,      # C5 A4 G4 F4 E4
]

var _bass_notes: Array[float] = [
	110.0, 110.0, 87.31, 87.31,    # A2 A2 F2 F2
	130.81, 130.81, 98.0, 98.0,    # C3 C3 G2 G2
]

func _fill_fm_buffer() -> void:
	if not fm_player.playing:
		return
	var pb := fm_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var frames := pb.get_frames_available()
	if frames <= 0:
		return

	var sr := 22050.0
	var note_idx := _beat_count % _melody.size()
	var freq := _melody[note_idx]

	for i in frames:
		var t := _fm_time
		# FM synthesis — carrier with modulator (YM2612-inspired)
		var mod_idx := 3.5 + sin(TAU * 0.3 * t) * 1.0  # Modulation depth wobble
		var mod := sin(TAU * freq * 1.0 * t)  # 1:1 ratio
		var carrier := sin(TAU * freq * t + mod_idx * mod)

		# Second operator — slight detune for Mega Drive character
		var carrier2 := sin(TAU * freq * 1.003 * t + mod_idx * 0.7 * mod)

		var value := (carrier * 0.25 + carrier2 * 0.12)

		# Beat envelope
		var beat_pos := fmod(t, BEAT_INTERVAL)
		var env := clampf(1.0 - beat_pos / (BEAT_INTERVAL * 0.7), 0.0, 1.0)
		env *= env
		value *= env

		# Quieter when not playing
		if state != State.PLAYING:
			value *= 0.12
		else:
			value *= 0.35

		_fm_time += 1.0 / sr
		pb.push_frame(Vector2(value, value))

func _fill_bass_buffer() -> void:
	if not bass_player.playing:
		return
	var pb := bass_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var frames := pb.get_frames_available()
	if frames <= 0:
		return

	var sr := 22050.0
	var idx := (_beat_count / 2) % _bass_notes.size()
	var freq := _bass_notes[idx]

	for i in frames:
		var t := _bass_time
		# FM bass — thick and gritty
		var mod := sin(TAU * freq * 2.0 * t)
		var value := sin(TAU * freq * t + 2.5 * mod) * 0.4
		value += sin(TAU * freq * 2.0 * t) * 0.15

		# Sidechain pump
		var beat_pos := fmod(t, BEAT_INTERVAL * 2.0)
		var pump := clampf(beat_pos / (BEAT_INTERVAL * 0.4), 0.0, 1.0)
		value *= pump

		if state != State.PLAYING:
			value *= 0.1
		else:
			value *= 0.45

		_bass_time += 1.0 / sr
		pb.push_frame(Vector2(value, value))

func _fill_drum_buffer() -> void:
	if not drum_player.playing:
		return
	var pb := drum_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var frames := pb.get_frames_available()
	if frames <= 0:
		return

	var sr := 22050.0

	for i in frames:
		var t := _drum_time
		var value := 0.0
		var beat_pos := fmod(t, BEAT_INTERVAL)

		# Kick on beats 0, 2
		var beat_in_bar := _beat_count % 4
		if beat_in_bar == 0 or beat_in_bar == 2:
			if beat_pos < 0.08:
				var kick_freq := 120.0 - beat_pos * 800.0
				var env := clampf(1.0 - beat_pos / 0.08, 0.0, 1.0)
				value += sin(TAU * kick_freq * beat_pos) * env * 0.4

		# Snare on beats 1, 3
		if beat_in_bar == 1 or beat_in_bar == 3:
			if beat_pos < 0.06:
				var env := clampf(1.0 - beat_pos / 0.06, 0.0, 1.0)
				value += (randf() * 2.0 - 1.0) * env * 0.2
				value += sin(TAU * 200.0 * beat_pos) * env * 0.1

		# Hi-hat on every beat
		if beat_pos < 0.02:
			var env := clampf(1.0 - beat_pos / 0.02, 0.0, 1.0)
			value += (randf() * 2.0 - 1.0) * env * 0.08

		if state != State.PLAYING:
			value *= 0.08

		_drum_time += 1.0 / sr
		pb.push_frame(Vector2(value, value))

func _fill_sfx_buffer() -> void:
	if not sfx_player.playing:
		return
	var pb := sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var frames := pb.get_frames_available()
	if frames <= 0:
		return

	var sr := 22050.0
	for i in frames:
		var value := 0.0
		if _sfx_playing:
			var t := _sfx_time
			match _sfx_type:
				"collect_salvage":
					# Metallic ping
					var freq := 1200.0 + sin(t * 40.0) * 200.0
					var env := clampf(1.0 - t / 0.1, 0.0, 1.0)
					value = sin(TAU * freq * t) * env * 0.35
					if t > 0.1: _sfx_playing = false
				"collect_cassette":
					# Tape click + rewind sweep
					var freq := 400.0 + t * 2000.0
					var env := clampf(1.0 - t / 0.15, 0.0, 1.0)
					value = sin(TAU * freq * t) * env * 0.3
					if t < 0.02: value += 0.3  # Click
					if t > 0.15: _sfx_playing = false
				"collect_wool":
					# Soft puff — filtered noise
					var env := clampf(1.0 - t / 0.12, 0.0, 1.0)
					value = (randf() * 2.0 - 1.0) * env * 0.15
					value += sin(TAU * 300.0 * t) * env * 0.05  # Soft tone
					if t > 0.12: _sfx_playing = false
				"collect_debris":
					# Metallic clank
					var env := clampf(1.0 - t / 0.08, 0.0, 1.0)
					value = sin(TAU * 800.0 * t) * env * 0.3
					value += sin(TAU * 1100.0 * t) * env * 0.15
					if t > 0.08: _sfx_playing = false
				"collect_headphones":
					# Ascending arpeggio — 3 quick tones
					var env := clampf(1.0 - t / 0.25, 0.0, 1.0)
					var freq := 440.0
					if t < 0.08: freq = 440.0
					elif t < 0.16: freq = 554.37
					else: freq = 659.25
					value = sin(TAU * freq * t) * env * 0.3
					if t > 0.25: _sfx_playing = false
				"collect_music_note":
					# Pure bell chime — long sustain
					var env := clampf(1.0 - t / 0.5, 0.0, 1.0)
					env *= env
					value = sin(TAU * 880.0 * t) * env * 0.25
					value += sin(TAU * 1760.0 * t) * env * 0.1  # Overtone
					value += sin(TAU * 1318.5 * t) * env * 0.08  # Fifth
					if t > 0.5: _sfx_playing = false
				"damage":
					# Harsh buzz
					var env := clampf(1.0 - t / 0.2, 0.0, 1.0)
					var sq := 1.0 if sin(TAU * 150.0 * t) > 0 else -1.0
					value = sq * env * 0.35
					if t > 0.2: _sfx_playing = false
				"gameover":
					# Descending wah
					var freq := 500.0 - t * 350.0
					var env := clampf(1.0 - t / 1.2, 0.0, 1.0)
					value = sin(TAU * freq * t) * env * 0.4
					value += sin(TAU * freq * 0.5 * t) * env * 0.2
					value *= 0.6 + sin(TAU * 7.0 * t) * 0.4
					if t > 1.2: _sfx_playing = false
				"nearmiss":
					var freq := 700.0 + t * 2500.0
					var env := clampf(1.0 - t / 0.1, 0.0, 1.0)
					value = sin(TAU * freq * t) * env * 0.3
					if t > 0.1: _sfx_playing = false
			_sfx_time += 1.0 / sr
		pb.push_frame(Vector2(value, value))

func _play_sfx(type: String) -> void:
	_sfx_playing = true
	_sfx_type = type
	_sfx_time = 0.0
