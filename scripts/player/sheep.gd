extends CharacterBody2D

## Space Sheep — moves through zero-gravity via sound pulses

@export var rotation_speed: float = 3.0
@export var pulse_force: float = 280.0
@export var max_speed: float = 320.0
@export var drag: float = 0.985
@export var charge_rate: float = 2.0
@export var max_charge: float = 3.0
@export var interact_range: float = 80.0

var space_velocity: Vector2 = Vector2.ZERO
var charge: float = 0.0
var is_charging: bool = false
var can_move: bool = false
var has_cassette: bool = false
var facing_right: bool = true
var original_modulate: Color

# Pre-cassette flail state
var _flail_cooldown: float = 0.0

# Audio generation state
var _bass_playing: bool = false
var _bass_freq: float = 55.0
var _bass_time: float = 0.0
var _bass_duration: float = 0.0
var _bass_strength: float = 0.0
var _hiss_active: bool = false

# Space ambient drone state
var _ambient_active: bool = false
var _ambient_time: float = 0.0
var _ambient_fade: float = 1.0  # 1.0 = full, fades to 0 on cassette pickup

# Visual references
@onready var sprite: Sprite2D = $Sprite2D
@onready var sound_ring: Node2D = $SoundRing
@onready var particles: GPUParticles2D = $NoteParticles
@onready var interact_area: Area2D = $InteractArea
@onready var cassette_sprite: Sprite2D = $CassetteSprite
@onready var charge_bar: ProgressBar = $ChargeBar

# Audio
@onready var bass_player: AudioStreamPlayer = $BassPlayer
@onready var hiss_player: AudioStreamPlayer = $HissPlayer
@onready var ambient_player: AudioStreamPlayer = $AmbientPlayer

signal pulse_fired(strength: float, direction: Vector2)

func _ready() -> void:
	original_modulate = sprite.modulate
	cassette_sprite.visible = false
	charge_bar.visible = false
	charge_bar.max_value = max_charge
	if particles:
		particles.emitting = false
	_setup_audio()
	# Start space ambient immediately — lonely cosmic drone from the start
	_ambient_active = true
	ambient_player.play()

func enable_flailing() -> void:
	## Pre-cassette: weak, chaotic movement
	can_move = true
	has_cassette = false

func enable_movement() -> void:
	## Full cassette-powered movement
	can_move = true
	has_cassette = true
	cassette_sprite.visible = true
	charge_bar.visible = true
	# Start cassette audio — bass + hiss
	bass_player.play()
	_hiss_active = true
	hiss_player.play()
	# Fade out space ambient over 3 seconds
	_ambient_fade = 1.0
	var tween := create_tween()
	tween.tween_method(_set_ambient_fade, 1.0, 0.0, 3.0)
	tween.tween_callback(func():
		_ambient_active = false
		ambient_player.stop()
	)

func _setup_audio() -> void:
	# Bass pulse — procedural sine wave with envelope
	var bass_gen := AudioStreamGenerator.new()
	bass_gen.mix_rate = 22050.0
	bass_gen.buffer_length = 1.0
	bass_player.stream = bass_gen
	bass_player.volume_db = 6.0
	bass_player.bus = &"Master"
	# Don't pre-start — only plays after cassette is received

	# Tape hiss — noise-based ambient
	var hiss_gen := AudioStreamGenerator.new()
	hiss_gen.mix_rate = 22050.0
	hiss_gen.buffer_length = 1.0
	hiss_player.stream = hiss_gen
	hiss_player.volume_db = -28.0
	hiss_player.bus = &"Master"

	# Space ambient — layered slow drones, lonely and cosmic
	var ambient_gen := AudioStreamGenerator.new()
	ambient_gen.mix_rate = 22050.0
	ambient_gen.buffer_length = 1.0
	ambient_player.stream = ambient_gen
	ambient_player.volume_db = -10.0
	ambient_player.bus = &"Master"

func _set_ambient_fade(val: float) -> void:
	_ambient_fade = val

