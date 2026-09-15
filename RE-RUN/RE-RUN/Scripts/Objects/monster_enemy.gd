extends Area2D

@export_enum("zombie", "skeleton", "witch") var monster_type: String = "zombie"
@export var speed: float = 65.0
@export var is_flying: bool = false
@export var max_health: int = 1

var health: int = 1
var is_dead: bool = false
var has_hit: bool = false
var has_triggered_near_miss: bool = false

var move_dir: float = -1.0
var base_y: float = 0.0
var anim_timer: float = 0.0
var current_frame: int = 0
var frames_list: Array[Texture2D] = []

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var groan_sfx: AudioStreamPlayer2D = $GroanSFX

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	base_y = position.y
	setup_monster_spritesheet()
	body_entered.connect(_on_body_entered)

func setup_monster_spritesheet() -> void:
	var path := ""
	match monster_type:
		"zombie":
			path = "res://Assets/Enemies/Monsters/zombie.png"
			speed = 55.0
			is_flying = false
		"skeleton":
			path = "res://Assets/Enemies/Monsters/skeleton.png"
			speed = 85.0
			is_flying = false
		"witch":
			path = "res://Assets/Enemies/Monsters/witch.png"
			speed = 70.0
			is_flying = true

	var tex: Texture2D = load(path)
	if not tex:
		return

	frames_list.clear()
	# Each frame is 32x32
	var total_frames := int(tex.get_width() / 32)
	for i in range(mini(total_frames, 12)): # Walk / fly cycle
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * 32, 0, 32, 32)
		frames_list.append(at)

	if frames_list.size() > 0 and sprite:
		sprite.texture = frames_list[0]
		sprite.scale = Vector2(1.5, 1.5)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	anim_timer += delta

	# Horizontal movement (marching towards oncoming runner)
	position.x += move_dir * speed * delta

	# Flying enemy sine wave hover
	if is_flying:
		position.y = base_y + sin(anim_timer * 3.5) * 18.0

	# Frame animation
	if frames_list.size() > 1 and sprite:
		var fps := 8.0
		current_frame = int(anim_timer * fps) % frames_list.size()
		sprite.texture = frames_list[current_frame]
		sprite.flip_h = move_dir > 0.0

	# Random groan sound effect
	if groan_sfx and randf() < 0.003:
		if not groan_sfx.playing:
			groan_sfx.pitch_scale = randf_range(0.85, 1.15)
			groan_sfx.play()

func _on_body_entered(body: Node2D) -> void:
	if is_dead or has_hit:
		return
	if not (body.is_in_group("player") or body.name == "Player"):
		return

	# If player jumped high over monster:
	if body.has_method("is_on_floor") and not body.is_on_floor():
		if body.global_position.y <= global_position.y - 14.0 or ("velocity" in body and body.velocity.y < 0.0):
			trigger_near_miss()
			return

	# If player attacked / slashed through monster:
	if "is_attacking" in body and body.is_attacking:
		take_damage(1)
		return

	# Direct collision damage
	has_hit = true
	if body.has_method("take_damage"):
		body.take_damage(1)

func take_damage(amount: int = 1) -> void:
	if is_dead:
		return
	health -= amount
	if health <= 0:
		die()
	else:
		# Hit flash
		if sprite:
			sprite.modulate = Color(3.0, 0.4, 0.4, 1.0)
			var tw := create_tween()
			tw.tween_property(sprite, "modulate", Color.WHITE, 0.12)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	has_hit = true

	# Score popup and sound
	var hud = get_tree().get_first_node_in_group("hud")
	if not hud:
		var root = get_tree().current_scene
		if root:
			hud = root.get_node_or_null("HUD")
	if hud:
		hud.add_score(250)
		hud.show_floating_text("+250", global_position + Vector2(0, -20), Color(0.9, 0.3, 1.0))

	if sprite:
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(sprite, "scale", Vector2(2.0, 0.2), 0.18)
		tw.tween_property(sprite, "modulate:a", 0.0, 0.18)
		tw.tween_callback(queue_free).set_delay(0.20)
	else:
		queue_free()

func trigger_near_miss() -> void:
	if not has_triggered_near_miss:
		has_triggered_near_miss = true
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.add_score(75)
			hud.show_floating_text("VAULT! +75", global_position + Vector2(0, -28), Color(0.3, 0.9, 1.0))
