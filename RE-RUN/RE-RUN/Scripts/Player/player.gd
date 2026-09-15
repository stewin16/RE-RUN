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
var JUMP_FORCE: float = -420.0
var DOUBLE_JUMP_FORCE: float = -410.0
var GRAVITY: float = 1250.0
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

var raw_jump_pressed: bool = false
var raw_jump_released: bool = false
var raw_slide_pressed: bool = false
var raw_attack_pressed: bool = false

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
	var char_id: String = char_info.get("id", "student_m_a")
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

	# Apply Unique Character Skill Perks:
	match char_id:
		"student_m_a": # Leo Tanaka (Algorithms): +10% Speed
			SPEED *= 1.10
			WALK_SPEED *= 1.10
		"student_m_b": # Kai Sterling (Cybersecurity): Free Shield
			GameSettings.has_shield = true
		"student_m_c": # Ren Takahashi (Physics): Low-Gravity Jump
			JUMP_FORCE = -440.0
			GRAVITY = 1100.0
		"student_f_h": # Sayaka Endo (Database): Starts with 2 Hints
			GameSettings.hints = max(2, GameSettings.hints)
		"student_f_k": # Erika Von Braun (Cybernetics): 4 Lifelines
			GameSettings.lifelines = 4
			health = 4
			max_health = 4
			emit_signal("health_changed", health)

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
				sprite.scale = Vector2(1.30, 0.70)
				var tw := create_tween()
				tw.tween_property(sprite, "scale", Vector2.ONE, 0.15)

	# Ghost Pixel Motion Trail during high speed / skills
	if velocity.x > 320.0 or GameSettings.power_up_timer > 0.0:
		if int(Time.get_ticks_msec() / 60) % 2 == 0:
			spawn_ghost_trail()

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
			coyote_timer = 0.0
			jump_buffer_timer = 0.0
			jumps_left = 1
			landing_timer = 0.0
			play_jump_effects()
		elif jumps_left > 0:
			# Fluid mid-air double jump!
			velocity.y = DOUBLE_JUMP_FORCE
			jump_buffer_timer = 0.0
			jumps_left = 0
			play_jump_effects()

	# Variable jump height cut on key release (only on initial jump tap)
	if is_jump_just_released() and velocity.y < -180.0 and jumps_left == 1:
		velocity.y = -180.0

	# Responsive Horizontal Movement (A/D or Left/Right Arrow keys)
	var move_input := get_horizontal_input()
	var current_speed := WALK_SPEED
	
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

	# Hazard collision check (Janitor chase/stopped detention contact)
	if not is_dead:
		for i in range(get_slide_collision_count()):
			var col := get_slide_collision(i)
			var collider = col.get_collider()
			if collider and is_instance_valid(collider):
				if collider.is_in_group("hazards") and collider.has_method("trigger_player_caught"):
					collider.trigger_player_caught(self)
					break

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var k: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if k in [KEY_SPACE, KEY_W, KEY_UP]:
			if event.pressed and not event.echo:
				raw_jump_pressed = true
			elif not event.pressed:
				raw_jump_released = true
		elif k in [KEY_S, KEY_DOWN]:
			if event.pressed and not event.echo:
				raw_slide_pressed = true
		elif k in [KEY_J, KEY_F, KEY_Z, KEY_X, KEY_C]:
			if event.pressed and not event.echo:
				raw_attack_pressed = true
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			raw_attack_pressed = true

func is_jump_just_pressed() -> bool:
	var pressed := raw_jump_pressed or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up")
	raw_jump_pressed = false
	return pressed

func is_jump_just_released() -> bool:
	var rel := raw_jump_released or Input.is_action_just_released("ui_accept") or Input.is_action_just_released("ui_up")
	raw_jump_released = false
	return rel

func is_slide_just_pressed() -> bool:
	var pressed := raw_slide_pressed or Input.is_action_just_pressed("ui_down")
	raw_slide_pressed = false
	return pressed

func is_attack_just_pressed() -> bool:
	var pressed := raw_attack_pressed
	raw_attack_pressed = false
	return pressed

func play_jump_effects() -> void:
	if jump_sfx:
		jump_sfx.play()
	if dust:
		dust.restart()
		dust.emitting = true
	if sprite:
		sprite.scale = Vector2(0.70, 1.35)
		var tw := create_tween()
		tw.tween_property(sprite, "scale", Vector2.ONE, 0.18)

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
	# Put player safely ahead of where they fell/hit (past moving block gaps), onto safe track level (y=190)
	global_position = Vector2(global_position.x + 220.0, 190.0)
	velocity = Vector2(WALK_SPEED, 0.0)
	hurt_timer = 0.2
	invulnerable_timer = 2.0 # 2.0s invulnerability flicker
	is_sliding = false
	is_attacking = false
	if sprite:
		sprite.rotation = 0.0
		sprite.scale = Vector2.ONE
		sprite.play("run")

