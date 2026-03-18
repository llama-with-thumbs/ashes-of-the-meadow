extends Node2D

## MEGA SHEEP — 16-bit Mega Drive style side-scrolling space arcade
## A melancholic retro minigame about a Little Prince sheep drifting through ruins,
## dodging meteors and collecting fragments of a broken world.

const RetroSprites = preload("res://scripts/minigame/retro_sprites.gd")

# ─── State Machine ───

enum State { TITLE, PLAYING, GAMEOVER, RESULTS }
var state: State = State.TITLE

# ─── Screen ───

const W: float = 1280.0
const H: float = 720.0
const HUD_H: float = 64.0  # Top panel height

# ─── Player ───

var sheep_pos: Vector2 = Vector2(140, 400)
var sheep_speed: float = 280.0
var sheep_hitbox: float = 15.0
var sheep_frames: Array[ImageTexture] = []
var sheep_frame_idx: int = 0
var sheep_anim_timer: float = 0.0
var lives: int = 3
const MAX_LIVES: int = 5
var invincible: float = 0.0
var blink_timer: float = 0.0

# ─── Power-ups ───

var shield_active: bool = false
var shield_timer: float = 0.0
var shield_hit_flash: float = 0.0
var magnet_active: bool = false
var magnet_timer: float = 0.0
var slowmo_active: bool = false
var slowmo_timer: float = 0.0
const MAGNET_RADIUS: float = 180.0
const MAGNET_PULL: float = 350.0

# ─── Sound Waves (projectile) ───

var sound_waves: Array = []  # {pos, vel, radius, life, max_life, power}
var wave_cooldown: float = 0.0
const WAVE_COOLDOWN: float = 1.0
var wave_charge: float = 0.0  # Hold SPACE to charge (0..1)
var wave_charging: bool = false
const WAVE_CHARGE_TIME: float = 0.8  # Time to fully charge
var meteors_destroyed: int = 0  # Track for results screen

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
	{"type": "salvage", "weight": 20, "score": 10},
	{"type": "wool", "weight": 16, "score": 10},
	{"type": "debris", "weight": 16, "score": 15},
	{"type": "cassette", "weight": 10, "score": 25},
	{"type": "headphones", "weight": 8, "score": 30},
	{"type": "music_note", "weight": 8, "score": 50},
	{"type": "golden_star", "weight": 4, "score": 100},
	{"type": "shield", "weight": 6, "score": 5},
	{"type": "magnet", "weight": 6, "score": 5},
	{"type": "slowmo", "weight": 6, "score": 5},
]

# ─── Combo System ───

var combo_count: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW: float = 1.8
var _last_combo_milestone: int = 0

# ─── Scoring & Difficulty ───

var score: int = 0
var high_score: int = 0
var distance: float = 0.0
var speed_mult: float = 1.0
var play_time: float = 0.0
var near_miss_cd: float = 0.0

# ─── Waves ───

var wave: int = 1
var wave_timer: float = 0.0
const WAVE_DURATION: float = 25.0
var wave_announce_timer: float = 0.0
var meteor_storm: bool = false
var storm_timer: float = 0.0

# ─── Screen Effects ───

var shake_intensity: float = 0.0
var shake_decay: float = 8.0
var screen_flash: float = 0.0  # White flash alpha (decays)
var screen_flash_color: Color = Color.WHITE
var damage_flash: float = 0.0  # Red vignette flash

# ─── Particles ───

var particles: Array = []
var trail_timer: float = 0.0

# ─── Shooting Stars (background) ───

var shooting_stars: Array = []
var shooting_star_timer: float = 0.0

# ─── Parallax Stars ───

var star_layers: Array = []

# ─── UI Nodes ───

var sheep_sprite: Sprite2D
var heart_full_tex: ImageTexture
var heart_empty_tex: ImageTexture
var wave_label: Label
var title_label: Label
var results_label: Label
var item_sprites: Dictionary = {}
var point_popups: Array = []
var _hud_font: Font

# ─── Audio ───

var fm_player: AudioStreamPlayer
var bass_player: AudioStreamPlayer
var drum_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var sfx_player2: AudioStreamPlayer  # Second SFX channel for overlapping sounds

var _fm_time: float = 0.0
var _bass_time: float = 0.0
var _drum_time: float = 0.0
var _sfx_time: float = 0.0
var _sfx_playing: bool = false
var _sfx_type: String = ""
var _sfx2_time: float = 0.0
var _sfx2_playing: bool = false
var _sfx2_type: String = ""

var _beat_count: int = 0
var _beat_timer: float = 0.0
const BEAT_INTERVAL: float = 0.46

# ─── The Little Prince Easter Eggs ───

var rose_sprite_tex: ImageTexture
var fox_sprite_tex: ImageTexture
var planet_sprite_tex: ImageTexture
var baobab_sprite_tex: ImageTexture

# Fox companion
var fox_active: bool = false
var fox_timer: float = 0.0
var fox_pos: Vector2 = Vector2.ZERO
var fox_sprite: Sprite2D = null
const FOX_DURATION: float = 15.0
const FOX_MAGNET_RADIUS: float = 250.0

# Rose collectible (added to COLLECT_TYPES dynamically)
var rose_collected: bool = false

# Baobab obstacles
var baobabs: Array = []  # {pos, growth, max_size, sprite}
var baobab_timer: float = 0.0

# Tiny planets (background drifting)
var tiny_planets: Array = []  # {pos, speed, sprite}
var planet_timer: float = 0.0

# Sunset event
var sunset_active: bool = false
var sunset_timer: float = 0.0
var sunset_progress: float = 0.0  # 0 to 1 and back

# Little Prince quotes
var _lp_quotes: Array[String] = [
	"\"What is essential is invisible to the eye.\"",
	"\"You become responsible for what you have tamed.\"",
	"\"It is only with the heart that one can see rightly.\"",
	"\"All grown-ups were once children.\"",
	"\"The stars are beautiful because of a flower you cannot see.\"",
	"\"One sees clearly only with the heart.\"",
	"\"If you love a flower on a star, it is sweet at night to look at the sky.\"",
]

# ─── Melancholic Atmosphere ───

# Memory fragments — diary entries drifting through space
var memory_fragments: Array = []  # {pos, vel, text, life, max_life, alpha}
var memory_timer: float = 0.0
var _memory_texts: Array[String] = [
	"I remember green fields...",
	"The wind used to sing here.",
	"Was there ever warmth?",
	"Someone called my name once.",
	"The meadow is gone.",
	"I keep drifting... always drifting.",
	"Stars don't answer when you call.",
	"Everything I loved is ashes now.",
	"There was music in the grass.",
	"I think I had a home.",
	"The silence is so heavy.",
	"Do the others remember me?",
	"Even the echoes are fading.",
	"One more fragment... one more memory.",
	"The sky used to be blue.",
	"I'm still here. I'm still here.",
]

# Ghost sheep — faint echoes of others who came before
var ghost_sheep: Array = []  # {pos, vel, alpha, life, max_life, frame}
var ghost_timer: float = 0.0

# Ambient whisper words — single words that drift by
var whisper_words: Array = []  # {pos, vel, text, life, max_life}
var whisper_timer: float = 0.0
var _whisper_pool: Array[String] = [
	"home", "lost", "remember", "alone", "echo", "ashes",
	"meadow", "silence", "drift", "far", "gone", "fading",
	"once", "warmth", "stars", "dust", "wind", "light",
]

# Stardust trails from destroyed meteors
var stardust_points: Array = []  # {pos, life, brightness}

# ─── Particle Color Lookup ───

var _item_particle_colors: Dictionary = {
	"salvage": Color(0.4, 0.6, 1.0, 0.8),
	"wool": Color(1.0, 0.9, 1.0, 0.7),
	"debris": Color(0.6, 0.65, 0.75, 0.8),
	"cassette": Color(1.0, 0.7, 0.2, 0.8),
	"headphones": Color(1.0, 0.3, 0.6, 0.8),
	"music_note": Color(1.0, 0.85, 0.1, 0.9),
	"golden_star": Color(1.0, 0.95, 0.4, 1.0),
	"shield": Color(0.3, 0.9, 1.0, 0.8),
	"magnet": Color(1.0, 0.3, 0.5, 0.8),
	"slowmo": Color(0.6, 0.3, 1.0, 0.8),
	"rose": Color(1.0, 0.3, 0.4, 0.9),
}

# ─── Lifecycle ───

func _ready() -> void:
	sheep_frames = [RetroSprites.generate_pixel_sheep(), RetroSprites.generate_pixel_sheep_frame2()]
	heart_full_tex = RetroSprites.generate_heart()
	heart_empty_tex = RetroSprites.generate_heart_empty()
	for ct in COLLECT_TYPES:
		match ct.type:
			"golden_star":
				item_sprites["golden_star"] = RetroSprites.generate_golden_star()
			"shield":
				item_sprites["shield"] = RetroSprites.generate_shield_icon()
			"magnet":
				item_sprites["magnet"] = RetroSprites.generate_magnet_icon()
			"slowmo":
				item_sprites["slowmo"] = RetroSprites.generate_slowmo_icon()
			_:
				item_sprites[ct.type] = RetroSprites.generate_mini_collectible(ct.type)

	# Little Prince sprites
	rose_sprite_tex = RetroSprites.generate_rose()
	fox_sprite_tex = RetroSprites.generate_fox()
	planet_sprite_tex = RetroSprites.generate_tiny_planet()
	baobab_sprite_tex = RetroSprites.generate_baobab()
	item_sprites["rose"] = rose_sprite_tex

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
	_hud_font = ThemeDB.fallback_font

	sheep_sprite = Sprite2D.new()
	sheep_sprite.texture = sheep_frames[0]
	sheep_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sheep_sprite.scale = Vector2(2.2, 2.2)
	sheep_sprite.z_index = 20
	add_child(sheep_sprite)

	wave_label = Label.new()
	wave_label.z_index = 55
	wave_label.position = Vector2(340, 200)
	wave_label.size = Vector2(600, 60)
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wave_label.add_theme_font_size_override("font_size", 32)
	wave_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	wave_label.visible = false
	add_child(wave_label)

	title_label = Label.new()
	title_label.z_index = 50
	title_label.position = Vector2(220, 80)
	title_label.size = Vector2(840, 560)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	add_child(title_label)

	results_label = Label.new()
	results_label.z_index = 50
	results_label.position = Vector2(290, 80)
	results_label.size = Vector2(700, 580)
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
	sfx_player2 = _make_audio_player(-2.0, 0.5)

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
	title_label.text = "M E G A   S H E E P\n\n\nDrift through the ruins. Collect what remains.\nDodge the meteors. Destroy them with sound.\n\nSPACE — Fire sound wave (hold to charge!)\nGolden stars grant extra lives.\nShields, Magnets, Slow-mo & Combos!\n\n\nArrow Keys / WASD to move\n\nPress SPACE to launch\nPress ESC to return"
	title_label.visible = true
	results_label.visible = false
	wave_label.visible = false
	sheep_sprite.visible = false

