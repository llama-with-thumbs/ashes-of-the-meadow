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
var facing_right: bool = true
var original_modulate: Color

# Audio generation state
var _bass_playing: bool = false
var _bass_freq: float = 55.0
var _bass_time: float = 0.0
var _bass_duration: float = 0.0
var _bass_strength: float = 0.0
var _hiss_active: bool = false

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

signal pulse_fired(strength: float, direction: Vector2)

func _ready() -> void:
	original_modulate = sprite.modulate
	cassette_sprite.visible = false
	charge_bar.visible = false
	charge_bar.max_value = max_charge
	if particles:
		particles.emitting = false
	_setup_audio()

func enable_movement() -> void:
	can_move = true
	cassette_sprite.visible = true
	charge_bar.visible = true
	# Start tape hiss
	_hiss_active = true
	hiss_player.play()

func _setup_audio() -> void:
	# Bass pulse — procedural sine wave with envelope
	var bass_gen := AudioStreamGenerator.new()
	bass_gen.mix_rate = 22050.0
	bass_gen.buffer_length = 1.0
	bass_player.stream = bass_gen
	bass_player.volume_db = 6.0
	bass_player.bus = &"Master"
	# Pre-start the player so playback is always available
	bass_player.play()

	# Tape hiss — noise-based ambient
	var hiss_gen := AudioStreamGenerator.new()
	hiss_gen.mix_rate = 22050.0
	hiss_gen.buffer_length = 1.0
	hiss_player.stream = hiss_gen
	hiss_player.volume_db = -28.0
	hiss_player.bus = &"Master"

func _process(_delta: float) -> void:
	# Fill audio buffers each frame
	_fill_bass_buffer()
	_fill_hiss_buffer()

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

func _physics_process(delta: float) -> void:
	if not can_move:
		# Gentle floating drift when inactive — must use move_and_slide
		# so Area2D collision detection still works (cassette pickup)
		space_velocity *= 0.99
		velocity = space_velocity
		move_and_slide()
		return

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