func _process(_delta: float) -> void:
	# Fill audio buffers each frame
	_fill_bass_buffer()
	_fill_hiss_buffer()
	_fill_ambient_buffer()

func _fill_bass_buffer() -> void:
	if not bass_player.playing:
		return
	var playback := bass_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return

	var frames_available := playback.get_frames_available()
	if frames_available <= 0:
		return

	var sample_rate := 22050.0

	for i in frames_available:
		var value := 0.0
		if _bass_playing:
			var envelope := maxf(0.0, 1.0 - _bass_time / _bass_duration)
			envelope *= envelope  # Quadratic decay
			value = sin(TAU * _bass_freq * _bass_time) * 0.6
			value += sin(TAU * _bass_freq * 2.0 * _bass_time) * 0.25
			value += sin(TAU * _bass_freq * 3.0 * _bass_time) * 0.1
			value *= envelope * _bass_strength
			_bass_time += 1.0 / sample_rate
			if _bass_time >= _bass_duration:
				_bass_playing = false
		playback.push_frame(Vector2(value, value))

func _fill_hiss_buffer() -> void:
	if not hiss_player.playing:
		return
	var playback := hiss_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return

	var frames_available := playback.get_frames_available()
	if frames_available <= 0:
		return

	for i in frames_available:
		var value := 0.0
		if _hiss_active:
			# Simple white noise scaled down for tape hiss
			value = (randf() * 2.0 - 1.0) * 0.12
		playback.push_frame(Vector2(value, value))

func _fill_ambient_buffer() -> void:
	if not ambient_player.playing:
		return
	var playback := ambient_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return

	var frames_available := playback.get_frames_available()
	if frames_available <= 0:
		return

	var sample_rate := 22050.0

	for i in frames_available:
		var value := 0.0
		if _ambient_active:
			var t := _ambient_time
			# Deep sub-bass drone — very slow, feels like the void humming
			value += sin(TAU * 32.0 * t) * 0.15
			# Second drone a fifth above, slightly detuned — eerie interval
			value += sin(TAU * 48.3 * t) * 0.08
			# High ethereal tone — lonely, airy shimmer
			value += sin(TAU * 196.0 * t + sin(TAU * 0.2 * t) * 3.0) * 0.04
			# Even higher wisp — FM modulated for mystery
			value += sin(TAU * 523.0 * t + sin(TAU * 0.7 * t) * 5.0) * 0.02
			# Breathy filtered noise — cosmic wind
			var noise := (randf() * 2.0 - 1.0)
			# Simple low-pass via mixing with previous value (smoothing)
			noise *= 0.06 * (0.5 + sin(TAU * 0.15 * t) * 0.5)
			value += noise
			# Slow overall volume swell — breathes in and out
			var breath := 0.6 + sin(TAU * 0.08 * t) * 0.25 + sin(TAU * 0.13 * t) * 0.15
			value *= breath * _ambient_fade

			_ambient_time += 1.0 / sample_rate
		playback.push_frame(Vector2(value, value))

func _physics_process(delta: float) -> void:
	if not can_move:
		# Gentle floating drift when inactive — must use move_and_slide
		# so Area2D collision detection still works (cassette pickup)
		space_velocity *= 0.99
		velocity = space_velocity
		move_and_slide()
		return

	if not has_cassette:
		_physics_flail(delta)
		return

	# ── CASSETTE MODE: smooth, responsive ──
	# Rotation
	var rot_input := Input.get_axis("move_left", "move_right")
	rotation += rot_input * rotation_speed * delta

	# Update facing
	var aim_dir := Vector2.from_angle(rotation - PI / 2.0)
	if aim_dir.x > 0.1:
		facing_right = true
		sprite.flip_h = false
	elif aim_dir.x < -0.1:
		facing_right = false
		sprite.flip_h = true

	# Charge bass
	if Input.is_action_pressed("bass_pulse"):
		if not is_charging:
			is_charging = true
			charge = 0.0
		charge = minf(charge + charge_rate * delta, max_charge)
		charge_bar.value = charge
		# Visual feedback during charge — darken slightly
		var t := charge / max_charge
		sprite.modulate = Color(
			original_modulate.r,
			original_modulate.g,
			original_modulate.b * (1.0 - t * 0.3),
			original_modulate.a
		)
	elif is_charging:
		# Release pulse
		_fire_pulse(charge)
		is_charging = false
		charge = 0.0
		charge_bar.value = 0.0
		sprite.modulate = original_modulate

	# Interact
	if Input.is_action_just_pressed("interact"):
		_try_interact()

	# Apply drag (space has very little, so high value)
	space_velocity *= drag

	# Clamp speed
	if space_velocity.length() > max_speed:
		space_velocity = space_velocity.normalized() * max_speed

	# Move
	velocity = space_velocity
	move_and_slide()

