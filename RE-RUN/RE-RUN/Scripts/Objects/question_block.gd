extends StaticBody2D

signal quiz_triggered(block_node: Node2D)

@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_area: Area2D = $HitArea
@onready var hit_sfx: AudioStreamPlayer2D = $HitSFX
@onready var particles: CPUParticles2D = get_node_or_null("CPUParticles2D")

var is_hit: bool = false

func _ready() -> void:
	if hit_area:
		hit_area.body_entered.connect(_on_hit_area_body_entered)
		hit_area.area_entered.connect(_on_hit_area_area_entered)

func hit_block() -> void:
	if is_hit:
		return
	is_hit = true

	# Switch sprite region to hit bronze block (frame 1)
	if sprite:
		sprite.region_rect = Rect2(16, 0, 16, 16)
		var tween := create_tween()
		tween.tween_property(sprite, "position:y", -10.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, "position:y", 0.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	if hit_sfx:
		hit_sfx.play()

	if particles:
		particles.restart()
		particles.emitting = true

	emit_signal("quiz_triggered", self)

func _on_hit_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		hit_block()

func _on_hit_area_area_entered(area: Area2D) -> void:
	if area.name == "AttackArea":
		hit_block()

func deactivate_and_fade() -> void:
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(0.75, 0.75, 0.8), 0.3)