func _start_game() -> void:
	state = State.PLAYING
	score = 0
	distance = 0.0
	speed_mult = 1.0
	play_time = 0.0
	lives = 3
	invincible = 0.0
	meteor_timer = 0.0
	meteor_interval = 0.9
	collect_timer = 0.0
	collect_interval = 2.0
	_beat_count = 0
	_beat_timer = 0.0
	sheep_pos = Vector2(140, (HUD_H + H) / 2.0)
	collected_tally.clear()
	combo_count = 0
	combo_timer = 0.0
	_last_combo_milestone = 0
	wave = 1
	wave_timer = 0.0
	wave_announce_timer = 0.0
	meteor_storm = false
	storm_timer = 0.0
	shield_active = false
	shield_timer = 0.0
	shield_hit_flash = 0.0
	magnet_active = false
	magnet_timer = 0.0
	slowmo_active = false
	slowmo_timer = 0.0
	shake_intensity = 0.0
	screen_flash = 0.0
	damage_flash = 0.0
	sound_waves.clear()
	wave_cooldown = 0.0
	wave_charge = 0.0
	wave_charging = false
	meteors_destroyed = 0

	for m in meteors:
		if m.sprite and is_instance_valid(m.sprite):
			m.sprite.queue_free()
	meteors.clear()
	for c in collectibles:
		if c.sprite and is_instance_valid(c.sprite):
			c.sprite.queue_free()
	collectibles.clear()
	for p in point_popups:
		if p.label and is_instance_valid(p.label):
			p.label.queue_free()
	point_popups.clear()
	particles.clear()
	shooting_stars.clear()

	# Little Prince reset
	fox_active = false
	fox_timer = 0.0
	if fox_sprite and is_instance_valid(fox_sprite):
		fox_sprite.queue_free()
		fox_sprite = null
	rose_collected = false
	for b in baobabs:
		if b.sprite and is_instance_valid(b.sprite):
			b.sprite.queue_free()
	baobabs.clear()
	baobab_timer = 0.0
	for tp in tiny_planets:
		if tp.sprite and is_instance_valid(tp.sprite):
			tp.sprite.queue_free()
	tiny_planets.clear()
	planet_timer = 0.0
	sunset_active = false
	sunset_timer = 0.0
	sunset_progress = 0.0
	memory_fragments.clear()
	memory_timer = 0.0
	ghost_sheep.clear()
	ghost_timer = 0.0
	whisper_words.clear()
	whisper_timer = 0.0
	stardust_points.clear()

	title_label.visible = false
	results_label.visible = false
	wave_label.visible = false
	sheep_sprite.visible = true
	sheep_sprite.modulate = Color.WHITE

	_announce_wave()

func _announce_wave() -> void:
	var texts := [
		"WAVE 1 — Into the Void",
		"WAVE 2 — Scattered Remains",
		"WAVE 3 — Meteor Rain",
		"WAVE 4 — The Deep Field",
		"WAVE 5 — Starfall",
		"WAVE 6 — Among the Ruins",
		"WAVE 7 — Cosmic Storm",
		"WAVE 8 — The Last Signal",
	]
	var idx := mini(wave - 1, texts.size() - 1)
	wave_label.text = texts[idx] if wave <= texts.size() else "WAVE %d — Endurance" % wave
	wave_label.visible = true
	wave_label.modulate.a = 1.0
	wave_announce_timer = 2.5
	_play_sfx2("wave_start")

func _take_damage() -> void:
	if invincible > 0:
		return

	if shield_active:
		shield_active = false
		shield_timer = 0.0
		shield_hit_flash = 0.4
		_play_sfx("shield_break")
		shake_intensity = 4.0
		screen_flash = 0.3
		screen_flash_color = Color(0.3, 0.9, 1.0)
		_spawn_ring_particles(sheep_pos, 16, Color(0.4, 0.9, 1.0, 0.9), 36.0)
		return

	lives -= 1
	invincible = 1.8
	shake_intensity = 10.0
	damage_flash = 0.5
	_play_sfx("damage")
	_play_sfx2("hit_impact")

	combo_count = 0
	combo_timer = 0.0
	_last_combo_milestone = 0

	_spawn_particles(sheep_pos, 15, Color(1.0, 0.3, 0.2, 0.9), 180.0)
	# Wool puffs scatter from sheep
	for i in 5:
		particles.append({
			"pos": sheep_pos + Vector2(randf_range(-10, 10), randf_range(-10, 10)),
			"vel": Vector2(randf_range(-100, 100), randf_range(-120, -30)),
			"life": randf_range(0.5, 1.0),
			"max_life": 1.0,
			"color": Color(1.0, 0.95, 0.85, 0.7),
			"size": randf_range(3.0, 6.0),
		})

	if lives <= 0:
		_game_over()

func _game_over() -> void:
	state = State.GAMEOVER
	sheep_sprite.modulate = Color(1.0, 0.3, 0.3)
	shake_intensity = 15.0
	damage_flash = 1.0
	_play_sfx("gameover")
	if score > high_score:
		high_score = score
	get_tree().create_timer(2.0).timeout.connect(_show_results)

func _show_results() -> void:
	state = State.RESULTS
	_transfer_resources()

	var mins := int(play_time) / 60
	var secs := int(play_time) % 60

	var text := "M I S S I O N   R E P O R T\n\n"
	text += "Wave: %d\n" % wave
	text += "Distance: %dm\n" % int(distance)
	text += "Time: %d:%02d\n" % [mins, secs]
	text += "Score: %d\n" % score
	text += "High Score: %d\n" % high_score
	if meteors_destroyed > 0:
		text += "Meteors Destroyed: %d\n" % meteors_destroyed
	text += "\n"

	if collected_tally.size() > 0:
		for type in collected_tally:
			var display_name: String = type.replace("_", " ").capitalize()
			if type == "golden_star":
				display_name = "Golden Star"
			text += "%s: x%d\n" % [display_name, collected_tally[type]]
		text += "\nResources transferred to inventory.\n"
	else:
		text += "No items collected.\n"

	text += "\n\nSPACE to retry    ESC to exit"
	results_label.text = text
	results_label.visible = true
	title_label.visible = false
	wave_label.visible = false

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
			"golden_star":
				GameState.add_item("stardust", count * 3)
			"rose":
				GameState.add_item("stardust", count * 5)

# ─── Input ───

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_SPACE:
			if event.pressed:
				if state == State.TITLE or state == State.RESULTS:
					_start_game()
				elif state == State.PLAYING and wave_cooldown <= 0:
					wave_charging = true
					wave_charge = 0.0
			else:
				# SPACE released — fire charged wave
				if state == State.PLAYING and wave_charging:
					_fire_sound_wave()
					wave_charging = false
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/main.tscn")

# ─── Main Loop ───

