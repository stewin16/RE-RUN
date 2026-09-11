extends CharacterBody2D

signal health_changed(new_health: int)
signal player_died
signal coin_collected(total_coins: int)

var SPEED: float = 280.0:
	set(val):
		SPEED = val
		WALK_SPEED = val
var WALK_SPEED: float = 280.0
const ACCELERATION := 2000.0
const FRICTION := 1800.0
const JUMP_FORCE := -390.0
const DOUBLE_JUMP_FORCE := -350.0
const GRAVITY := 1250.0
const COYOTE_TIME := 0.15
const JUMP_BUFFER_TIME := 0.12
const SLIDE_DURATION := 0.42
const ATTACK_DURATION := 0.18

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var dust: CPUParticles2D = $DustParticles
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var slash_sprite: Sprite2D = $AttackArea/SlashSprite

@onready var jump_sfx: AudioStreamPlayer2D = $JumpSFX
@onready var land_sfx: AudioStreamPlayer2D = $LandSFX
@onready var hurt_sfx: AudioStreamPlayer2D = $HurtSFX
@onready var slide_sfx: AudioStreamPlayer2D = $SlideSFX
@onready var slash_sfx: AudioStreamPlayer2D = $SlashSFX

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var landing_timer: float = 0.0
var hurt_timer: float = 0.0
var invulnerable_timer: float = 0.0
var slide_timer: float = 0.0
var attack_timer: float = 0.0

var jumps_left: int = 2
var facing_dir: float = 1.0
var max_health: int = 3
var health: int = 3
var spawn_point: Vector2 = Vector2.ZERO
var is_dead: bool = false
var is_controlled: bool = true
var is_sliding: bool = false
var is_attacking: bool = false

func _ready() -> void:
	add_to_group("player")
	spawn_point = global_position
	setup_character_appearance()
	health = GameSettings.lifelines
	emit_signal("health_changed", health)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if GameSettings.has_shield and not is_dead:
		var pulse := sin(Time.get_ticks_msec() * 0.008) * 2.0
		draw_arc(Vector2(0, -12), 17.0 + pulse, 0, TAU, 32, Color(0.2, 0.85, 1.0, 0.8), 2.0)
		draw_arc(Vector2(0, -12), 19.0 + pulse, 0, TAU, 32, Color(1.0, 0.85, 0.2, 0.5), 1.2)