func set_checkpoint(pos: Vector2) -> void:
	spawn_point = pos

func heal(amount: int = 1) -> void:
	if is_dead:
		return
	GameSettings.lifelines = min(max_health, GameSettings.lifelines + amount)
	health = GameSettings.lifelines
	emit_signal("health_changed", health)

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

func trigger_unique_skill() -> bool:
	if GameSettings.is_character_skill_used or is_dead:
		return false

	GameSettings.is_character_skill_used = true
	var char_info: Dictionary = GameSettings.get_current_character()
	var char_id: String = char_info.get("id", "student_m_a")

	match char_id:
		"student_m_a": # Leo: Sprint Surge 5s (Smooth temporary boost)
			invulnerable_timer = 5.0
			var orig_spd := WALK_SPEED
			WALK_SPEED = orig_spd * 1.20
			var tw := create_tween()
			tw.tween_interval(5.0)
			tw.tween_property(self, "WALK_SPEED", orig_spd, 0.4)
		"student_m_b": # Kai: Firewall Shield
			GameSettings.has_shield = true
			invulnerable_timer = 2.0
		"student_m_c": # Ren: Low Gravity Launch
			velocity.y = -520.0
			invulnerable_timer = 3.0
		"student_m_d": # Jin: Cloud Restore 1 Heart
			GameSettings.lifelines = min(max_health, GameSettings.lifelines + 1)
			health = GameSettings.lifelines
			emit_signal("health_changed", health)
		"student_m_e": # Arata: Overclock 12s Magnet
			GameSettings.activate_tech_power_up(12.0)
		"student_m_f": # Daiki: Bloom Radiance 2X Score
			GameSettings.is_multiplier_active = true
			GameSettings.power_up_timer = 15.0
		"student_m_g": # Haruto: Zero-Cost Abstraction
			invulnerable_timer = 3.0
		"student_m_h": # Kaito: Cluster Surge
			GameSettings.activate_tech_power_up(10.0)
		"student_m_i": # Sora: Cellular Heal
			GameSettings.lifelines = min(max_health, GameSettings.lifelines + 1)
			health = GameSettings.lifelines
			emit_signal("health_changed", health)
		"student_m_j": # Riku: DMA Surge
			GameSettings.knowledge_score += 50
		"student_m_k": # Shinjiro: Quantum Phase
			invulnerable_timer = 6.0
		"student_f_a": # Maya: Agile Hyper Dash
			velocity.x = 600.0
			invulnerable_timer = 3.0
		"student_f_b": # Chloe: Data Mining
			GameSettings.activate_tech_power_up(10.0)
		"student_f_c": # Aoi: Predictive AI
			GameSettings.hints += 1
		"student_f_d": # Yuna: Exploit Bypass Shield
			GameSettings.has_shield = true
			invulnerable_timer = 3.0
		"student_f_e": # Hana: Ergonomic Buffer
			GameSettings.knowledge_score += 40
		"student_f_f": # Rin: Phantom Magnetism
			GameSettings.is_magnet_active = true
			GameSettings.power_up_timer = 14.0
		"student_f_g": # Mei: Thermal Vision
			invulnerable_timer = 4.0
		"student_f_h": # Sayaka: B-Tree Cache
			GameSettings.hints += 1
			GameSettings.knowledge_score += 25
		"student_f_i": # Sakura: Kernel Interrupt
			invulnerable_timer = 5.0
		"student_f_j": # Nozomi: Proximity Sensor
			invulnerable_timer = 4.0
		"student_f_k", _: # Erika: Nanite Repair
			GameSettings.lifelines = 4
			health = 4
			GameSettings.has_shield = true
			emit_signal("health_changed", health)

	return true

func spawn_ghost_trail() -> void:
	if not sprite or not sprite.sprite_frames:
		return
	var current_anim = sprite.animation
	var current_frame = sprite.frame
	var frame_tex = sprite.sprite_frames.get_frame_texture(current_anim, current_frame)
	if not frame_tex:
		return
	var ghost := Sprite2D.new()
	ghost.texture = frame_tex
	ghost.global_position = sprite.global_position
	ghost.scale = sprite.scale
	ghost.flip_h = sprite.flip_h
	ghost.rotation = sprite.rotation
	ghost.modulate = Color(0.2, 0.9, 1.0, 0.45)
	ghost.top_level = true
	get_parent().add_child(ghost)

	var tw := create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tw.tween_callback(ghost.queue_free)

func trigger_hit_stop(duration: float = 0.06) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration * 0.05, true, false, true).timeout
	Engine.time_scale = 1.0

func _on_attack_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage()
	elif area.is_in_group("hazards") or area.is_in_group("enemies"):
		if area.has_method("deactivate_and_fade"):
			area.deactivate_and_fade()
		else:
			var tw := create_tween()
			tw.tween_property(area, "scale", Vector2.ZERO, 0.1)
			tw.tween_callback(area.queue_free)

