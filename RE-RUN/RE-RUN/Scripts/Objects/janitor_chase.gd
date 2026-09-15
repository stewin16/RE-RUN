extends CharacterBody2D

signal intro_requested(c_name: String, c_speech: String)
signal chase_started()

const GRAVITY: float = 950.0

@export var base_chase_duration: float = 8.0

var is_standing: bool = true
var is_chasing: bool = false
var is_tired: bool = false
var is_caught: bool = false
var has_intro_shown: bool = false
var has_player_crossed: bool = false
var chase_timer: float = 0.0
var shout_timer: float = 0.0
var chase_dir: float = -1.0  # Starts facing left towards oncoming player!

var outrun_waves_done: int = 0
const MAX_OUTRUN_WAVES: int = 3
var offscreen_timer: float = 0.0

var janitor_sprite: Sprite2D
var player: CharacterBody2D = null
var is_fading_out: bool = false

# Obstacle avoidance & autonomous jump
var jump_cooldown: float = 0.0
var stuck_timer: float = 0.0
var last_x: float = 0.0

# Speech bubble Container
var speech_container: Control
var speech_patch: Panel
var speech_tail: TextureRect
var speech_label: Label

var dust_particles: CPUParticles2D

# Run animation frames
var run_textures: Array[Texture2D] = []
var anim_timer: float = 0.0
var current_frame: int = 0

const OUTRUN_SHOUTS = [
	"YOU CAN'T OUTRUN ME!",
	"HEY! STOP RIGHT THERE!",
	"NO RUNNING IN HALLWAYS!",
	"I'M STILL ON YOUR TAIL!",
	"WAIT TILL I CATCH YOU!"
]

const CHASER_DATA = {
	1: {
		"name": "Head Janitor",
		"spritesheet": "res://Assets/Characters/Janitors/janitor_runner_lvl1.png",
		"speech": "YOU'RE LATE!",
		"tired": "Phew... my knees...",
		"duration": 18.0
	},
	2: {
		"name": "Hall Monitor",
		"spritesheet": "res://Assets/Characters/Janitors/janitor_runner_lvl2.png",
		"speech": "NO RUNNING!",
		"tired": "Huff... slow down...",
		"duration": 20.0
	},
	3: {
		"name": "Canteen Chef",
		"spritesheet": "res://Assets/Characters/Janitors/janitor_runner_lvl3.png",
		"speech": "FORGOT LUNCH!",
		"tired": "Bento is cold...",
		"duration": 22.0
	},
	4: {
		"name": "Infirmary Nurse",
		"spritesheet": "res://Assets/Characters/Janitors/janitor_runner_lvl4.png",
		"speech": "HEALTH CHECK!",
		"tired": "Don't skip checks!",
		"duration": 24.0
	},
	5: {
		"name": "Head Librarian",
		"spritesheet": "res://Assets/Characters/Janitors/janitor_runner_lvl5.png",
		"speech": "RETURN BOOKS!",
		"tired": "Fines accumulate...",
		"duration": 25.0
	},
	6: {
		"name": "Campus Patrol",
		"spritesheet": "res://Assets/Characters/Janitors/janitor_runner_lvl6.png",
		"speech": "NO PERMIT!",
		"tired": "Too agile...",
		"duration": 26.0
	},
	7: {
		"name": "Lab Supervisor",
		"spritesheet": "res://Assets/Characters/Janitors/janitor_runner_lvl7.png",
		"speech": "GOGGLES ON!",
		"tired": "Lab rules ignored!",
		"duration": 27.0
	},
	8: {
		"name": "Athletic Coach",
		"spritesheet": "res://Assets/Characters/Janitors/janitor_runner_lvl8.png",
		"speech": "PICK UP PACE!",
		"tired": "Nice stamina kid!",
		"duration": 28.0
	},
	9: {
		"name": "Discipline Officer",
		"spritesheet": "res://Assets/Characters/Janitors/janitor_runner_lvl9.png",
		"speech": "VIOLATION!",
		"tired": "Reported to council!",
		"duration": 29.0
	},
	10: {
		"name": "Principal Pendelton",
		"spritesheet": "res://Assets/Characters/Janitors/janitor_runner_lvl10.png",
		"speech": "YOU SHALL NOT PASS!",
		"tired": "Face the Capstone!",
		"duration": 30.0
	}
}

