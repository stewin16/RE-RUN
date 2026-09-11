extends CharacterBody2D

signal exam_damage_taken(current_hp: int)
signal exam_attack_launched
signal boss_defeated

@onready var sprite: Sprite2D = $Sprite2D
@onready var sfx_attack: AudioStreamPlayer2D = $AttackSFX
@onready var sfx_hurt: AudioStreamPlayer2D = $HurtSFX
@onready var aura_particles: CPUParticles2D = get_node_or_null("CPUParticles2D")

var max_hp: int = 5
var hp: int = 5
var is_active: bool = false
var base_y: float = 0.0

func _ready() -> void:
	base_y = position.y
	setup_boss_appearance()
	play_state("idle")

func setup_boss_appearance() -> void:
	var teacher_data: Dictionary = GameSettings.get_current_teacher()
	var tex_path: String = teacher_data.get("sprite", "res://Assets/Characters/teacher_boss.png")
	var tex = load(tex_path)
	if not tex or (tex.get_width() != 192 or tex.get_height() != 48):
		tex = load("res://Assets/Characters/teacher_boss.png")
	if tex and sprite:
		sprite.texture = tex
		sprite.region_enabled = true
		sprite.visible = true
		sprite.modulate = Color.WHITE
		sprite.flip_h = true

func _process(delta: float) -> void:
	if is_active:
		# Floating levitation
		position.y = base_y + sin(Time.get_ticks_msec() * 0.004) * 4.0

func play_state(state_name: String) -> void:
	if not sprite:
		return
	match state_name:
		"idle":
			sprite.region_rect = Rect2(0, 0, 48, 48)
		"attack":
			sprite.region_rect = Rect2(48, 0, 48, 48)
		"hurt":
			sprite.region_rect = Rect2(96, 0, 48, 48)
		"defeat":
			sprite.region_rect = Rect2(144, 0, 48, 48)

func take_exam_damage() -> void:
	hp = max(0, hp - 1)
	play_state("hurt")
	if sfx_hurt:
		sfx_hurt.play()
	
	# Hurt shake & flash
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.5, 0.4, 0.4), 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	await tween.finished
	
	if hp <= 0:
		play_state("defeat")
		emit_signal("boss_defeated")
	else:
		play_state("idle")
	
	emit_signal("exam_damage_taken", hp)

func launch_exam_attack() -> void:
	play_state("attack")
	if sfx_attack:
		sfx_attack.play()
	emit_signal("exam_attack_launched")
	
	# Spawn flying exam paper projectile towards left
	var paper := Sprite2D.new()
	paper.texture = load("res://Assets/Items/flying_exam_paper.png")
	paper.global_position = global_position + Vector2(-20, -5)
	get_parent().add_child(paper)
	
	var tween := create_tween()
	tween.tween_property(paper, "global_position", paper.global_position + Vector2(-160, 20), 0.35)
	tween.parallel().tween_property(paper, "rotation", -PI * 1.5, 0.35)
	tween.tween_callback(paper.queue_free)
	
	await get_tree().create_timer(0.4).timeout
	play_state("idle")