func _physics_flail(delta: float) -> void:
	## Pre-cassette: weak, awkward kicks with random drift
	_flail_cooldown = maxf(_flail_cooldown - delta, 0.0)

	# Sluggish rotation — half speed, wobbles
	var rot_input := Input.get_axis("move_left", "move_right")
	rotation += rot_input * rotation_speed * 0.4 * delta
	# Random wobble
	rotation += sin(Time.get_ticks_msec() * 0.003) * 0.3 * delta

	# Space = weak, erratic kick (no charge, instant, with random offset)
	if Input.is_action_just_pressed("bass_pulse") and _flail_cooldown <= 0.0:
		var aim := Vector2.from_angle(rotation - PI / 2.0)
		# Add significant random offset — the sheep can't aim well
		var scatter := randf_range(-0.6, 0.6)
		aim = aim.rotated(scatter)
		# Weak force — about 25% of a minimal cassette pulse
		space_velocity += aim * pulse_force * 0.2
		_flail_cooldown = 0.4  # Can't spam — exhausting to flail
		# Visual: small wobble on the sprite
		var tween := create_tween()
		tween.tween_property(sprite, "rotation", randf_range(-0.2, 0.2), 0.1)
		tween.tween_property(sprite, "rotation", 0.0, 0.2)

	# Interact — still works
	if Input.is_action_just_pressed("interact"):
		_try_interact()

	# Heavier drag — movement feels labored
	space_velocity *= 0.97
	# Lower speed cap
	if space_velocity.length() > max_speed * 0.3:
		space_velocity = space_velocity.normalized() * max_speed * 0.3

	velocity = space_velocity
	move_and_slide()

func _fire_pulse(strength: float) -> void:
	var direction := Vector2.from_angle(rotation - PI / 2.0)
	var force := direction * pulse_force * (0.5 + strength * 0.5)
	space_velocity += force

	# Play bass sound
	_trigger_bass_note(strength)

	# Visual ring
	_spawn_sound_ring(strength)

	# Particles
	if particles:
		particles.emitting = true
		get_tree().create_timer(0.3).timeout.connect(func(): particles.emitting = false)

	pulse_fired.emit(strength, direction)

func _trigger_bass_note(strength: float) -> void:
	# Set parameters for the streaming fill function
	_bass_playing = true
	_bass_time = 0.0
	_bass_duration = 0.25 + strength * 0.2
	_bass_freq = 45.0 + strength * 30.0
	_bass_strength = clampf(strength / max_charge, 0.4, 1.0)

func _spawn_sound_ring(strength: float) -> void:
	if sound_ring:
		sound_ring.trigger(strength)

func _try_interact() -> void:
	if not interact_area:
		return
	var bodies := interact_area.get_overlapping_bodies()
	var areas := interact_area.get_overlapping_areas()
	for body in bodies:
		if body.has_method("interact"):
			body.interact(self)
			return
	for area in areas:
		if area.has_method("interact"):
			area.interact(self)
			return

func receive_cassette() -> void:
	GameState.has_cassette_bass = true
	enable_movement()
	GameState.advance_phase(GameState.Phase.TUTORIAL)