func _ready() -> void:
	add_to_group("hazards")
	collision_layer = 4
	collision_mask = 3 # Mask world (1) and Player (2)

	# ── Sprite ──────────────────────────────────────────────────────────────
	janitor_sprite = Sprite2D.new()
	janitor_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	janitor_sprite.scale = Vector2(2.4, 2.4)
	janitor_sprite.position = Vector2(0, -18)
	add_child(janitor_sprite)

	# ── Dust particles ───────────────────────────────────────────────────────
	dust_particles = CPUParticles2D.new()
	dust_particles.emitting = false
	dust_particles.amount = 6
	dust_particles.lifetime = 0.25
	dust_particles.direction = Vector2(0, -1)
	dust_particles.spread = 30.0
	dust_particles.initial_velocity_min = 18.0
	dust_particles.initial_velocity_max = 36.0
	dust_particles.scale_amount_min = 0.5
	dust_particles.scale_amount_max = 1.0
	dust_particles.color = Color(0.85, 0.75, 0.6, 0.7)
	dust_particles.position = Vector2(0, 2)
	add_child(dust_particles)

	# ── Clean Comic Speech Bubble (directly attached above Janitor) ─────────
	speech_container = Control.new()
	speech_container.top_level = false
	speech_container.z_index = 25
	speech_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speech_container.visible = false
	add_child(speech_container)

	speech_patch = Panel.new()
	var sbox := StyleBoxFlat.new()
	sbox.bg_color = Color(1.0, 1.0, 1.0, 0.98)
	sbox.border_width_left = 2
	sbox.border_width_top = 2
	sbox.border_width_right = 2
	sbox.border_width_bottom = 2
	sbox.border_color = Color(0.08, 0.06, 0.12, 1.0)
	sbox.corner_radius_top_left = 4
	sbox.corner_radius_top_right = 4
	sbox.corner_radius_bottom_left = 4
	sbox.corner_radius_bottom_right = 4
	speech_patch.add_theme_stylebox_override("panel", sbox)
	speech_patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speech_container.add_child(speech_patch)

	speech_tail = TextureRect.new()
	var t_tex = load("res://Assets/SpeechBubbles/bubble_pixel_tail.png")
	if t_tex:
		speech_tail.texture = t_tex
	speech_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speech_container.add_child(speech_tail)

	speech_label = Label.new()
	speech_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speech_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speech_label.add_theme_font_size_override("font_size", 8)
	speech_label.add_theme_color_override("font_color", Color(0.08, 0.06, 0.12, 1.0))
	var pf: Font = load("res://Assets/Fonts/PressStart2P.ttf")
	if pf:
		speech_label.add_theme_font_override("font", pf)
	speech_patch.add_child(speech_label)
	setup_chaser_for_level()

# ─────────────────────────────────────────────────────────────────────────────
func setup_chaser_for_level() -> void:
	var lvl: int = 1
	if get_node_or_null("/root/GameSettings"):
		lvl = clampi(GameSettings.current_level, 1, 10)
	var data: Dictionary = CHASER_DATA.get(lvl, CHASER_DATA[1])

	# Load 4-frame run animation spritesheet (64x16, each frame is 16x16)
	var sheet_path: String = data.get("spritesheet", "res://Assets/Characters/Janitors/janitor_runner_lvl1.png")
	var sheet_tex: Texture2D = load(sheet_path)
	run_textures.clear()

	if sheet_tex:
		for f in range(4):
			var at := AtlasTexture.new()
			at.atlas = sheet_tex
			at.region = Rect2(f * 16, 0, 16, 16)
			run_textures.append(at)
	else:
		var fallback_path = "res://Assets/KW_School_Characters/16x16 Character/Other_M_A.png"
		var fb = load(fallback_path)
		if fb:
			run_textures.append(fb)

	if run_textures.size() > 0 and janitor_sprite:
		janitor_sprite.texture = run_textures[0]
		janitor_sprite.region_enabled = false

	set_speech_text(data.get("speech", "YOU'RE LATE!"))

func set_speech_text(msg: String) -> void:
	if not speech_label or not speech_patch:
		return
	speech_label.text = msg
	var char_count: int = msg.length()
	var estimated_w: float = float(char_count) * 8.5
	var bubble_w: float = clampf(estimated_w + 24.0, 96.0, 320.0)
	var bubble_h: float = 26.0

	speech_patch.size = Vector2(bubble_w, bubble_h)
	speech_label.position = Vector2(4.0, 2.0)
	speech_label.size = Vector2(bubble_w - 8.0, bubble_h - 4.0)
	if speech_container:
		if chase_dir >= 0.0:
			speech_container.position = Vector2(-12.0, -bubble_h - 28.0)
			if speech_tail:
				speech_tail.position = Vector2(12.0, bubble_h - 1.0)
		else:
			speech_container.position = Vector2(-bubble_w + 12.0, -bubble_h - 28.0)
			if speech_tail:
				speech_tail.position = Vector2(bubble_w - 22.0, bubble_h - 1.0)