func _process(delta: float) -> void:
	_fill_fm_buffer()
	_fill_bass_buffer()
	_fill_drum_buffer()
	_fill_sfx_buffer()
	_fill_sfx2_buffer()

	# Slow-mo affects game delta
	var game_delta := delta
	if slowmo_active and state == State.PLAYING:
		game_delta *= 0.35

	for layer in star_layers:
		var spd: float = layer.speed * (speed_mult if state == State.PLAYING else 0.4)
		for star in layer.stars:
			star.pos.x -= spd * game_delta
			if star.pos.x < -2:
				star.pos.x += W + 4
				star.pos.y = randf() * H

	_update_shooting_stars(game_delta)

	# Screen effects decay (always)
	if screen_flash > 0:
		screen_flash = maxf(screen_flash - delta * 3.0, 0.0)
	if damage_flash > 0:
		damage_flash = maxf(damage_flash - delta * 2.5, 0.0)
	if shield_hit_flash > 0:
		shield_hit_flash = maxf(shield_hit_flash - delta * 3.0, 0.0)
	if shake_intensity > 0:
		shake_intensity = maxf(shake_intensity - shake_decay * delta, 0.0)

	if state != State.PLAYING:
		queue_redraw()
		return

	play_time += game_delta
	_beat_timer += game_delta
	if _beat_timer >= BEAT_INTERVAL:
		_beat_timer -= BEAT_INTERVAL
		_beat_count += 1

	# ── Wave system ──
	wave_timer += game_delta
	if wave_timer >= WAVE_DURATION:
		wave_timer -= WAVE_DURATION
		wave += 1
		_announce_wave()
		if wave % 3 == 0:
			meteor_storm = true
			storm_timer = 5.0

	if wave_announce_timer > 0:
		wave_announce_timer -= delta
		wave_label.modulate.a = clampf(wave_announce_timer / 1.0, 0.0, 1.0)
		if wave_announce_timer <= 0:
			wave_label.visible = false

	if meteor_storm:
		storm_timer -= game_delta
		if storm_timer <= 0:
			meteor_storm = false

	# Difficulty ramp
	var wave_mult := 1.0 + (wave - 1) * 0.15
	speed_mult = (1.0 + play_time * 0.02) * wave_mult
	meteor_interval = maxf(0.15, 0.9 - play_time * 0.006 - (wave - 1) * 0.05)
	if meteor_storm:
		meteor_interval *= 0.3
	collect_interval = maxf(0.6, 2.0 - play_time * 0.008)

	# ── Power-up timers ──
	if shield_active:
		shield_timer -= delta
		if shield_timer <= 0:
			shield_active = false
			_play_sfx2("shield_expire")
	if magnet_active:
		magnet_timer -= delta
		if magnet_timer <= 0:
			magnet_active = false
	if slowmo_active:
		slowmo_timer -= delta
		if slowmo_timer <= 0:
			slowmo_active = false

	# ── Combo decay ──
	if combo_count > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0
			_last_combo_milestone = 0

	# ── Player movement ──
	var move := Vector2.ZERO
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		move.y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		move.y += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		move.x -= 0.5
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		move.x += 0.5

	sheep_pos += move * sheep_speed * delta  # Movement not affected by slow-mo
	sheep_pos.x = clampf(sheep_pos.x, 40.0, W * 0.3)
	sheep_pos.y = clampf(sheep_pos.y, HUD_H + 20.0, H - 30.0)
	sheep_sprite.position = sheep_pos

	sheep_anim_timer += delta
	if sheep_anim_timer > 0.2:
		sheep_anim_timer -= 0.2
		sheep_frame_idx = (sheep_frame_idx + 1) % sheep_frames.size()
		sheep_sprite.texture = sheep_frames[sheep_frame_idx]

	if invincible > 0:
		invincible -= delta
		blink_timer += delta
		sheep_sprite.visible = int(blink_timer * 10) % 2 == 0
		if invincible <= 0:
			sheep_sprite.visible = true
			sheep_sprite.modulate = Color.WHITE

	# Trail particles
	trail_timer += delta
	if trail_timer > 0.06:
		trail_timer -= 0.06
		var trail_col := Color(1.0, 0.95, 0.85, 0.35)
		if shield_active:
			trail_col = Color(0.4, 0.9, 1.0, 0.4)
		elif magnet_active:
			trail_col = Color(1.0, 0.4, 0.6, 0.35)
		elif slowmo_active:
			trail_col = Color(0.6, 0.3, 1.0, 0.4)
		particles.append({
			"pos": sheep_pos + Vector2(-18 + randf() * 6, randf_range(-8, 8)),
			"vel": Vector2(randf_range(-40, -70), randf_range(-12, 12)),
			"life": 0.5,
			"max_life": 0.5,
			"color": trail_col,
			"size": randf_range(2.0, 4.5),
		})

	if near_miss_cd > 0:
		near_miss_cd -= delta

	# ── Sound wave cooldown & charging ──
	if wave_cooldown > 0:
		wave_cooldown -= delta
	if wave_charging:
		wave_charge = minf(wave_charge + delta / WAVE_CHARGE_TIME, 1.0)
		# Charge particles around sheep
		if int(play_time * 20) % 2 == 0:
			var angle := randf() * TAU
			var dist := 30.0 + randf() * 15.0
			particles.append({
				"pos": sheep_pos + Vector2(cos(angle) * dist, sin(angle) * dist),
				"vel": Vector2(cos(angle), sin(angle)) * -50.0,
				"life": 0.25,
				"max_life": 0.25,
				"color": Color(0.3 + wave_charge * 0.7, 0.8, 1.0, 0.5 + wave_charge * 0.3),
				"size": 1.5 + wave_charge * 2.0,
			})

	# ── Update sound waves ──
	var sw_remove: Array[int] = []
	for i in sound_waves.size():
		var sw = sound_waves[i]
		sw.pos += sw.vel * game_delta
		sw.radius += sw.expand_rate * game_delta
		sw.life -= game_delta
		if sw.life <= 0 or sw.pos.x > W + 80:
			sw_remove.append(i)
			continue
		# Check collision with meteors
		var met_kill: Array[int] = []
		for mi in meteors.size():
			var m = meteors[mi]
			var dist_to_wave: float = sw.pos.distance_to(m.pos)
			if dist_to_wave < sw.radius + m.radius:
				met_kill.append(mi)
		# Destroy hit meteors (iterate in reverse)
		for ki in range(met_kill.size() - 1, -1, -1):
			var mi: int = met_kill[ki]
			if mi < meteors.size():
				var m = meteors[mi]
				# Shatter particles — more dramatic than normal
				_spawn_particles(m.pos, 14, Color(1.0, 0.6, 0.2, 0.9), 160.0)
				_spawn_ring_particles(m.pos, 10, Color(0.5, 0.8, 1.0, 0.7), 20.0)
				# Debris chunks
				for j in 4:
					particles.append({
						"pos": m.pos + Vector2(randf_range(-5, 5), randf_range(-5, 5)),
						"vel": Vector2(randf_range(-150, 150), randf_range(-150, 150)),
						"life": randf_range(0.4, 0.8),
						"max_life": 0.8,
						"color": Color(0.6, 0.4, 0.3, 0.8),
						"size": randf_range(3.0, 7.0),
					})
				# Score bonus
				var destroy_score := 15 + wave * 3
				if sw.power > 0.7:
					destroy_score = int(destroy_score * 1.5)
				score += destroy_score
				meteors_destroyed += 1
				_play_sfx2("meteor_shatter")
				_spawn_popup("+%d" % destroy_score, m.pos + Vector2(0, -20), Color(0.5, 0.9, 1.0))
				# Leave stardust where the meteor was destroyed
				for sd_i in randi_range(3, 6):
					stardust_points.append({
						"pos": m.pos + Vector2(randf_range(-15, 15), randf_range(-15, 15)),
						"life": randf_range(4.0, 8.0),
						"brightness": randf_range(0.3, 0.8),
					})
				# Flash
				screen_flash = 0.08
				screen_flash_color = Color(0.4, 0.8, 1.0)
				if m.sprite and is_instance_valid(m.sprite):
					m.sprite.queue_free()
				meteors.remove_at(mi)
	for i in range(sw_remove.size() - 1, -1, -1):
		sound_waves.remove_at(sw_remove[i])

	# Spawn meteors
	meteor_timer += game_delta
	if meteor_timer >= meteor_interval:
		meteor_timer -= meteor_interval
		_spawn_meteor()

	# Spawn collectibles
	collect_timer += game_delta
	if collect_timer >= collect_interval:
		collect_timer -= collect_interval
		_spawn_collectible()

	# ── Update meteors ──
	var m_remove: Array[int] = []
	for i in meteors.size():
		var m = meteors[i]
		m.pos.x -= m.speed * speed_mult * game_delta
		m.rot += m.rot_speed * game_delta
		if m.sprite and is_instance_valid(m.sprite):
			m.sprite.position = m.pos
			m.sprite.rotation = m.rot
			# Slow-mo tint
			if slowmo_active:
				m.sprite.modulate = Color(0.7, 0.6, 1.0, 0.9)
			else:
				m.sprite.modulate = Color.WHITE

		if m.pos.x < -60:
			m_remove.append(i)
			continue

		var dist_to := sheep_pos.distance_to(m.pos)
		if dist_to < sheep_hitbox + m.radius:
			# Meteor explosion particles
			_spawn_particles(m.pos, 8, Color(0.8, 0.4, 0.2, 0.8), 100.0)
			_take_damage()
			m_remove.append(i)
			continue

		if dist_to < sheep_hitbox + m.radius + 25.0 and m.pos.x < sheep_pos.x and near_miss_cd <= 0:
			var bonus := 5 + wave
			score += bonus
			near_miss_cd = 0.4
			_play_sfx2("nearmiss")
			_spawn_popup("NEAR! +%d" % bonus, sheep_pos + Vector2(20, -30), Color(0.5, 1.0, 0.8))

	for i in range(m_remove.size() - 1, -1, -1):
		var idx = m_remove[i]
		if meteors[idx].sprite and is_instance_valid(meteors[idx].sprite):
			meteors[idx].sprite.queue_free()
		meteors.remove_at(idx)

	# ── Update collectibles ──
	var c_remove: Array[int] = []
	for i in collectibles.size():
		var c = collectibles[i]
		c.pos.x -= c.speed * speed_mult * game_delta
		c.pos.y += sin(play_time * 3.0 + c.bob_offset) * 0.5

		if magnet_active:
			var to_sheep: Vector2 = sheep_pos - c.pos
			var dist_to: float = to_sheep.length()
			if dist_to < MAGNET_RADIUS and dist_to > 1.0:
				var pull_strength := MAGNET_PULL * (1.0 - dist_to / MAGNET_RADIUS)
				c.pos += to_sheep.normalized() * pull_strength * delta
				# Magnet pull sparkle trail
				if randf() < 0.3:
					particles.append({
						"pos": c.pos + Vector2(randf_range(-4, 4), randf_range(-4, 4)),
						"vel": to_sheep.normalized() * 40.0,
						"life": 0.2,
						"max_life": 0.2,
						"color": Color(1.0, 0.5, 0.7, 0.5),
						"size": 1.5,
					})

		if c.sprite and is_instance_valid(c.sprite):
			c.sprite.position = c.pos

		if c.pos.x < -30:
			c_remove.append(i)
			continue

		if sheep_pos.distance_to(c.pos) < sheep_hitbox + 12.0:
			_collect_item(c.type, c.score_val)
			c_remove.append(i)
			continue

	for i in range(c_remove.size() - 1, -1, -1):
		var idx = c_remove[i]
		if collectibles[idx].sprite and is_instance_valid(collectibles[idx].sprite):
			collectibles[idx].sprite.queue_free()
		collectibles.remove_at(idx)

	# ── Little Prince: Fox companion ──
	if fox_active:
		fox_timer -= delta
		# Fox follows sheep with lag
		var fox_target := sheep_pos + Vector2(-50, 20)
		fox_pos = fox_pos.lerp(fox_target, 3.0 * delta)
		if fox_sprite and is_instance_valid(fox_sprite):
			fox_sprite.position = fox_pos
			# Fox bob
			fox_sprite.position.y += sin(play_time * 4.0) * 3.0
		# Fox magnetizes items (stronger than magnet power-up)
		for c in collectibles:
			var to_fox: Vector2 = fox_pos - c.pos
			var fox_dist: float = to_fox.length()
			if fox_dist < FOX_MAGNET_RADIUS and fox_dist > 1.0:
				var pull := 200.0 * (1.0 - fox_dist / FOX_MAGNET_RADIUS)
				c.pos += to_fox.normalized() * pull * delta
		# Fox sparkle trail
		if int(play_time * 15) % 3 == 0:
			particles.append({
				"pos": fox_pos + Vector2(randf_range(-6, 6), randf_range(-4, 4)),
				"vel": Vector2(randf_range(-20, -40), randf_range(-15, 15)),
				"life": 0.4,
				"max_life": 0.4,
				"color": Color(1.0, 0.7, 0.2, 0.5),
				"size": randf_range(1.5, 3.0),
			})
		if fox_timer <= 0:
			fox_active = false
			if fox_sprite and is_instance_valid(fox_sprite):
				fox_sprite.queue_free()
				fox_sprite = null
			_spawn_popup("\"Goodbye...\"", fox_pos + Vector2(0, -30), Color(1.0, 0.7, 0.2))
	elif wave > 1 and wave % 2 == 0 and wave_timer < 1.0 and wave_timer > 0.5 and not fox_active:
		# Fox appears at start of every even wave
		_summon_fox()

	# ── Little Prince: Baobab obstacles ──
	baobab_timer += game_delta
	if baobab_timer > 8.0 and wave >= 2:
		baobab_timer = 0.0
		if baobabs.size() < 3:
			_spawn_baobab()
	var b_remove: Array[int] = []
	for i in baobabs.size():
		var b = baobabs[i]
		b.pos.x -= 30.0 * speed_mult * game_delta
		# Grow over time
		b.growth = minf(b.growth + delta * 0.3, b.max_size)
		if b.sprite and is_instance_valid(b.sprite):
			b.sprite.position = b.pos
			var sc: float = b.growth
			b.sprite.scale = Vector2(sc, sc)
		if b.pos.x < -50:
			b_remove.append(i)
			continue
		# Collision with grown baobabs
		if b.growth > 1.5:
			var dist_to := sheep_pos.distance_to(b.pos)
			if dist_to < sheep_hitbox + b.growth * 8.0:
				_take_damage()
				b_remove.append(i)
				_spawn_particles(b.pos, 10, Color(0.3, 0.6, 0.2, 0.8), 80.0)
				continue
	for i in range(b_remove.size() - 1, -1, -1):
		var idx = b_remove[i]
		if baobabs[idx].sprite and is_instance_valid(baobabs[idx].sprite):
			baobabs[idx].sprite.queue_free()
		baobabs.remove_at(idx)

	# ── Little Prince: Tiny planets drifting in background ──
	planet_timer += game_delta
	if planet_timer > 12.0:
		planet_timer = 0.0
		_spawn_tiny_planet()
	var tp_remove: Array[int] = []
	for i in tiny_planets.size():
		var tp = tiny_planets[i]
		tp.pos.x -= tp.speed * game_delta
		tp.pos.y += sin(play_time * 0.5 + tp.pos.x * 0.01) * 0.3
		if tp.sprite and is_instance_valid(tp.sprite):
			tp.sprite.position = tp.pos
		if tp.pos.x < -60:
			tp_remove.append(i)
	for i in range(tp_remove.size() - 1, -1, -1):
		var idx = tp_remove[i]
		if tiny_planets[idx].sprite and is_instance_valid(tiny_planets[idx].sprite):
			tiny_planets[idx].sprite.queue_free()
		tiny_planets.remove_at(idx)

	# ── Little Prince: Sunset event ──
	if not sunset_active and fmod(play_time, 45.0) < game_delta and play_time > 10.0:
		sunset_active = true
		sunset_timer = 8.0
		sunset_progress = 0.0
	if sunset_active:
		sunset_timer -= delta
		# Fade in for first 2s, hold, fade out last 2s
		if sunset_timer > 6.0:
			sunset_progress = (8.0 - sunset_timer) / 2.0
		elif sunset_timer < 2.0:
			sunset_progress = sunset_timer / 2.0
		else:
			sunset_progress = 1.0
		if sunset_timer <= 0:
			sunset_active = false
			sunset_progress = 0.0

	# ── Little Prince: Spawn rose (rare, once per game until collected) ──
	if not rose_collected and play_time > 30.0 and fmod(play_time, 40.0) < game_delta:
		_spawn_rose()

	# ── Melancholic: Memory fragments ──
	memory_timer += game_delta
	if memory_timer > 12.0 + randf() * 8.0:
		memory_timer = 0.0
		var text: String = _memory_texts[randi() % _memory_texts.size()]
		memory_fragments.append({
			"pos": Vector2(W + 20, randf_range(HUD_H + 60, H - 100)),
			"vel": Vector2(randf_range(-25.0, -45.0), randf_range(-3.0, 3.0)),
			"text": text,
			"life": 14.0,
			"max_life": 14.0,
		})
	var mf_remove: Array[int] = []
	for i in memory_fragments.size():
		var mf = memory_fragments[i]
		mf.pos += mf.vel * game_delta
		mf.life -= game_delta
		if mf.life <= 0 or mf.pos.x < -400:
			mf_remove.append(i)
	for i in range(mf_remove.size() - 1, -1, -1):
		memory_fragments.remove_at(mf_remove[i])

	# ── Melancholic: Ghost sheep ──
	ghost_timer += game_delta
	if ghost_timer > 20.0 + randf() * 15.0:
		ghost_timer = 0.0
		ghost_sheep.append({
			"pos": Vector2(W + 40, randf_range(HUD_H + 80, H - 80)),
			"vel": Vector2(randf_range(-35.0, -55.0), randf_range(-5.0, 5.0)),
			"life": 12.0,
			"max_life": 12.0,
			"frame": randi() % 2,
		})
	var gs_remove: Array[int] = []
	for i in ghost_sheep.size():
		var gs = ghost_sheep[i]
		gs.pos += gs.vel * game_delta
		gs.pos.y += sin(play_time * 0.8 + gs.pos.x * 0.01) * 0.4
		gs.life -= game_delta
		if gs.life <= 0 or gs.pos.x < -80:
			gs_remove.append(i)
	for i in range(gs_remove.size() - 1, -1, -1):
		ghost_sheep.remove_at(gs_remove[i])

	# ── Melancholic: Whisper words ──
	whisper_timer += game_delta
	if whisper_timer > 5.0 + randf() * 4.0:
		whisper_timer = 0.0
		var word: String = _whisper_pool[randi() % _whisper_pool.size()]
		whisper_words.append({
			"pos": Vector2(randf_range(W * 0.3, W), randf_range(HUD_H + 40, H - 40)),
			"vel": Vector2(randf_range(-15.0, -30.0), randf_range(-8.0, 8.0)),
			"text": word,
			"life": 6.0,
			"max_life": 6.0,
		})
	var ww_remove: Array[int] = []
	for i in whisper_words.size():
		var ww = whisper_words[i]
		ww.pos += ww.vel * game_delta
		ww.life -= game_delta
		if ww.life <= 0 or ww.pos.x < -100:
			ww_remove.append(i)
	for i in range(ww_remove.size() - 1, -1, -1):
		whisper_words.remove_at(ww_remove[i])

	# ── Stardust trails (from destroyed meteors) ──
	var sd_remove: Array[int] = []
	for i in stardust_points.size():
		var sd = stardust_points[i]
		sd.pos.x -= 15.0 * speed_mult * game_delta
		sd.life -= game_delta
		if sd.life <= 0 or sd.pos.x < -10:
			sd_remove.append(i)
	for i in range(sd_remove.size() - 1, -1, -1):
		stardust_points.remove_at(sd_remove[i])

	# ── Update particles ──
	var p_remove: Array[int] = []
	for i in particles.size():
		var p = particles[i]
		p.pos += p.vel * delta
		p.life -= delta
		if p.life <= 0:
			p_remove.append(i)
	for i in range(p_remove.size() - 1, -1, -1):
		particles.remove_at(p_remove[i])

	# Score & distance
	score += 1
	distance += 60.0 * speed_mult * game_delta

	# Update point popups
	var pop_remove: Array[int] = []
	for i in point_popups.size():
		var p = point_popups[i]
		p.timer -= delta
		if p.label and is_instance_valid(p.label):
			p.label.position.y -= 60.0 * delta
			p.label.modulate.a = clampf(p.timer / 0.5, 0.0, 1.0)
		if p.timer <= 0:
			pop_remove.append(i)
	for i in range(pop_remove.size() - 1, -1, -1):
		var idx = pop_remove[i]
		if point_popups[idx].label and is_instance_valid(point_popups[idx].label):
			point_popups[idx].label.queue_free()
		point_popups.remove_at(idx)

	queue_redraw()

