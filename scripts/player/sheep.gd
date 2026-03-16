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
var _sheep_sprites: Dictionary = {}  # Set by sprite_loader

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
var _ambient_fade: float = 1.0

# Whether using file-based audio instead of procedural
var _bass_from_file: bool = false
var _hiss_from_file: bool = false
var _ambient_from_file: bool = false

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
	# Start ambient drone immediately
	_ambient_active = true
	ambient_player.play()

func enable_movement() -> void:
	## Enable basic movement (no cassette yet)
	can_move = true

func receive_compass() -> void:
	## Compass picked up — show compass UI
	var compass := get_tree().get_first_node_in_group("compass_ui")
	if compass:
		compass.visible = true
		compass.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(compass, "modulate:a", 1.0, 0.8)

func receive_cassette() -> void:
	## Cassette picked up — full sound-powered movement
	has_cassette = true
	GameState.has_cassette_bass = true
	cassette_sprite.visible = true
	charge_bar.visible = true
	# Start cassette audio
	if not _bass_from_file:
		bass_player.play()  # Start generator stream for procedural fill
	_hiss_active = true
	hiss_player.play()
	# Fade out ambient drone
	if _ambient_from_file:
		var tween := create_tween()
		tween.tween_property(ambient_player, "volume_db", -60.0, 3.0)
		tween.tween_callback(ambient_player.stop)
	else:
		_ambient_fade = 1.0
		var tween := create_tween()
		tween.tween_method(_set_ambient_fade, 1.0, 0.0, 3.0)
		tween.tween_callback(func():
			_ambient_active = false
			ambient_player.stop()
		)
	GameState.advance_phase(GameState.Phase.TUTORIAL)

func _set_ambient_fade(val: float) -> void:
	_ambient_fade = val

func _try_load_audio(path_prefix: String) -> AudioStream:
	## Check for .ogg, .wav, or .mp3 in the given folder path
	var extensions: Array[String] = ["ogg", "wav", "mp3"]
	for ext in extensions:
		var path: String = path_prefix + "." + ext
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null

func _setup_audio() -> void:
	# Bass pulse — check for file, fall back to procedural
	var bass_file := _try_load_audio("res://assets/audio/bass_pulse/bass_pulse")
	if bass_file:
		bass_player.stream = bass_file
		bass_player.volume_db = 6.0
		bass_player.bus = &"Master"
		_bass_from_file = true
	else:
		var bass_gen := AudioStreamGenerator.new()
		bass_gen.mix_rate = 22050.0
		bass_gen.buffer_length = 1.0
		bass_player.stream = bass_gen
		bass_player.volume_db = 6.0
		bass_player.bus = &"Master"

	# Tape hiss — check for file, fall back to procedural
	var hiss_file := _try_load_audio("res://assets/audio/tape_hiss/tape_hiss")
	if hiss_file:
		hiss_player.stream = hiss_file
		hiss_player.volume_db = -28.0
		hiss_player.bus = &"Master"
		_hiss_from_file = true
	else:
		var hiss_gen := AudioStreamGenerator.new()
		hiss_gen.mix_rate = 22050.0
		hiss_gen.buffer_length = 1.0
		hiss_player.stream = hiss_gen
		hiss_player.volume_db = -28.0
		hiss_player.bus = &"Master"

	# Space ambient — check for file, fall back to procedural
	var ambient_file := _try_load_audio("res://assets/audio/ambient/ambient")
	if ambient_file:
		ambient_player.stream = ambient_file
		ambient_player.volume_db = -10.0
		ambient_player.bus = &"Master"
		_ambient_from_file = true
	else:
		var ambient_gen := AudioStreamGenerator.new()
		ambient_gen.mix_rate = 22050.0
		ambient_gen.buffer_length = 1.0
		ambient_player.stream = ambient_gen
		ambient_player.volume_db = -10.0
		ambient_player.bus = &"Master"