# ─────────────────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		if velocity.y > 0.0:
			velocity.y = 0.0

	if jump_cooldown > 0.0:
		jump_cooldown -= delta

	# Locate player
	if not is_instance_valid(player):
		var p = get_tree().get_first_node_in_group("player")
		if p is CharacterBody2D:
			player = p
		return

	# If player was caught, Janitor stays stopped gloating
	if is_caught:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_speech_position()
		return

	# Fall-recovery safety net across bottomless gaps
	if global_position.y > 270.0:
		global_position.y = 195.0
		var safe_x_offset: float = -180.0 * chase_dir
		global_position.x = player.global_position.x + safe_x_offset
		velocity = Vector2(chase_dir * 180.0, -260.0)
		if dust_particles:
			dust_particles.restart()
			dust_particles.emitting = true

	# ── State 1: Standing Ahead on Track (Waiting for player) ────────────────
	if is_standing:
		velocity.x = 0.0
		move_and_slide()

		# Ensure idle standing visual facing left towards incoming player
		chase_dir = -1.0
		if janitor_sprite:
			janitor_sprite.scale.x = -2.4
			janitor_sprite.scale.y = 2.4
			janitor_sprite.rotation = 0.0
			janitor_sprite.position.y = -18.0
			if run_textures.size() > 0:
				janitor_sprite.texture = run_textures[0]
		if dust_particles:
			dust_particles.emitting = false

		# 1. Once Janitor enters camera frame -> Trigger Intro Modal!
		if not has_intro_shown and is_instance_valid(player):
			var dist_ahead: float = global_position.x - player.global_position.x
			# Viewport is 480px wide; ~330px distance places standing janitor clearly on-screen
			if dist_ahead <= 330.0 and dist_ahead > 0.0:
				has_intro_shown = true
				var lvl: int = 1
				if get_node_or_null("/root/GameSettings"):
					lvl = clampi(GameSettings.current_level, 1, 10)
				var d: Dictionary = CHASER_DATA.get(lvl, CHASER_DATA[1])
				emit_signal("intro_requested", d.get("name", "Head Janitor"), d.get("speech", "YOU'RE LATE!"))

		# 2. Check if player has jumped over / crossed the Janitor
		if is_instance_valid(player):
			var dx: float = player.global_position.x - global_position.x
			if dx > 18.0:
				# Player crossed past! Turn around and start chasing!
				start_chase()
				return

		# 3. If player runs directly into standing janitor on foot without jumping -> Detention!
		if not is_caught and not has_player_crossed and is_instance_valid(player) and not player.is_dead:
			var caught := false
			for i in range(get_slide_collision_count()):
				var col := get_slide_collision(i)
				var collider = col.get_collider()
				if collider and (collider.is_in_group("player") or collider.name == "Player"):
					caught = true
					break
			if not caught:
				var diff_x: float = abs(player.global_position.x - global_position.x)
				var diff_y: float = abs((player.global_position.y - 12.0) - (global_position.y - 14.0))
				if diff_x < 22.0 and diff_y < 24.0:
					caught = true
			if caught:
				set_speech_text("CAUGHT! DETENTION!")
				trigger_player_caught(player)
				return

	# ── State 2: Active Autonomous Chase (A bit slower & at a distance) ──────
	elif is_chasing and not is_tired:
		chase_timer += delta
		shout_timer += delta

		# Periodic comic shouts during pursuit
		if shout_timer >= 4.5:
			shout_timer = 0.0
			var shout: String = OUTRUN_SHOUTS[randi() % OUTRUN_SHOUTS.size()]
			set_speech_text(shout)

		# Track direction towards player
		var dx: float = player.global_position.x - global_position.x
		if abs(dx) > 4.0:
			var prev_dir = chase_dir
			chase_dir = sign(dx)
			if chase_dir != prev_dir:
				set_speech_text(speech_label.text if speech_label else "YOU'RE LATE!")

		# Reference player running speed
		var p_speed: float = 220.0
		if "SPEED" in player and player.SPEED > 0.0:
			p_speed = player.SPEED
		elif "WALK_SPEED" in player and player.WALK_SPEED > 0.0:
			p_speed = player.WALK_SPEED

		var player_run_speed: float = maxf(abs(player.velocity.x), p_speed * 0.6)
		# Distance to player in pursuit (janitor is behind player, so dx > 0)
		var dist_to_player: float = abs(dx)

		# Pacing: Keep Janitor chasing at a comfortable distance (140-190px behind)
		# and slightly slower than player to provide fair reaction & breathing room!
		var janitor_target_speed: float = player_run_speed
		if dist_to_player > 200.0:
			# Falling too far behind: gently keep in visible pursuit
			janitor_target_speed = player_run_speed * 1.04
		elif dist_to_player >= 135.0:
			# Desired pursuit sweet-spot (135 to 200px): slightly slower than player!
			janitor_target_speed = player_run_speed * 0.94
		elif dist_to_player >= 80.0:
			# Getting closer (< 135px): back off slightly to give player breathing room
			janitor_target_speed = player_run_speed * 0.88
		else:
			# Close range (< 80px): slow down further so player isn't instantly tackled
			janitor_target_speed = player_run_speed * 0.80

		# Smooth, natural acceleration
		var accel: float = 650.0
		if sign(velocity.x) != 0 and sign(velocity.x) != chase_dir:
			accel = 2400.0
		velocity.x = move_toward(velocity.x, chase_dir * janitor_target_speed, accel * delta)

		# Autonomous obstacle jumping across all terrains
		check_and_tackle_obstacles(janitor_target_speed)

		# Anti-stuck watchdog: jump if blocked horizontally
		if is_on_floor() and jump_cooldown <= 0.0:
			if abs(global_position.x - last_x) < 1.0:
				stuck_timer += delta
				if stuck_timer > 0.12:
					perform_jump(390.0)
					stuck_timer = 0.0
			else:
				stuck_timer = 0.0
		last_x = global_position.x

		move_and_slide()

		# Run animation cycle using actual 4-frame spritesheet
		anim_timer += delta
		if run_textures.size() > 1:
			var run_fps: float = clampf(abs(velocity.x) / 16.0, 5.0, 11.0)
			current_frame = int(anim_timer * run_fps) % run_textures.size()
			janitor_sprite.texture = run_textures[current_frame]

		# Visual squash & stretch, flip, and tilt
		if janitor_sprite:
			janitor_sprite.scale.x = 2.4 * chase_dir
			if not is_on_floor():
				janitor_sprite.scale.y = lerpf(janitor_sprite.scale.y, 2.7, 0.25)
				janitor_sprite.rotation = lerp_angle(janitor_sprite.rotation, -0.08 * chase_dir, 0.2)
				janitor_sprite.position.y = -21.0
			else:
				janitor_sprite.scale.y = lerpf(janitor_sprite.scale.y, 2.4, 0.3)
				janitor_sprite.rotation = lerp_angle(janitor_sprite.rotation, 0.04 * chase_dir, 0.2)
				janitor_sprite.position.y = -18.0

		# Dust particles
		if dust_particles:
			dust_particles.emitting = is_on_floor() and abs(velocity.x) > 40.0
			dust_particles.direction = Vector2(-chase_dir, -0.3)

		# Collision with player -> Catch player -> LEVEL FAILED!
		if not is_caught and is_instance_valid(player) and not player.is_dead:
			var caught := false
			for i in range(get_slide_collision_count()):
				var col := get_slide_collision(i)
				var collider = col.get_collider()
				if collider and (collider.is_in_group("player") or collider.name == "Player"):
					caught = true
					break
			if not caught:
				var diff_x: float = abs(player.global_position.x - global_position.x)
				var diff_y: float = abs((player.global_position.y - 12.0) - (global_position.y - 14.0))
				if diff_x < 24.0 and diff_y < 28.0:
					caught = true

			if caught:
				trigger_player_caught(player)
				return

		# Check chase duration limit -> smoothly tire out
		var max_duration: float = base_chase_duration
		var lvl: int = 1
		if get_node_or_null("/root/GameSettings"):
			lvl = clampi(GameSettings.current_level, 1, 10)
		var d: Dictionary = CHASER_DATA.get(lvl, CHASER_DATA[1])
		max_duration = d.get("duration", 20.0)

		if chase_timer >= max_duration:
			tire_out()

	# ── State 3: Tired / Out of breath state ──────────────────────────────────
	elif is_tired:
		chase_timer += delta
		# STOPS completely and does NOT follow the student!
		velocity.x = 0.0
		move_and_slide()

		# Always faces the student whichever direction the student moves or runs!
		if is_instance_valid(player):
			var dx_student: float = player.global_position.x - global_position.x
			if abs(dx_student) > 3.0:
				chase_dir = sign(dx_student)

		if janitor_sprite:
			var pant := sin(chase_timer * 4.0)
			janitor_sprite.position.y = -18.0 + pant * 1.5
			janitor_sprite.rotation = lerp_angle(janitor_sprite.rotation, 0.12 * chase_dir, 0.1)
			janitor_sprite.scale.x = 2.4 * chase_dir
			janitor_sprite.scale.y = 2.4
			if run_textures.size() > 0:
				janitor_sprite.texture = run_textures[0]

		if dust_particles:
			dust_particles.emitting = false

		# ── Tired janitor contact check: player touching stopped janitor = CAUGHT! ──
		# The janitor is resting but is still a dangerous obstacle!
		if not is_caught and is_instance_valid(player) and not player.is_dead:
			var contact_caught := false
			for i in range(get_slide_collision_count()):
				var col := get_slide_collision(i)
				var collider = col.get_collider()
				if collider and (collider.is_in_group("player") or collider.name == "Player"):
					contact_caught = true
					break
			if not contact_caught:
				var dx: float = abs(player.global_position.x - global_position.x)
				var dy: float = abs((player.global_position.y - 12.0) - (global_position.y - 14.0))
				if dx < 24.0 and dy < 28.0:
					contact_caught = true
			if contact_caught:
				# Tired janitor grabs the student — DETENTION!
				set_speech_text("GOTCHA! DETENTION!")
				trigger_player_caught(player)
				return

		# DOES NOT VANISH ON SCREEN!
		# Stays standing, panting, and watching the student.
		# Only cleans up if the student is far away off-screen (> 1200px away).
		if is_instance_valid(player):
			var dist_away: float = abs(player.global_position.x - global_position.x)
			if dist_away > 1200.0:
				queue_free()

	_update_speech_position()