# ─── Helpers ───

func _spawn_popup(text: String, pos: Vector2, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.z_index = 60
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", color)
	add_child(lbl)
	point_popups.append({"label": lbl, "timer": 0.8})

func _spawn_particles(pos: Vector2, count: int, color: Color, spread: float) -> void:
	for i in count:
		var angle := randf() * TAU
		var spd := randf_range(spread * 0.3, spread)
		particles.append({
			"pos": pos,
			"vel": Vector2(cos(angle) * spd, sin(angle) * spd),
			"life": randf_range(0.3, 0.7),
			"max_life": 0.7,
			"color": color,
			"size": randf_range(2.0, 5.0),
		})

func _spawn_ring_particles(pos: Vector2, count: int, color: Color, radius: float) -> void:
	for i in count:
		var angle := float(i) / float(count) * TAU
		particles.append({
			"pos": pos + Vector2(cos(angle), sin(angle)) * radius,
			"vel": Vector2(cos(angle), sin(angle)) * 120.0,
			"life": 0.5,
			"max_life": 0.5,
			"color": color,
			"size": randf_range(2.5, 4.0),
		})

func _fire_sound_wave() -> void:
	var power := clampf(wave_charge, 0.15, 1.0)  # Minimum power even for tap
	var base_radius := 15.0 + power * 20.0
	var speed := 350.0 + power * 200.0
	var lifetime := 1.2 + power * 0.8

	sound_waves.append({
		"pos": sheep_pos + Vector2(25, 0),
		"vel": Vector2(speed, 0),
		"radius": base_radius,
		"expand_rate": 40.0 + power * 60.0,
		"life": lifetime,
		"max_life": lifetime,
		"power": power,
	})

	wave_cooldown = WAVE_COOLDOWN
	wave_charge = 0.0

	# SFX
	if power > 0.6:
		_play_sfx("sound_blast_charged")
	else:
		_play_sfx("sound_blast")

	# Launch particles
	var count := int(6 + power * 10)
	for i in count:
		var angle := randf_range(-0.5, 0.5)
		particles.append({
			"pos": sheep_pos + Vector2(20, 0),
			"vel": Vector2(cos(angle) * (200 + power * 150), sin(angle) * 80.0),
			"life": 0.3 + power * 0.2,
			"max_life": 0.5,
			"color": Color(0.4 + power * 0.6, 0.8, 1.0, 0.6),
			"size": 2.0 + power * 2.0,
		})

	# Screen kick
	shake_intensity = 2.0 + power * 4.0
	screen_flash = 0.06 + power * 0.1
	screen_flash_color = Color(0.3, 0.7, 1.0)

func _update_shooting_stars(delta: float) -> void:
	shooting_star_timer += delta
	var interval := 3.0 if state == State.TITLE else 1.5 / maxf(speed_mult, 1.0)
	if shooting_star_timer >= interval:
		shooting_star_timer -= interval
		shooting_stars.append({
			"pos": Vector2(randf_range(W * 0.3, W), randf_range(0, H * 0.6)),
			"vel": Vector2(randf_range(-500, -300), randf_range(100, 250)),
			"life": randf_range(0.3, 0.6),
			"max_life": 0.5,
		})
	var ss_remove: Array[int] = []
	for i in shooting_stars.size():
		var ss = shooting_stars[i]
		ss.pos += ss.vel * delta
		ss.life -= delta
		if ss.life <= 0 or ss.pos.x < -50 or ss.pos.y > H + 50:
			ss_remove.append(i)
	for i in range(ss_remove.size() - 1, -1, -1):
		shooting_stars.remove_at(ss_remove[i])

# ─── Little Prince Spawning ───

func _summon_fox() -> void:
	fox_active = true
	fox_timer = FOX_DURATION
	fox_pos = Vector2(-40, sheep_pos.y)
	fox_sprite = Sprite2D.new()
	fox_sprite.texture = fox_sprite_tex
	fox_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fox_sprite.scale = Vector2(2.5, 2.5)
	fox_sprite.z_index = 18
	fox_sprite.position = fox_pos
	add_child(fox_sprite)
	var quote: String = _lp_quotes[randi() % _lp_quotes.size()]
	_spawn_popup(quote, Vector2(W * 0.2, H * 0.25), Color(1.0, 0.75, 0.3))
	_play_sfx2("fox_appear")
	screen_flash = 0.15
	screen_flash_color = Color(1.0, 0.8, 0.3)

func _spawn_baobab() -> void:
	var y := randf_range(HUD_H + 30.0, H - 80.0)
	var spr := Sprite2D.new()
	spr.texture = baobab_sprite_tex
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(0.5, 0.5)
	spr.z_index = 8
	add_child(spr)
	baobabs.append({
		"pos": Vector2(W + 40, y),
		"growth": 0.5,
		"max_size": randf_range(2.0, 3.5),
		"sprite": spr,
	})

func _spawn_tiny_planet() -> void:
	var y := randf_range(HUD_H + 20.0, H - 100.0)
	var spr := Sprite2D.new()
	spr.texture = planet_sprite_tex
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(1.5, 1.5)
	spr.z_index = 2
	spr.modulate = Color(1, 1, 1, 0.4)  # Semi-transparent background element
	add_child(spr)
	tiny_planets.append({
		"pos": Vector2(W + 30, y),
		"speed": randf_range(15.0, 35.0),
		"sprite": spr,
	})

func _spawn_rose() -> void:
	var y := randf_range(HUD_H + 30.0, H - 80.0)
	var spr := Sprite2D.new()
	spr.texture = rose_sprite_tex
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(3.0, 3.0)
	spr.z_index = 16
	add_child(spr)
	collectibles.append({
		"pos": Vector2(W + 30, y),
		"speed": randf_range(80.0, 120.0),
		"type": "rose",
		"score_val": 200,
		"bob_offset": randf() * TAU,
		"sprite": spr,
	})

# ─── Spawning ───

func _spawn_meteor() -> void:
	var y := randf_range(HUD_H + 10.0, H - 30.0)
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

	if meteor_storm:
		spd *= 1.5

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

	var y := randf_range(HUD_H + 15.0, H - 40.0)
	var spr := Sprite2D.new()
	spr.texture = item_sprites[chosen.type]
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(3.0, 3.0)
	if chosen.type == "golden_star":
		spr.scale = Vector2(3.5, 3.5)
	elif chosen.type == "slowmo":
		spr.scale = Vector2(3.0, 3.0)
		spr.modulate = Color(0.7, 0.4, 1.0)  # Purple tint for slow-mo
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
	var pcol: Color = _item_particle_colors.get(type, Color(1.0, 1.0, 1.0, 0.7))

	# Handle power-ups (no combo, distinct sounds)
	if type == "shield":
		shield_active = true
		shield_timer = 12.0
		_play_sfx("shield_activate")
		_spawn_popup("SHIELD!", sheep_pos + Vector2(20, -25), Color(0.3, 1.0, 1.0))
		_spawn_ring_particles(sheep_pos, 12, pcol, 30.0)
		screen_flash = 0.15
		screen_flash_color = Color(0.3, 0.8, 1.0)
		return
	if type == "magnet":
		magnet_active = true
		magnet_timer = 10.0
		_play_sfx("magnet_activate")
		_spawn_popup("MAGNET!", sheep_pos + Vector2(20, -25), Color(1.0, 0.4, 0.4))
		_spawn_ring_particles(sheep_pos, 12, pcol, 30.0)
		screen_flash = 0.15
		screen_flash_color = Color(1.0, 0.4, 0.6)
		return
	if type == "slowmo":
		slowmo_active = true
		slowmo_timer = 6.0
		_play_sfx("slowmo_activate")
		_spawn_popup("SLOW-MO!", sheep_pos + Vector2(20, -25), Color(0.7, 0.4, 1.0))
		_spawn_ring_particles(sheep_pos, 12, pcol, 30.0)
		screen_flash = 0.2
		screen_flash_color = Color(0.5, 0.2, 1.0)
		return

	# Combo
	combo_count += 1
	combo_timer = COMBO_WINDOW

	# Combo milestone sounds
	if combo_count >= 10 and _last_combo_milestone < 10:
		_last_combo_milestone = 10
		_play_sfx2("combo_mega")
		screen_flash = 0.2
		screen_flash_color = Color(1.0, 0.3, 1.0)
	elif combo_count >= 5 and _last_combo_milestone < 5:
		_last_combo_milestone = 5
		_play_sfx2("combo_big")
		screen_flash = 0.15
		screen_flash_color = Color(1.0, 0.8, 0.0)
	elif combo_count >= 3 and _last_combo_milestone < 3:
		_last_combo_milestone = 3
		_play_sfx2("combo_start")

	var mult := 1.0
	if combo_count >= 10:
		mult = 3.0
	elif combo_count >= 5:
		mult = 2.0
	elif combo_count >= 3:
		mult = 1.5

	var final_score := int(float(score_val) * mult)
	score += final_score

	if collected_tally.has(type):
		collected_tally[type] += 1
	else:
		collected_tally[type] = 1

	if type == "rose":
		rose_collected = true
		if lives < MAX_LIVES:
			lives += 1
		# Rose grants temporary sparkle invincibility
		invincible = maxf(invincible, 3.0)
		_play_sfx("collect_rose")
		_spawn_popup("+%d  The Rose!" % final_score, sheep_pos + Vector2(20, -25), Color(1.0, 0.3, 0.5))
		_spawn_ring_particles(sheep_pos, 20, Color(1.0, 0.3, 0.4, 0.9), 30.0)
		_spawn_particles(sheep_pos, 25, Color(1.0, 0.5, 0.6, 0.8), 150.0)
		shake_intensity = 3.0
		screen_flash = 0.5
		screen_flash_color = Color(1.0, 0.4, 0.5)
		# Show a Little Prince quote
		var quote: String = _lp_quotes[randi() % _lp_quotes.size()]
		_spawn_popup(quote, Vector2(W * 0.3, H * 0.3), Color(1.0, 0.8, 0.8))
		return

	if type == "golden_star":
		if lives < MAX_LIVES:
			lives += 1
		_play_sfx("collect_star")
		_spawn_popup("+%d  +1UP" % final_score, sheep_pos + Vector2(20, -25), Color(1.0, 0.9, 0.2))
		_spawn_particles(sheep_pos, 20, pcol, 140.0)
		_spawn_ring_particles(sheep_pos, 16, Color(1.0, 0.95, 0.5, 0.8), 25.0)
		shake_intensity = 3.0
		screen_flash = 0.4
		screen_flash_color = Color(1.0, 0.95, 0.6)
	else:
		_play_sfx("collect_" + type)
		var popup_text := "+%d" % final_score
		if mult > 1.0:
			popup_text += " x%.1f" % mult
		_spawn_popup(popup_text, sheep_pos + Vector2(20, -20), Color(1.0, 1.0, 0.3))
		_spawn_particles(sheep_pos, 8, pcol, 70.0)

# ─── Drawing ───

func _draw() -> void:
	var shake_offset := Vector2.ZERO
	if shake_intensity > 0:
		shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)

	# Background
	draw_rect(Rect2(0, 0, W, H), Color(0.01, 0.01, 0.04))
	for i in range(0, 80):
		var a := 0.015 * (1.0 - float(i) / 80.0)
		draw_rect(Rect2(0, H - 80 + i, W, 1), Color(0.08, 0.04, 0.15, a))

	# Sunset gradient overlay (The Little Prince loved sunsets)
	if sunset_active and sunset_progress > 0:
		var sp := sunset_progress * 0.2
		# Warm orange-pink gradient from bottom
		for i in range(0, int(H * 0.6)):
			var y_frac := float(i) / (H * 0.6)
			var a := sp * (1.0 - y_frac) * 0.6
			var col := Color(0.95, 0.4 + y_frac * 0.3, 0.15 + y_frac * 0.2, a)
			draw_rect(Rect2(0, H - H * 0.6 + i, W, 1), col)
		# Golden sun hint near horizon
		var sun_x := W * 0.7 + sin(play_time * 0.2) * 30.0
		var sun_y := H - 50.0
		draw_circle(Vector2(sun_x, sun_y) + shake_offset, 25.0 * sunset_progress, Color(1.0, 0.85, 0.3, sp * 1.5))
		draw_circle(Vector2(sun_x, sun_y) + shake_offset, 15.0 * sunset_progress, Color(1.0, 0.95, 0.7, sp * 2.0))

	# Slow-mo tint overlay
	if slowmo_active and state == State.PLAYING:
		draw_rect(Rect2(0, 0, W, H), Color(0.15, 0.05, 0.3, 0.12))

	# Stars
	for layer in star_layers:
		for star in layer.stars:
			var col := Color(star.color_r, 0.7, star.color_b, star.bright)
			var p: Vector2 = star.pos + shake_offset
			if star.size <= 1.0:
				draw_rect(Rect2(p.x, p.y, 1, 1), col)
			else:
				draw_rect(Rect2(p.x, p.y, star.size, star.size), col)

	# Shooting stars
	for ss in shooting_stars:
		var alpha := clampf(ss.life / ss.max_life, 0.0, 1.0)
		var head: Vector2 = ss.pos + shake_offset
		var tail: Vector2 = head - ss.vel.normalized() * 30.0 * alpha
		draw_line(head, tail, Color(1.0, 0.95, 0.8, alpha * 0.6), 1.5)
		draw_circle(head, 1.5, Color(1.0, 1.0, 0.9, alpha * 0.8))

	# Nebula wisps
	if state == State.PLAYING or state == State.TITLE:
		var t := play_time if state == State.PLAYING else Time.get_ticks_msec() / 1000.0
		for i in 7:
			var nx := fmod(600.0 + i * 200.0 - t * 8.0, W + 200.0) - 100.0
			var ny := 80.0 + i * 95.0 + sin(t * 0.3 + i) * 30.0
			var r := 35.0 + sin(t * 0.2 + i * 2.0) * 12.0
			var nebula_r := 0.12 + sin(i * 1.3) * 0.05
			var nebula_g := 0.06 + cos(i * 0.9) * 0.03
			var nebula_b := 0.2 + sin(i * 0.7) * 0.08
			draw_circle(Vector2(nx, ny) + shake_offset, r, Color(nebula_r, nebula_g, nebula_b, 0.04))
			draw_circle(Vector2(nx + 15, ny - 8) + shake_offset, r * 0.65, Color(nebula_r * 0.7, nebula_g, nebula_b * 1.2, 0.03))

	# Stardust trails (left behind by destroyed meteors)
	for sd in stardust_points:
		var sd_alpha := clampf(sd.life / 6.0, 0.0, 1.0)
		var sd_pulse := 0.5 + sin(play_time * 3.0 + sd.pos.x * 0.05) * 0.5
		var sd_b: float = sd.brightness
		draw_circle(sd.pos + shake_offset, 1.0 + sd_b * 1.5, Color(0.8, 0.85, 1.0, sd_alpha * sd_b * sd_pulse))
		if sd_b > 0.5:
			draw_circle(sd.pos + shake_offset, 0.5 + sd_b, Color(1.0, 0.95, 0.9, sd_alpha * 0.3 * sd_pulse))

	# Ghost sheep (faint translucent echoes drifting through space)
	for gs in ghost_sheep:
		var gs_alpha := 0.0
		var gs_life_frac: float = gs.life / gs.max_life
		if gs_life_frac > 0.85:
			gs_alpha = (1.0 - gs_life_frac) / 0.15
		elif gs_life_frac < 0.15:
			gs_alpha = gs_life_frac / 0.15
		else:
			gs_alpha = 1.0
		gs_alpha *= 0.12  # Very faint
		var gp: Vector2 = gs.pos + shake_offset
		# Draw ghostly sheep silhouette
		draw_texture_rect(sheep_frames[gs.frame], Rect2(gp.x - 18, gp.y - 18, 36, 36), false, Color(0.7, 0.75, 1.0, gs_alpha))

	# Whisper words (single words fading through space)
	if state == State.PLAYING:
		var wfont := _hud_font
		for ww in whisper_words:
			var ww_alpha := 0.0
			var ww_frac: float = ww.life / ww.max_life
			if ww_frac > 0.8:
				ww_alpha = (1.0 - ww_frac) / 0.2
			elif ww_frac < 0.2:
				ww_alpha = ww_frac / 0.2
			else:
				ww_alpha = 1.0
			ww_alpha *= 0.08  # Very subtle
			draw_string(wfont, ww.pos + shake_offset, ww.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.55, 0.8, ww_alpha))

	# Memory fragments (diary entries drifting through the void)
	if state == State.PLAYING:
		var mfont := _hud_font
		for mf in memory_fragments:
			var mf_alpha := 0.0
			var mf_frac: float = mf.life / mf.max_life
			if mf_frac > 0.85:
				mf_alpha = (1.0 - mf_frac) / 0.15
			elif mf_frac < 0.15:
				mf_alpha = mf_frac / 0.15
			else:
				mf_alpha = 1.0
			mf_alpha *= 0.18  # Ethereal presence
			draw_string(mfont, mf.pos + shake_offset, mf.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.75, 0.7, 0.9, mf_alpha))

	# Particles
	for p in particles:
		var alpha := clampf(p.life / p.max_life, 0.0, 1.0)
		var col: Color = p.color
		col.a *= alpha
		var sz: float = p.size * alpha
		draw_circle(p.pos + shake_offset, sz, col)
		# Bright core for larger particles
		if sz > 2.0:
			draw_circle(p.pos + shake_offset, sz * 0.4, Color(col.r, col.g, col.b, col.a * 0.5))

	# Shield bubble
	if shield_active and state == State.PLAYING:
		var pulse := 0.6 + sin(play_time * 5.0) * 0.15
		# Outer glow
		draw_circle(sheep_pos + shake_offset, 40.0, Color(0.2, 0.7, 1.0, pulse * 0.08))
		# Main bubble
		draw_circle(sheep_pos + shake_offset, 35.0, Color(0.3, 0.85, 1.0, pulse * 0.2))
		# Rotating hex segments
		for i in 6:
			var angle := play_time * 2.0 + i * TAU / 6.0
			var seg_start := angle - 0.3
			var seg_end := angle + 0.3
			draw_arc(sheep_pos + shake_offset, 35.0, seg_start, seg_end, 8, Color(0.5, 0.95, 1.0, pulse * 0.6), 2.0)
		# Inner shimmer line
		draw_arc(sheep_pos + shake_offset, 28.0, play_time * 3.0, play_time * 3.0 + 1.0, 12, Color(0.7, 1.0, 1.0, pulse * 0.3), 1.0)
		# Expiry warning
		if shield_timer < 3.0:
			if int(shield_timer * 4) % 2 == 0:
				draw_arc(sheep_pos + shake_offset, 38.0, 0, TAU, 32, Color(1.0, 0.3, 0.3, 0.5), 1.5)

	# Shield hit flash (expanding ring)
	if shield_hit_flash > 0:
		var ring_r := 35.0 + (0.4 - shield_hit_flash) * 80.0
		var ring_a := shield_hit_flash * 2.0
		draw_arc(sheep_pos + shake_offset, ring_r, 0, TAU, 32, Color(0.5, 1.0, 1.0, ring_a), 2.5)

	# Magnet field
	if magnet_active and state == State.PLAYING:
		var mag_alpha := 0.08 + sin(play_time * 3.0) * 0.04
		# Outer range ring
		draw_arc(sheep_pos + shake_offset, MAGNET_RADIUS, 0, TAU, 48, Color(1.0, 0.4, 0.6, mag_alpha * 1.5), 1.0)
		# Pulsing inner rings
		for ring_i in 3:
			var ring_r := 40.0 + fmod(play_time * 80.0 + ring_i * 50.0, MAGNET_RADIUS - 40.0)
			var ring_alpha := mag_alpha * (1.0 - ring_r / MAGNET_RADIUS)
			draw_arc(sheep_pos + shake_offset, ring_r, 0, TAU, 24, Color(1.0, 0.5, 0.7, ring_alpha), 0.5)
		# Rotating field lines
		for i in 8:
			var angle := play_time * 2.0 + i * TAU / 8.0
			var inner := sheep_pos + Vector2(cos(angle), sin(angle)) * 25.0
			var outer := sheep_pos + Vector2(cos(angle), sin(angle)) * MAGNET_RADIUS * 0.8
			draw_line(inner + shake_offset, outer + shake_offset, Color(1.0, 0.5, 0.7, mag_alpha * 2), 0.8)
		# Expiry warning
		if magnet_timer < 3.0 and int(magnet_timer * 3) % 2 == 0:
			draw_arc(sheep_pos + shake_offset, MAGNET_RADIUS, 0, TAU, 32, Color(1.0, 0.2, 0.2, 0.3), 1.0)

	# Slow-mo visual effect — time distortion rings
	if slowmo_active and state == State.PLAYING:
		for i in 3:
			var r := 50.0 + fmod(play_time * 30.0 + i * 40.0, 120.0)
			var a := 0.1 * (1.0 - r / 170.0)
			draw_arc(sheep_pos + shake_offset, r, 0, TAU, 32, Color(0.6, 0.3, 1.0, a), 1.0)

	# Sound wave projectiles
	for sw in sound_waves:
		var alpha := clampf(sw.life / sw.max_life, 0.0, 1.0)
		var p: float = sw.power
		var center: Vector2 = sw.pos + shake_offset
		# Multiple concentric expanding rings
		for ring_i in 4:
			var ring_offset := ring_i * 8.0
			var r: float = sw.radius - ring_offset
			if r < 3.0:
				continue
			var ring_alpha := alpha * (1.0 - float(ring_i) / 4.0) * (0.4 + p * 0.3)
			var col := Color(0.3 + p * 0.5, 0.7 + p * 0.2, 1.0, ring_alpha)
			# Draw arcs (sonic wave shape — forward-facing crescents)
			draw_arc(center, r, -0.8 - p * 0.3, 0.8 + p * 0.3, 16, col, 1.5 + p * 1.5)
		# Bright core ring
		draw_arc(center, sw.radius * 0.5, -0.6, 0.6, 12, Color(0.7, 0.95, 1.0, alpha * 0.6 * p), 1.0)
		# Leading edge glow
		var front := center + Vector2(sw.radius * 0.3, 0)
		draw_circle(front, 3.0 + p * 4.0, Color(0.5, 0.9, 1.0, alpha * 0.3))

	# Charge indicator (while charging)
	if wave_charging and state == State.PLAYING:
		var charge_r := 22.0 + wave_charge * 18.0
		var charge_a := 0.15 + wave_charge * 0.3
		# Pulsing charge ring
		draw_arc(sheep_pos + shake_offset, charge_r, -PI * 0.5, -PI * 0.5 + TAU * wave_charge, 24, Color(0.4 + wave_charge * 0.6, 0.85, 1.0, charge_a), 2.0)
		# Inner glow
		draw_circle(sheep_pos + shake_offset + Vector2(15, 0), 5.0 + wave_charge * 8.0, Color(0.5, 0.9, 1.0, charge_a * 0.4))

	# Cooldown indicator (small arc below sheep)
	if wave_cooldown > 0 and state == State.PLAYING:
		var cd_frac := wave_cooldown / WAVE_COOLDOWN
		draw_arc(sheep_pos + shake_offset + Vector2(0, 25), 10.0, 0, TAU * cd_frac, 12, Color(0.5, 0.5, 0.7, 0.3), 1.5)

	# Collectible glow effects
	if state == State.PLAYING:
		for c in collectibles:
			var glow_pos: Vector2 = c.pos + shake_offset
			match c.type:
				"golden_star":
					var glow_r := 14.0 + sin(play_time * 4.0) * 5.0
					draw_circle(glow_pos, glow_r, Color(1.0, 0.9, 0.3, 0.15))
					draw_circle(glow_pos, glow_r * 0.5, Color(1.0, 1.0, 0.6, 0.1))
					# Rotating sparkles
					for i in 4:
						var a := play_time * 3.0 + i * TAU / 4.0
						var sp := glow_pos + Vector2(cos(a), sin(a)) * glow_r
						draw_circle(sp, 1.5, Color(1.0, 1.0, 0.8, 0.4))
				"shield":
					var glow_r := 10.0 + sin(play_time * 3.0) * 3.0
					draw_circle(glow_pos, glow_r, Color(0.3, 0.9, 1.0, 0.1))
				"magnet":
					var glow_r := 10.0 + sin(play_time * 3.5) * 3.0
					draw_circle(glow_pos, glow_r, Color(1.0, 0.3, 0.5, 0.1))
				"slowmo":
					var glow_r := 10.0 + sin(play_time * 2.5) * 3.0
					draw_circle(glow_pos, glow_r, Color(0.6, 0.3, 1.0, 0.1))
				"music_note":
					draw_circle(glow_pos, 8.0, Color(1.0, 0.85, 0.1, 0.06))
				"rose":
					# Rose has a special dreamy glow
					var rose_r := 18.0 + sin(play_time * 3.0) * 5.0
					draw_circle(glow_pos, rose_r, Color(1.0, 0.3, 0.4, 0.12))
					draw_circle(glow_pos, rose_r * 0.6, Color(1.0, 0.5, 0.6, 0.08))
					# Petal-like sparkles orbit
					for pi in 5:
						var pa := play_time * 2.0 + pi * TAU / 5.0
						var pp := glow_pos + Vector2(cos(pa), sin(pa)) * rose_r * 0.8
						draw_circle(pp, 1.0, Color(1.0, 0.5, 0.6, 0.3))

	# Fox companion glow
	if fox_active and fox_sprite and is_instance_valid(fox_sprite):
		var fox_glow := 0.08 + sin(play_time * 4.0) * 0.04
		draw_circle(fox_pos + shake_offset, FOX_MAGNET_RADIUS, Color(1.0, 0.7, 0.2, fox_glow * 0.4))
		draw_arc(fox_pos + shake_offset, FOX_MAGNET_RADIUS, 0, TAU, 48, Color(1.0, 0.75, 0.3, fox_glow), 0.8)
		# Heart trail
		draw_circle(fox_pos + shake_offset, 8.0, Color(1.0, 0.6, 0.2, 0.15))

	# Baobab danger indicators
	for b in baobabs:
		if b.growth > 1.0:
			var danger_a: float = (b.growth - 1.0) / (b.max_size - 1.0) * 0.1
			draw_circle(b.pos + shake_offset, b.growth * 10.0, Color(0.4, 0.2, 0.1, danger_a))
			if b.growth > 1.5:
				# Warning ring when it can damage
				draw_arc(b.pos + shake_offset, b.growth * 8.0 + sheep_hitbox, 0, TAU, 24, Color(1.0, 0.3, 0.1, 0.15), 1.0)

	# Meteor storm warning
	if meteor_storm and state == State.PLAYING:
		var warn_alpha := 0.06 + sin(play_time * 6.0) * 0.05
		draw_rect(Rect2(0, 0, W, 4), Color(1.0, 0.15, 0.1, warn_alpha * 4))
		draw_rect(Rect2(0, H - 4, W, 4), Color(1.0, 0.15, 0.1, warn_alpha * 4))
		# Side warning bars
		draw_rect(Rect2(0, 0, 3, H), Color(1.0, 0.2, 0.1, warn_alpha * 2))
		draw_rect(Rect2(W - 3, 0, 3, H), Color(1.0, 0.2, 0.1, warn_alpha * 2))

	# CRT scanlines
	for y in range(0, int(H), 2):
		draw_line(Vector2(0, y), Vector2(W, y), Color(0, 0, 0, 0.06))

	# Neon borders
	draw_rect(Rect2(0, 0, W, 2), Color(0.6, 0.2, 0.8, 0.3))
	draw_rect(Rect2(0, H - 3, W, 3), Color(0.0, 0.8, 0.6, 0.25))

	# Speed bar
	if state == State.PLAYING:
		var bar_h := clampf((speed_mult - 1.0) / 4.0, 0.0, 1.0) * (H - 80)
		draw_rect(Rect2(3, H - 40 - bar_h, 4, bar_h), Color(1.0, 0.3, 0.6, 0.4))

	# Damage red vignette
	if damage_flash > 0:
		var da := damage_flash * 0.4
		# Top/bottom red bars
		draw_rect(Rect2(0, 0, W, 40), Color(1.0, 0.0, 0.0, da))
		draw_rect(Rect2(0, H - 40, W, 40), Color(1.0, 0.0, 0.0, da))
		# Side red bars
		draw_rect(Rect2(0, 0, 40, H), Color(1.0, 0.0, 0.0, da * 0.7))
		draw_rect(Rect2(W - 40, 0, 40, H), Color(1.0, 0.0, 0.0, da * 0.7))

	# Screen flash overlay
	if screen_flash > 0:
		draw_rect(Rect2(0, 0, W, H), Color(screen_flash_color.r, screen_flash_color.g, screen_flash_color.b, screen_flash * 0.5))

	# HUD Panel (drawn last, on top of everything)
	if state == State.PLAYING or state == State.GAMEOVER:
		_draw_hud_panel()

