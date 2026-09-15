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
	var sprite_path: String = teacher_data.get("sprite", "res://Assets/KW_School_Characters/16x16 Character/Teacher_M_A.png")
	var tex = load(sprite_path)
	if not tex:
		tex = load("res://Assets/KW_School_Characters/16x16 Character/Teacher_M_A.png")
	if tex and sprite:
		sprite.texture = tex
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, 16, 16)
		sprite.visible = true
		sprite.scale = Vector2(2.5, 2.5)
		sprite.modulate = Color.WHITE
		sprite.flip_h = true

func play_state(state_name: String) -> void:
	if not sprite:
		return
	match state_name:
		"idle":
			sprite.scale = Vector2(2.5, 2.5)
			sprite.modulate = Color.WHITE
		"attack":
			sprite.scale = Vector2(3.0, 3.0)
			sprite.modulate = Color(1.0, 0.85, 0.3)
		"hurt":
			sprite.scale = Vector2(2.1, 2.1)
			sprite.modulate = Color(1.0, 0.3, 0.3)
		"defeat":
			sprite.scale = Vector2(2.5, 2.5)
			sprite.modulate = Color(0.4, 0.4, 0.5, 0.6)

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