# ─────────────────────────────────────────────────────────────────────────────
func trigger_player_caught(p_node: CharacterBody2D) -> void:
	if is_caught or is_fading_out:
		return
	is_caught = true
	is_chasing = false
	velocity = Vector2.ZERO
	if is_instance_valid(p_node):
		var dx_caught: float = p_node.global_position.x - global_position.x
		if abs(dx_caught) > 2.0:
			chase_dir = sign(dx_caught)
			if janitor_sprite:
				janitor_sprite.scale.x = 2.4 * chase_dir

	# ── SECRET LEVEL 5 ALTERNATE REALM TRIGGER ──────────────────────────────
	var lvl: int = 1
	if get_node_or_null("/root/GameSettings"):
		lvl = clampi(GameSettings.current_level, 1, 10)

	if lvl == 5:
		# On Level 5: DO NOT kill player, DO NOT remove life, DO NOT trigger Game Over!
		# INSTEAD: trigger dimensional glitch tear & warp into the Alternate Realm!
		trigger_level_5_alternate_realm_warp(p_node)
		return

	# Standard caught logic for other levels (1-4, 6-10):
	set_speech_text("CAUGHT YOU! DETENTION!")

	if p_node.has_method("die"):
		p_node.die()

	var hud = get_tree().get_first_node_in_group("hud")
	if not hud:
		var root = get_tree().current_scene
		if root:
			hud = root.get_node_or_null("HUD")
	if hud and hud.has_method("show_game_over_sequence"):
		hud.show_game_over_sequence("CAUGHT! LEVEL FAILED")

