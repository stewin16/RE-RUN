extends Area2D

signal defeated(pos: Vector2, points: int)

@export var patrol_dist: float = 120.0
@export var speed: float = 60.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_sfx: AudioStreamPlayer2D = $HitSFX

var start_x: float = 0.0
var direction: float = 1.0
var time_passed: float = 0.0
var is_dead: bool = false

func _ready() -> void:
	start_x = global_position.x

func _process(delta: float) -> void:
	if is_dead:
		return

	time_passed += delta
	# Sinusoidal flying bob
	position.y += sin(time_passed * 4.0) * 0.4

	# Horizontal patrol
	position.x += direction * speed * delta
	if position.x > start_x + patrol_dist:
		direction = -1.0
		sprite.flip_h = true
	elif position.x < start_x - patrol_dist:
		direction = 1.0
		sprite.flip_h = false

	# Wing flap animation
	sprite.region_rect = Rect2(32 if int(time_passed * 8.0) % 2 == 1 else 0, 0, 32, 32)

func _on_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body.is_in_group("player"):
		# Check if player stomped on top
		if body.velocity.y > 0 and body.global_position.y < global_position.y - 4.0:
			body.velocity.y = -380.0 # Stomp bounce!
			take_damage()
		elif body.has_method("take_damage"):
			body.take_damage(1)

func take_damage() -> void:
	if is_dead:
		return
	is_dead = true
	if hit_sfx:
		hit_sfx.play()
	emit_signal("defeated", global_position, 150)
	
	# Pixel death burst animation
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.08)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.12)
	tween.tween_callback(queue_free)