func setup_character_appearance() -> void:
	var char_info: Dictionary = GameSettings.get_current_character()
	var char_tex_path: String = char_info.get("sprite", "res://Assets/Player/runner_student_m_a.png")
	var char_tex: Texture2D = load(char_tex_path)
	if not char_tex:
		print("Warning: Could not load character texture:", char_tex_path)
		return
	if sprite and sprite.sprite_frames:
		var sf: SpriteFrames = sprite.sprite_frames.duplicate(true)
		for anim in sf.get_animation_names():
			for f_idx in range(sf.get_frame_count(anim)):
				var old_tex = sf.get_frame_texture(anim, f_idx)
				if old_tex is AtlasTexture:
					var new_tex := AtlasTexture.new()
					new_tex.atlas = char_tex
					new_tex.region = old_tex.region
					sf.set_frame(anim, f_idx, new_tex)
		sprite.sprite_frames = sf
		sprite.visible = true
		sprite.modulate = Color.WHITE
		sprite.play("run")

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		return

	if not is_controlled:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		if sprite:
			sprite.visible = true
			sprite.modulate.a = 1.0
			if is_on_floor():
				sprite.play("idle")
		return

	# Decrement active timers
	if coyote_timer > 0.0:
		coyote_timer -= delta
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta
	if landing_timer > 0.0:
		landing_timer -= delta
	if hurt_timer > 0.0:
		hurt_timer -= delta
	if invulnerable_timer > 0.0:
		invulnerable_timer -= delta
		if sprite:
			sprite.visible = true
			sprite.modulate.a = 0.35 if (int(invulnerable_timer * 15.0) % 2 == 0) else 1.0
	elif sprite:
		sprite.visible = true
		sprite.modulate.a = 1.0

	# Ground detection & coyote time / double jump reset
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		jumps_left = 2
	
	# Detect landing impact
	if not was_on_floor and is_on_floor():
		landing_timer = 0.12
		if velocity.y >= 0:
			if land_sfx:
				land_sfx.play()
			if dust:
				dust.restart()
				dust.emitting = true
			if sprite:
				sprite.scale = Vector2.ONE

	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Attack action (J / F / Z / X / C / Left Click)
	if is_attack_just_pressed():
		if not is_attacking and hurt_timer <= 0.0:
			start_attack()

	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0.0:
			end_attack()

	# Slide action (S / Down Arrow / ui_down)
	if is_on_floor() and not is_sliding and not is_attacking and hurt_timer <= 0.0:
		if is_slide_just_pressed():
			start_slide()

	if is_sliding:
		slide_timer -= delta
		if dust:
			dust.emitting = true
		if slide_timer <= 0.0 or not is_on_floor() or is_jump_just_pressed():
			end_slide()

	# Jump buffer input (Space / W / Up Arrow / ui_accept / ui_up)
	if is_jump_just_pressed() and not is_sliding:
		jump_buffer_timer = JUMP_BUFFER_TIME

	# Jump execution (Ground jump or Midair Double jump)
	if jump_buffer_timer > 0.0:
		if coyote_timer > 0.0:
			# First jump from ground/ledge
			velocity.y = JUMP_FORCE
			jump_buffer_timer = 0.0
			coyote_timer = 0.0
			landing_timer = 0.0
			jumps_left = 1
			play_jump_effects()
		elif jumps_left > 0:
			# Fluid mid-air double jump!
			velocity.y = DOUBLE_JUMP_FORCE
			jump_buffer_timer = 0.0
			jumps_left = 0
			play_jump_effects()

	# Variable jump height cut on key release
	if is_jump_just_released() and velocity.y < -150.0:
		velocity.y = -150.0

	# Responsive Horizontal Movement (A/D or Left/Right Arrow keys)
	var move_input := get_horizontal_input()
	var current_speed := WALK_SPEED if not is_sliding else (WALK_SPEED * 1.35)
	
	if move_input != 0.0:
		facing_dir = sign(move_input)
		velocity.x = move_toward(velocity.x, move_input * current_speed, ACCELERATION * delta)
		if sprite:
			sprite.flip_h = move_input < 0.0
		if attack_area:
			attack_area.scale.x = facing_dir
		if is_on_floor() and not is_sliding and randf() < 0.2:
			if dust:
				dust.emitting = true
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		if dust and not is_sliding:
			dust.emitting = false

	# Update visual animations
	update_animation(move_input)

	was_on_floor = is_on_floor()
	move_and_slide()

	# Fall death / pit boundary check (ground is at y=220; if fell off track y > 300)
	if global_position.y > 300.0 and not is_dead:
		take_damage(1)

func get_horizontal_input() -> float:
	var dir := 0.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_action_pressed("ui_left"):
		dir -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_action_pressed("ui_right"):
		dir += 1.0
	return dir

func is_jump_just_pressed() -> bool:
	return Input.is_physical_key_pressed(KEY_SPACE) or \
		   Input.is_physical_key_pressed(KEY_W) or \
		   Input.is_physical_key_pressed(KEY_UP) or \
		   Input.is_action_just_pressed("ui_accept") or \
		   Input.is_action_just_pressed("ui_up")

func is_jump_just_released() -> bool:
	var jump_held: bool = Input.is_physical_key_pressed(KEY_SPACE) or \
						  Input.is_physical_key_pressed(KEY_W) or \
						  Input.is_physical_key_pressed(KEY_UP) or \
						  Input.is_action_pressed("ui_accept") or \
						  Input.is_action_pressed("ui_up")
	return not jump_held

func is_slide_just_pressed() -> bool:
	return Input.is_physical_key_pressed(KEY_S) or \
		   Input.is_physical_key_pressed(KEY_DOWN) or \
		   Input.is_action_just_pressed("ui_down")

func is_attack_just_pressed() -> bool:
	return Input.is_physical_key_pressed(KEY_J) or \
		   Input.is_physical_key_pressed(KEY_F) or \
		   Input.is_physical_key_pressed(KEY_Z) or \
		   Input.is_physical_key_pressed(KEY_X) or \
		   Input.is_physical_key_pressed(KEY_C) or \
		   Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

func play_jump_effects() -> void:
	if jump_sfx:
		jump_sfx.play()
	if dust:
		dust.restart()
		dust.emitting = true
	if sprite:
		sprite.scale = Vector2.ONE