func _process(_delta: float) -> void:
	if not _bass_from_file:
		_fill_bass_buffer()
	if not _hiss_from_file:
		_fill_hiss_buffer()
	if not _ambient_from_file:
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
			# Deep sub-bass drone — the void humming
			value += sin(TAU * 32.0 * t) * 0.15
			# Detuned fifth — eerie interval
			value += sin(TAU * 48.3 * t) * 0.08
			# High ethereal shimmer
			value += sin(TAU * 196.0 * t + sin(TAU * 0.2 * t) * 3.0) * 0.04
			# FM wisp — mystery
			value += sin(TAU * 523.0 * t + sin(TAU * 0.7 * t) * 5.0) * 0.02
			# Cosmic wind noise
			var noise := (randf() * 2.0 - 1.0)
			noise *= 0.06 * (0.5 + sin(TAU * 0.15 * t) * 0.5)
			value += noise
			# Breathing volume swell
			var breath := 0.6 + sin(TAU * 0.08 * t) * 0.25 + sin(TAU * 0.13 * t) * 0.15
			value *= breath * _ambient_fade

			_ambient_time += 1.0 / sample_rate
		playback.push_frame(Vector2(value, value))

func _physics_process(delta: float) -> void:
	if not can_move:
		# Still need move_and_slide for Area2D collision detection
		space_velocity *= 0.99
		velocity = space_velocity
		move_and_slide()
		return

	# Rotation
	var rot_input := Input.get_axis("move_left", "move_right")
	rotation += rot_input * rotation_speed * delta

	# Update facing and directional sprite
	var aim_dir := Vector2.from_angle(rotation - PI / 2.0)
	if aim_dir.x > 0.1:
		facing_right = true
		sprite.flip_h = false
	elif aim_dir.x < -0.1:
		facing_right = false
		sprite.flip_h = true

	if _sheep_sprites.size() > 0:
		var angle := aim_dir.angle()  # -PI to PI, 0=right
		var deg := rad_to_deg(angle)
		# Map angle to sprite direction
		# Up=-90, Down=90, Right=0, Left=180/-180
		var key: String
		if deg > -22.5 and deg <= 22.5:
			key = "side_right"
		elif deg > 22.5 and deg <= 67.5:
			key = "front_right"
		elif deg > 67.5 and deg <= 112.5:
			key = "front"
		elif deg > 112.5 and deg <= 157.5:
			key = "front_left"
		elif deg > 157.5 or deg <= -157.5:
			key = "side_left"
		elif deg > -157.5 and deg <= -112.5:
			key = "back_left"
		elif deg > -112.5 and deg <= -67.5:
			key = "back"
		else:
			key = "back_right"
		if _sheep_sprites.has(key) and _sheep_sprites[key] != null:
			sprite.texture = _sheep_sprites[key]
			sprite.flip_h = false  # Sprites already have correct orientation

	# Charge bass pulse
	if Input.is_action_pressed("bass_pulse"):
		if not is_charging:
			is_charging = true
			charge = 0.0
		charge = minf(charge + charge_rate * delta, max_charge)
		charge_bar.value = charge
		var t := charge / max_charge
		sprite.modulate = Color(
			original_modulate.r,
			original_modulate.g,
			original_modulate.b * (1.0 - t * 0.3),
			original_modulate.a
		)
	elif is_charging:
		_fire_pulse(charge)
		is_charging = false
		charge = 0.0
		charge_bar.value = 0.0
		sprite.modulate = original_modulate

	# Interact
	if Input.is_action_just_pressed("interact"):
		_try_interact()

	# Drag
	space_velocity *= drag

	# Clamp speed
	if space_velocity.length() > max_speed:
		space_velocity = space_velocity.normalized() * max_speed

	velocity = space_velocity
	move_and_slide()

func _fire_pulse(strength: float) -> void:
	var direction := Vector2.from_angle(rotation - PI / 2.0)
	var force := direction * pulse_force * (0.5 + strength * 0.5)
	space_velocity += force

	if has_cassette:
		_trigger_bass_note(strength)
		_spawn_sound_ring(strength)

	if particles:
		particles.emitting = true
		get_tree().create_timer(0.3).timeout.connect(func(): particles.emitting = false)

	pulse_fired.emit(strength, direction)

func _trigger_bass_note(strength: float) -> void:
	if _bass_from_file:
		# Replay the audio file from the start
		bass_player.pitch_scale = 0.8 + strength / max_charge * 0.4
		bass_player.play()
	else:
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