# ─── HUD Panel (retro Mega Drive style) ───

func _draw_hud_panel() -> void:
	var ph := HUD_H
	var font := _hud_font
	var t := play_time

	# ── Panel background ──
	draw_rect(Rect2(0, 0, W, ph), Color(0.03, 0.025, 0.07, 0.96))

	# Beveled border — metallic 3D look
	draw_rect(Rect2(0, 0, W, 2), Color(0.5, 0.45, 0.6, 0.8))
	draw_rect(Rect2(0, 2, W, 1), Color(0.3, 0.27, 0.4, 0.6))
	draw_rect(Rect2(0, ph - 2, W, 2), Color(0.1, 0.08, 0.15, 0.9))
	# Neon accent at bottom
	draw_rect(Rect2(0, ph - 3, W, 1), Color(0.35, 0.15, 0.65, 0.45))

	# Corner rivets
	for cx in [12.0, W - 12.0]:
		for cy in [12.0, ph - 12.0]:
			draw_circle(Vector2(cx, cy), 3.5, Color(0.35, 0.3, 0.4, 0.5))
			draw_circle(Vector2(cx, cy), 1.8, Color(0.6, 0.55, 0.65, 0.4))

	# ── Section separators ──
	var sep1 := 240.0
	var sep2 := 600.0
	var sep3 := 920.0
	for sx in [sep1, sep2, sep3]:
		draw_rect(Rect2(sx, 5, 1, ph - 10), Color(0.35, 0.3, 0.45, 0.5))
		draw_rect(Rect2(sx + 1, 5, 1, ph - 10), Color(0.08, 0.06, 0.12, 0.5))

	# ═══════════════════════════════════════════
	# SECTION 1: Lives & Wave (0..sep1)
	# ═══════════════════════════════════════════
	draw_string(font, Vector2(24, 20), "LIVES", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.5, 0.75, 0.8))
	for i in MAX_LIVES:
		var hx := 24.0 + i * 28.0
		var hy := 28.0
		if i < lives:
			draw_texture_rect(heart_full_tex, Rect2(hx, hy, 24, 24), false, Color.WHITE)
		else:
			draw_texture_rect(heart_empty_tex, Rect2(hx, hy, 24, 24), false, Color(0.3, 0.3, 0.4, 0.4))

	# Wave number
	draw_string(font, Vector2(175, 20), "WAVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.5, 0.75, 0.7))
	draw_string(font, Vector2(175, 42), "%d" % wave, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.85, 0.3, 1.0))

	# Combo
	if combo_count >= 2:
		var pulse := 0.5 + sin(t * 8.0) * 0.5
		var combo_col := Color(1.0, 0.5 + pulse * 0.3, 0.15, 1.0)
		if combo_count >= 10:
			combo_col = Color(1.0, 0.3 + pulse * 0.3, 1.0, 1.0)
		elif combo_count >= 5:
			combo_col = Color(1.0, 0.8 + pulse * 0.2, 0.1, 1.0)
		draw_string(font, Vector2(24, 58), "COMBO x%d" % combo_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, combo_col)

	# ═══════════════════════════════════════════
	# SECTION 2: Score & stats (sep1..sep2)
	# ═══════════════════════════════════════════
	draw_string(font, Vector2(sep1 + 16, 18), "SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.45, 0.65, 0.7))
	draw_string(font, Vector2(sep1 + 16, 40), "%d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.1, 1.0, 0.8, 1.0))
	draw_string(font, Vector2(sep1 + 16, 58), "HI %d" % high_score, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.75, 0.55, 0.2, 0.6))

	var mins := int(t) / 60
	var secs := int(t) % 60
	draw_string(font, Vector2(sep2 - 16, 20), "%dm" % int(distance), HORIZONTAL_ALIGNMENT_RIGHT, -1, 15, Color(0.6, 0.5, 0.85, 0.9))
	draw_string(font, Vector2(sep2 - 16, 40), "%d:%02d" % [mins, secs], HORIZONTAL_ALIGNMENT_RIGHT, -1, 15, Color(1.0, 0.85, 0.3, 0.8))
	if meteors_destroyed > 0:
		draw_string(font, Vector2(sep2 - 16, 58), "KILLS %d" % meteors_destroyed, HORIZONTAL_ALIGNMENT_RIGHT, -1, 13, Color(1.0, 0.5, 0.3, 0.7))

	# ═══════════════════════════════════════════
	# SECTION 3: Power-ups (sep2..sep3)
	# ═══════════════════════════════════════════
	var pu_x := sep2 + 16.0
	var pu_y := 6.0
	var bar_total := 90.0
	var bar_h := 10.0
	var any_pu := false

	if shield_active:
		any_pu = true
		var bar_w := bar_total * clampf(shield_timer / 12.0, 0.0, 1.0)
		draw_string(font, Vector2(pu_x, pu_y + 14), "SHIELD", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.4, 0.9, 1.0, 0.9))
		draw_rect(Rect2(pu_x + 65, pu_y + 4, bar_total, bar_h), Color(0.12, 0.1, 0.18, 0.6))
		draw_rect(Rect2(pu_x + 65, pu_y + 4, bar_w, bar_h), Color(0.3, 0.85, 1.0, 0.85))
		if shield_timer < 3.0 and int(shield_timer * 4) % 2 == 0:
			draw_rect(Rect2(pu_x + 65, pu_y + 4, bar_w, bar_h), Color(1.0, 0.3, 0.3, 0.4))
		draw_string(font, Vector2(pu_x + 160, pu_y + 14), "%.0fs" % shield_timer, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.4, 0.9, 1.0, 0.8))
		pu_y += 18.0

	if magnet_active:
		any_pu = true
		var bar_w := bar_total * clampf(magnet_timer / 10.0, 0.0, 1.0)
		draw_string(font, Vector2(pu_x, pu_y + 14), "MAGNET", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.4, 0.6, 0.9))
		draw_rect(Rect2(pu_x + 65, pu_y + 4, bar_total, bar_h), Color(0.12, 0.1, 0.18, 0.6))
		draw_rect(Rect2(pu_x + 65, pu_y + 4, bar_w, bar_h), Color(1.0, 0.4, 0.6, 0.85))
		draw_string(font, Vector2(pu_x + 160, pu_y + 14), "%.0fs" % magnet_timer, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.5, 0.7, 0.8))
		pu_y += 18.0

	if slowmo_active:
		any_pu = true
		var bar_w := bar_total * clampf(slowmo_timer / 6.0, 0.0, 1.0)
		draw_string(font, Vector2(pu_x, pu_y + 14), "SLOW-MO", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.3, 1.0, 0.9))
		draw_rect(Rect2(pu_x + 65, pu_y + 4, bar_total, bar_h), Color(0.12, 0.1, 0.18, 0.6))
		draw_rect(Rect2(pu_x + 65, pu_y + 4, bar_w, bar_h), Color(0.6, 0.3, 1.0, 0.85))
		draw_string(font, Vector2(pu_x + 160, pu_y + 14), "%.0fs" % slowmo_timer, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 0.4, 1.0, 0.8))
		pu_y += 18.0

	if fox_active:
		any_pu = true
		var fox_bar := bar_total * clampf(fox_timer / FOX_DURATION, 0.0, 1.0)
		draw_string(font, Vector2(pu_x, pu_y + 14), "FOX", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.7, 0.2, 0.9))
		draw_rect(Rect2(pu_x + 65, pu_y + 4, bar_total, bar_h), Color(0.12, 0.1, 0.18, 0.6))
		draw_rect(Rect2(pu_x + 65, pu_y + 4, fox_bar, bar_h), Color(1.0, 0.7, 0.2, 0.85))

	if not any_pu:
		draw_string(font, Vector2(pu_x, 38), "no power-ups", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.3, 0.28, 0.4, 0.35))

	# ═══════════════════════════════════════════
	# SECTION 4: Weapon (sep3..W)
	# ═══════════════════════════════════════════
	var wp_x := sep3 + 16.0
	draw_string(font, Vector2(wp_x, 18), "SOUND WAVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.5, 0.7, 0.9, 0.7))

	if wave_charging:
		var charge_pct := int(wave_charge * 100)
		var bar_w := 140.0 * wave_charge
		draw_rect(Rect2(wp_x, 24, 140, 14), Color(0.12, 0.1, 0.18, 0.6))
		var charge_col := Color(0.3 + wave_charge * 0.7, 0.7 + wave_charge * 0.2, 1.0, 0.9)
		draw_rect(Rect2(wp_x, 24, bar_w, 14), charge_col)
		if bar_w > 3:
			draw_rect(Rect2(wp_x + bar_w - 2, 24, 2, 14), Color(1.0, 1.0, 1.0, 0.5))
		draw_string(font, Vector2(wp_x + 148, 38), "CHG %d%%" % charge_pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, charge_col)
	elif wave_cooldown > 0:
		var cd_frac := wave_cooldown / WAVE_COOLDOWN
		draw_rect(Rect2(wp_x, 24, 140, 14), Color(0.12, 0.1, 0.18, 0.6))
		draw_rect(Rect2(wp_x, 24, 140 * cd_frac, 14), Color(0.35, 0.3, 0.45, 0.5))
		draw_string(font, Vector2(wp_x + 148, 38), "WAIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.45, 0.4, 0.55, 0.6))
	else:
		var rp := 0.7 + sin(t * 4.0) * 0.3
		draw_rect(Rect2(wp_x, 24, 140, 14), Color(0.08, 0.35 * rp, 0.15 * rp, 0.35))
		draw_string(font, Vector2(wp_x + 148, 38), "READY", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.3, 1.0, 0.6, rp))

	# Storm / status line
	if meteor_storm:
		var wp2 := 0.5 + sin(t * 6.0) * 0.5
		draw_string(font, Vector2(wp_x, 58), "!! STORM !!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.2, 0.1, wp2))

# ─── Audio: FM Synth Melody ───

var _melody: Array[float] = [
	440.0, 523.25, 587.33, 659.25, 784.0,
	659.25, 587.33, 523.25, 440.0, 392.0,
	349.23, 392.0, 440.0, 523.25, 587.33,
	523.25, 440.0, 392.0, 349.23, 329.63,
]

var _bass_notes: Array[float] = [
	110.0, 110.0, 87.31, 87.31,
	130.81, 130.81, 98.0, 98.0,
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
		var mod_idx := 3.5 + sin(TAU * 0.3 * t) * 1.0
		var mod := sin(TAU * freq * 1.0 * t)
		var carrier := sin(TAU * freq * t + mod_idx * mod)
		var carrier2 := sin(TAU * freq * 1.003 * t + mod_idx * 0.7 * mod)
		var value := (carrier * 0.25 + carrier2 * 0.12)
		var beat_pos := fmod(t, BEAT_INTERVAL)
		var env := clampf(1.0 - beat_pos / (BEAT_INTERVAL * 0.7), 0.0, 1.0)
		env *= env
		value *= env
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
		var mod := sin(TAU * freq * 2.0 * t)
		var value := sin(TAU * freq * t + 2.5 * mod) * 0.4
		value += sin(TAU * freq * 2.0 * t) * 0.15
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
		var beat_in_bar := _beat_count % 4
		if beat_in_bar == 0 or beat_in_bar == 2:
			if beat_pos < 0.08:
				var kick_freq := 120.0 - beat_pos * 800.0
				var env := clampf(1.0 - beat_pos / 0.08, 0.0, 1.0)
				value += sin(TAU * kick_freq * beat_pos) * env * 0.4
		if beat_in_bar == 1 or beat_in_bar == 3:
			if beat_pos < 0.06:
				var env := clampf(1.0 - beat_pos / 0.06, 0.0, 1.0)
				value += (randf() * 2.0 - 1.0) * env * 0.2
				value += sin(TAU * 200.0 * beat_pos) * env * 0.1
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
			value = _synth_sfx(t, _sfx_type)
			if not _sfx_playing:
				pass  # ended inside _synth_sfx
			_sfx_time += 1.0 / sr
		pb.push_frame(Vector2(value, value))

func _fill_sfx2_buffer() -> void:
	if not sfx_player2.playing:
		return
	var pb := sfx_player2.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var frames := pb.get_frames_available()
	if frames <= 0:
		return
	var sr := 22050.0
	for i in frames:
		var value := 0.0
		if _sfx2_playing:
			var t := _sfx2_time
			value = _synth_sfx2(t, _sfx2_type)
			_sfx2_time += 1.0 / sr
		pb.push_frame(Vector2(value, value))

func _synth_sfx(t: float, type: String) -> float:
	var value := 0.0
	match type:
		"collect_salvage":
			# Metallic ping — resonant hit on steel plate
			var freq := 1200.0 + sin(t * 40.0) * 200.0
			var env := clampf(1.0 - t / 0.12, 0.0, 1.0)
			value = sin(TAU * freq * t) * env * 0.3
			value += sin(TAU * 1800.0 * t) * env * 0.1  # Harmonic overtone
			if t > 0.12: _sfx_playing = false
		"collect_cassette":
			# Tape rewind — rising sweep with click
			var freq := 350.0 + t * 2500.0
			var env := clampf(1.0 - t / 0.18, 0.0, 1.0)
			value = sin(TAU * freq * t) * env * 0.25
			if t < 0.015: value += 0.35  # Mechanical click
			value += sin(TAU * freq * 0.5 * t) * env * 0.08  # Sub harmonic
			if t > 0.18: _sfx_playing = false
		"collect_wool":
			# Soft puff — gentle filtered noise with warm tone
			var env := clampf(1.0 - t / 0.15, 0.0, 1.0)
			env = env * env  # Smoother falloff
			value = (randf() * 2.0 - 1.0) * env * 0.12
			value += sin(TAU * 280.0 * t) * env * 0.08
			value += sin(TAU * 420.0 * t) * env * 0.04  # Breathy overtone
			if t > 0.15: _sfx_playing = false
		"collect_debris":
			# Metallic clank — two resonant frequencies + noise burst
			var env := clampf(1.0 - t / 0.1, 0.0, 1.0)
			value = sin(TAU * 750.0 * t) * env * 0.25
			value += sin(TAU * 1150.0 * t) * env * 0.15
			value += sin(TAU * 1600.0 * t) * env * 0.05  # High harmonic
			if t < 0.02: value += (randf() * 2.0 - 1.0) * 0.15  # Impact noise
			if t > 0.1: _sfx_playing = false
		"collect_headphones":
			# Ascending arpeggio — musical and distinct
			var env := clampf(1.0 - t / 0.3, 0.0, 1.0)
			var freq := 440.0
			if t < 0.08: freq = 440.0
			elif t < 0.16: freq = 554.37
			elif t < 0.24: freq = 659.25
			else: freq = 880.0
			value = sin(TAU * freq * t) * env * 0.25
			value += sin(TAU * freq * 2.0 * t) * env * 0.06  # Octave shimmer
			if t > 0.3: _sfx_playing = false
		"collect_music_note":
			# Pure bell chime — long sustain, harmonics
			var env := clampf(1.0 - t / 0.6, 0.0, 1.0)
			env *= env
			value = sin(TAU * 880.0 * t) * env * 0.2
			value += sin(TAU * 1760.0 * t) * env * 0.1
			value += sin(TAU * 1318.5 * t) * env * 0.08
			value += sin(TAU * 2640.0 * t) * env * 0.04  # High bell overtone
			# Gentle tremolo
			value *= 0.85 + sin(TAU * 6.0 * t) * 0.15
			if t > 0.6: _sfx_playing = false
		"collect_star":
			# Magical sparkle cascade — ethereal ascending with shimmer
			var env := clampf(1.0 - t / 1.0, 0.0, 1.0)
			env *= env
			var base_freq := 880.0 + t * 500.0
			value = sin(TAU * base_freq * t) * env * 0.18
			value += sin(TAU * base_freq * 1.5 * t) * env * 0.12  # Perfect fifth
			value += sin(TAU * base_freq * 2.0 * t) * env * 0.06  # Octave
			value += sin(TAU * base_freq * 3.0 * t) * env * 0.03  # High harmonic
			# Shimmer (amplitude modulated high freq)
			value += sin(TAU * 4000.0 * t) * env * 0.03 * sin(t * 25.0)
			# Sparkle bursts
			if fmod(t, 0.15) < 0.02:
				value += sin(TAU * 3500.0 * t) * env * 0.08
			if t > 1.0: _sfx_playing = false
		"collect_rose":
			# Romantic dreamy harp — delicate and beautiful
			var env := clampf(1.0 - t / 1.2, 0.0, 1.0)
			env = sqrt(env)  # Gentle decay
			# Harp-like ascending notes
			var note_t := fmod(t, 0.2)
			var note_idx := int(t / 0.2) % 5
			var freqs := [523.25, 659.25, 784.0, 987.77, 1174.66]  # C5 E5 G5 B5 D6
			var freq: float = freqs[note_idx]
			var note_env := clampf(1.0 - note_t / 0.18, 0.0, 1.0) * env
			value = sin(TAU * freq * t) * note_env * 0.18
			value += sin(TAU * freq * 2.0 * t) * note_env * 0.06
			# Warm pad underneath
			value += sin(TAU * 261.6 * t) * env * 0.06  # C4
			value += sin(TAU * 329.6 * t) * env * 0.04  # E4
			if t > 1.2: _sfx_playing = false
		"shield_activate":
			# Energy bubble forming — whoosh up + resonant hum
			var env := clampf(1.0 - t / 0.4, 0.0, 1.0)
			var freq := 200.0 + t * 1200.0
			value = sin(TAU * freq * t) * env * 0.2
			# Resonant hum settling
			value += sin(TAU * 600.0 * t) * env * 0.15 * clampf(t / 0.1, 0.0, 1.0)
			# Bubble pop at start
			if t < 0.03: value += sin(TAU * 2000.0 * t) * 0.2
			if t > 0.4: _sfx_playing = false
		"magnet_activate":
			# Electromagnetic hum — low buzzy rising tone
			var env := clampf(1.0 - t / 0.35, 0.0, 1.0)
			var freq := 150.0 + t * 800.0
			# Square-ish wave for magnetic character
			var raw := sin(TAU * freq * t)
			value = (1.0 if raw > 0 else -1.0) * env * 0.12
			value += sin(TAU * freq * t) * env * 0.12
			# Metallic ring
			value += sin(TAU * 1200.0 * t) * env * 0.06 * sin(t * 20.0)
			if t > 0.35: _sfx_playing = false
		"slowmo_activate":
			# Time warp — descending pitch bend with reverb tail
			var env := clampf(1.0 - t / 0.5, 0.0, 1.0)
			var freq := 1000.0 - t * 600.0
			value = sin(TAU * freq * t) * env * 0.2
			# Detuned copy for chorus
			value += sin(TAU * freq * 1.02 * t) * env * 0.1
			# Sub bass thump
			if t < 0.1:
				value += sin(TAU * 80.0 * t) * (1.0 - t / 0.1) * 0.2
			# Ethereal tail
			value += sin(TAU * 400.0 * t) * env * env * 0.08
			if t > 0.5: _sfx_playing = false
		"shield_break":
			# Glass shatter — noise burst + descending metallic ringing
			var env := clampf(1.0 - t / 0.3, 0.0, 1.0)
			value = (randf() * 2.0 - 1.0) * env * 0.25
			var ring_freq := 1500.0 - t * 1000.0
			value += sin(TAU * ring_freq * t) * env * 0.15
			value += sin(TAU * ring_freq * 1.5 * t) * env * 0.08
			# Tinkling glass fragments
			if fmod(t, 0.04) < 0.01:
				value += sin(TAU * (2000.0 + randf() * 1000.0) * t) * env * 0.1
			if t > 0.3: _sfx_playing = false
		"damage":
			# Harsh impact — distorted buzz + low thud
			var env := clampf(1.0 - t / 0.25, 0.0, 1.0)
			var sq := 1.0 if sin(TAU * 150.0 * t) > 0 else -1.0
			value = sq * env * 0.3
			# Low thud
			if t < 0.06:
				value += sin(TAU * 60.0 * t) * (1.0 - t / 0.06) * 0.3
			# High crunch
			value += (randf() * 2.0 - 1.0) * env * 0.08
			if t > 0.25: _sfx_playing = false
		"sound_blast":
			# Quick sonic pulse — punchy whomp with ring
			var env := clampf(1.0 - t / 0.2, 0.0, 1.0)
			var freq := 300.0 + t * 800.0
			value = sin(TAU * freq * t) * env * 0.3
			# Sub thump
			if t < 0.04:
				value += sin(TAU * 100.0 * t) * (1.0 - t / 0.04) * 0.25
			# Bright ring
			value += sin(TAU * 1200.0 * t) * env * env * 0.1
			if t > 0.2: _sfx_playing = false
		"sound_blast_charged":
			# Powerful charged sonic boom — deep + bright + reverb tail
			var env := clampf(1.0 - t / 0.6, 0.0, 1.0)
			# Initial boom
			if t < 0.08:
				var boom_env := 1.0 - t / 0.08
				value = sin(TAU * 80.0 * t) * boom_env * 0.35
				value += (randf() * 2.0 - 1.0) * boom_env * 0.12
			# Rising sweep
			var freq := 200.0 + t * 1500.0
			value += sin(TAU * freq * t) * env * 0.25
			# Detuned chorus for width
			value += sin(TAU * freq * 1.015 * t) * env * 0.12
			# Bright harmonics
			value += sin(TAU * freq * 2.0 * t) * env * env * 0.08
			# Reverb tail
			if t > 0.3:
				var tail_env := clampf(1.0 - (t - 0.3) / 0.3, 0.0, 1.0)
				value += sin(TAU * 400.0 * t) * tail_env * 0.08
				value += sin(TAU * 600.0 * t) * tail_env * 0.04
			if t > 0.6: _sfx_playing = false
		"gameover":
			# Sad descending wah with tremolo
			var freq := 500.0 - t * 350.0
			var env := clampf(1.0 - t / 1.2, 0.0, 1.0)
			value = sin(TAU * freq * t) * env * 0.35
			value += sin(TAU * freq * 0.5 * t) * env * 0.18
			value *= 0.6 + sin(TAU * 7.0 * t) * 0.4  # Tremolo
			# Low drone underneath
			value += sin(TAU * 55.0 * t) * env * 0.1
			if t > 1.2: _sfx_playing = false
	return value

func _synth_sfx2(t: float, type: String) -> float:
	var value := 0.0
	match type:
		"nearmiss":
			# Quick whoosh past
			var freq := 700.0 + t * 3000.0
			var env := clampf(1.0 - t / 0.1, 0.0, 1.0)
			value = sin(TAU * freq * t) * env * 0.25
			if t > 0.1: _sfx2_playing = false
		"hit_impact":
			# Secondary impact layer — deep thud
			var env := clampf(1.0 - t / 0.15, 0.0, 1.0)
			value = sin(TAU * 80.0 * t) * env * 0.3
			value += sin(TAU * 120.0 * t) * env * 0.15
			if t > 0.15: _sfx2_playing = false
		"wave_start":
			# Fanfare — two rising tones
			var env := clampf(1.0 - t / 0.4, 0.0, 1.0)
			var freq := 440.0
			if t < 0.15: freq = 440.0
			else: freq = 554.37
			value = sin(TAU * freq * t) * env * 0.2
			value += sin(TAU * freq * 1.5 * t) * env * 0.1
			if t > 0.4: _sfx2_playing = false
		"combo_start":
			# Quick chime — encouraging
			var env := clampf(1.0 - t / 0.15, 0.0, 1.0)
			value = sin(TAU * 660.0 * t) * env * 0.2
			value += sin(TAU * 880.0 * t) * env * 0.1
			if t > 0.15: _sfx2_playing = false
		"combo_big":
			# Rising power chord
			var env := clampf(1.0 - t / 0.25, 0.0, 1.0)
			var freq := 660.0 + t * 400.0
			value = sin(TAU * freq * t) * env * 0.2
			value += sin(TAU * freq * 1.5 * t) * env * 0.12
			value += sin(TAU * freq * 2.0 * t) * env * 0.06
			if t > 0.25: _sfx2_playing = false
		"combo_mega":
			# Epic fanfare — full chord with shimmer
			var env := clampf(1.0 - t / 0.4, 0.0, 1.0)
			var freq := 880.0
			value = sin(TAU * freq * t) * env * 0.18
			value += sin(TAU * freq * 1.25 * t) * env * 0.12  # Major third
			value += sin(TAU * freq * 1.5 * t) * env * 0.1   # Fifth
			value += sin(TAU * freq * 2.0 * t) * env * 0.06   # Octave
			value += sin(TAU * 3500.0 * t) * env * 0.03 * sin(t * 20.0)  # Sparkle
			if t > 0.4: _sfx2_playing = false
		"fox_appear":
			# Playful, warm — like a music box
			var env := clampf(1.0 - t / 0.5, 0.0, 1.0)
			var note_t := fmod(t, 0.12)
			var note_i := int(t / 0.12) % 4
			var fox_freqs := [659.25, 784.0, 880.0, 784.0]  # E5 G5 A5 G5
			var freq: float = fox_freqs[note_i]
			var nenv := clampf(1.0 - note_t / 0.1, 0.0, 1.0) * env
			value = sin(TAU * freq * t) * nenv * 0.2
			value += sin(TAU * freq * 0.5 * t) * nenv * 0.08
			if t > 0.5: _sfx2_playing = false
		"meteor_shatter":
			# Crumbling rock + bright ping of destruction
			var env := clampf(1.0 - t / 0.2, 0.0, 1.0)
			# Rocky crumble noise
			value = (randf() * 2.0 - 1.0) * env * 0.15
			# Bright destruction ping
			value += sin(TAU * 1400.0 * t) * env * 0.15
			value += sin(TAU * 900.0 * t) * env * 0.08
			# Low rumble
			if t < 0.06:
				value += sin(TAU * 70.0 * t) * (1.0 - t / 0.06) * 0.2
			if t > 0.2: _sfx2_playing = false
		"shield_expire":
			# Quiet fade-out hum
			var env := clampf(1.0 - t / 0.2, 0.0, 1.0)
			value = sin(TAU * 400.0 * t * (1.0 - t)) * env * 0.15
			if t > 0.2: _sfx2_playing = false
		_:
			_sfx2_playing = false
	return value

func _play_sfx(type: String) -> void:
	_sfx_playing = true
	_sfx_type = type
	_sfx_time = 0.0

func _play_sfx2(type: String) -> void:
	_sfx2_playing = true
	_sfx2_type = type
	_sfx2_time = 0.0