func start_attack() -> void:
	is_attacking = true
	attack_timer = ATTACK_DURATION
	if attack_area:
		attack_area.monitoring = true
	if slash_sprite:
		slash_sprite.visible = true
	if slash_sfx:
		slash_sfx.play()

func end_attack() -> void:
	is_attacking = false
	attack_timer = 0.0
	if attack_area:
		attack_area.monitoring = false
	if slash_sprite:
		slash_sprite.visible = false

func start_slide() -> void:
	is_sliding = true
	slide_timer = SLIDE_DURATION
	if collision_shape:
		var shape := collision_shape.shape as RectangleShape2D
		if shape:
			shape.size = Vector2(14, 12)
			collision_shape.position = Vector2(0, -6)
	if slide_sfx:
		slide_sfx.play()

func end_slide() -> void:
	is_sliding = false
	slide_timer = 0.0
	if collision_shape:
		var shape := collision_shape.shape as RectangleShape2D
		if shape:
			shape.size = Vector2(14, 24)
			collision_shape.position = Vector2(0, -12)

func update_animation(horizontal_dir: float) -> void:
	if not sprite:
		return
	sprite.visible = true
	if is_dead:
		return
	if hurt_timer > 0.0:
		if sprite.animation != "hurt":
			sprite.play("hurt")
		return
	if is_sliding:
		if sprite.animation != "slide":
			sprite.play("slide")
		return

	if not is_on_floor():
		if velocity.y < -50.0:
			if sprite.animation != "jump":
				sprite.play("jump")
		else:
			if sprite.animation != "fall":
				sprite.play("fall")
	elif landing_timer > 0.0:
		if sprite.animation != "land":
			sprite.play("land")
	elif horizontal_dir != 0.0:
		if sprite.animation != "run":
			sprite.play("run")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")

func take_damage(amount: int = 1) -> void:
	if invulnerable_timer > 0.0 or is_dead:
		return

	# Shield absorb power-up check
	if GameSettings.has_shield:
		GameSettings.has_shield = false
		invulnerable_timer = 1.2
		velocity.y = -180.0
		if hurt_sfx:
			hurt_sfx.play()
		return

	GameSettings.lifelines = max(0, GameSettings.lifelines - amount)
	health = GameSettings.lifelines
	emit_signal("health_changed", health)

	if hurt_sfx:
		hurt_sfx.play()

	if GameSettings.lifelines <= 0:
		die()
	else:
		hazard_respawn_ahead()

func hazard_respawn_ahead() -> void:
	# Put player slightly ahead of where they fell/hit, onto safe track level (y=190)
	global_position = Vector2(global_position.x + 85.0, 190.0)
	velocity = Vector2(WALK_SPEED, 0.0)
	hurt_timer = 0.2
	invulnerable_timer = 1.6 # 1.6s invulnerability flicker
	is_sliding = false
	is_attacking = false
	if sprite:
		sprite.rotation = 0.0
		sprite.scale = Vector2.ONE
		sprite.play("run")

func set_checkpoint(pos: Vector2) -> void:
	spawn_point = pos

func die() -> void:
	if is_dead:
		return
	is_dead = true
	is_controlled = false
	end_slide()
	end_attack()
	if sprite:
		sprite.play("death")
	if dust:
		dust.amount = 12
		dust.restart()
		dust.emitting = true
	emit_signal("player_died")

func revive_at_location(pos: Vector2) -> void:
	global_position = Vector2(pos.x + 80.0, 190.0)
	velocity = Vector2(WALK_SPEED, 0.0)
	GameSettings.lifelines = 3
	health = 3
	is_dead = false
	is_controlled = true
	is_sliding = false
	is_attacking = false
	hurt_timer = 0.0
	invulnerable_timer = 1.8
	if sprite:
		sprite.rotation = 0.0
		sprite.scale = Vector2.ONE
		sprite.play("run")
	emit_signal("health_changed", health)

func respawn_to_start() -> void:
	global_position = Vector2(80, 180)
	velocity = Vector2(WALK_SPEED, 0.0)
	GameSettings.lifelines = 3
	health = 3
	is_dead = false
	is_controlled = true
	is_sliding = false
	is_attacking = false
	hurt_timer = 0.0
	invulnerable_timer = 1.2
	if sprite:
		sprite.rotation = 0.0
		sprite.scale = Vector2.ONE
		sprite.play("run")
	emit_signal("health_changed", health)

func respawn() -> void:
	respawn_to_start()