func trigger_level_5_alternate_realm_warp(p_node: CharacterBody2D) -> void:
	# Stop player velocity & input
	if is_instance_valid(p_node):
		if "is_controlled" in p_node:
			p_node.is_controlled = false
		if "velocity" in p_node:
			p_node.velocity = Vector2.ZERO

	# Janitor is stunned as reality breaks
	set_speech_text("WAIT... REALITY IS TEARING?!")

	# Play dimensional warp sound effect
	var warp_player := AudioStreamPlayer.new()
	var snd = load("res://Assets/Audio/dimensional_warp.wav")
	if snd:
		warp_player.stream = snd
	warp_player.volume_db = 2.0
	get_tree().root.add_child(warp_player)
	warp_player.play()

	# Dramatic screen shake
	var root = get_tree().current_scene
	if root and root.has_method("add_shake"):
		root.add_shake(14.0)

	# Flash reality tear overlay (violet dimensional breach)
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	var overlay := ColorRect.new()
	overlay.color = Color(0.8, 0.1, 1.0, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)
	get_tree().root.add_child(canvas)

	var tw := create_tween()
	tw.tween_property(overlay, "color:a", 1.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished

	# Seamless transition to the secret Alternate Realm!
	if is_instance_valid(canvas):
		canvas.queue_free()
	var tree := get_tree()
	if tree:
		tree.change_scene_to_file("res://Scenes/Levels/alternate_realm.tscn")
	return

# ─────────────────────────────────────────────────────────────────────────────
func check_and_tackle_obstacles(forward_speed: float = 160.0) -> void:
	if not is_on_floor() or jump_cooldown > 0.0:
		return

	# 1. Direct wall collision check
	if is_on_wall():
		perform_jump(400.0)
		return

	var space_state = get_world_2d().direct_space_state

	# 2. Raycast physics check ahead for hazards/barriers/pipes (waist level)
	var look_ahead_dist := 42.0 * chase_dir
	var origin := global_position + Vector2(0, -12)
	var target := origin + Vector2(look_ahead_dist, 0)

	var query := PhysicsRayQueryParameters2D.create(origin, target)
	query.exclude = [get_rid()]
	query.collision_mask = 1 | 4  # ground blocks & hazards
	var result = space_state.intersect_ray(query)
	if result:
		perform_jump(390.0)
		return

	# 3. Pit / Gap detection: check if ground drops off ahead
	var floor_check_pos := global_position + Vector2(28.0 * chase_dir, 10.0)
	var down_query := PhysicsRayQueryParameters2D.create(floor_check_pos, floor_check_pos + Vector2(0, 56.0))
	down_query.exclude = [get_rid()]
	down_query.collision_mask = 1
	var down_res = space_state.intersect_ray(down_query)
	if not down_res:
		# Pit ahead! Athletic forward leap across gap!
		velocity.x = chase_dir * (forward_speed * 1.25)
		perform_jump(415.0)
		return

	# 4. High platform leap: If player is higher above on an elevated platform
	if is_instance_valid(player):
		var dy = player.global_position.y - global_position.y
		var dx = abs(player.global_position.x - global_position.x)
		if dy < -45.0 and dx < 140.0:
			perform_jump(420.0)

func perform_jump(force: float = 380.0) -> void:
	velocity.y = -force
	jump_cooldown = 0.40
	if dust_particles:
		dust_particles.restart()
		dust_particles.emitting = true
	if janitor_sprite:
		janitor_sprite.scale = Vector2(2.1 * chase_dir, 2.8)

# ─────────────────────────────────────────────────────────────────────────────
func _update_speech_position() -> void:
	if not speech_container:
		return
	speech_container.visible = (is_chasing or is_tired or is_caught) and not (is_fading_out and speech_container.modulate.a <= 0.05)

# ─────────────────────────────────────────────────────────────────────────────
func start_chase() -> void:
	is_standing = false
	is_chasing = true
	is_tired = false
	is_caught = false
	has_player_crossed = true
	chase_dir = 1.0
	chase_timer = 0.0
	shout_timer = 0.0
	outrun_waves_done = 0
	offscreen_timer = 0.0
	if janitor_sprite:
		janitor_sprite.scale.x = 2.4
	if dust_particles:
		dust_particles.restart()
		dust_particles.emitting = true
	setup_chaser_for_level()
	var lvl: int = 1
	if get_node_or_null("/root/GameSettings"):
		lvl = clampi(GameSettings.current_level, 1, 10)
	var d: Dictionary = CHASER_DATA.get(lvl, CHASER_DATA[1])
	set_speech_text(d.get("speech", "STOP RIGHT THERE!"))
	if speech_container:
		speech_container.modulate.a = 1.0
		speech_container.visible = true
	emit_signal("chase_started")

func tire_out() -> void:
	if is_tired:
		return
	is_chasing = false
	is_tired = true
	chase_timer = 0.0
	velocity = Vector2.ZERO

	var lvl: int = 1
	if get_node_or_null("/root/GameSettings"):
		lvl = clampi(GameSettings.current_level, 1, 10)
	var d: Dictionary = CHASER_DATA.get(lvl, CHASER_DATA[1])
	set_speech_text(d.get("tired", "Huff... you're too fast... phew..."))
