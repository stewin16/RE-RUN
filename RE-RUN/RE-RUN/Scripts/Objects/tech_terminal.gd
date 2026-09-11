extends Area2D

signal quiz_triggered(terminal_node: Node2D)

@onready var sprite: Sprite2D = $Sprite2D
@onready var particles: CPUParticles2D = get_node_or_null("CPUParticles2D")

var is_activated: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	if not is_activated and sprite:
		sprite.position.y = sin(Time.get_ticks_msec() * 0.006) * 2.0

func _on_body_entered(body: Node2D) -> void:
	if is_activated:
		return
	if body.is_in_group("player") or body.name == "Player":
		is_activated = true
		emit_signal("quiz_triggered", self)
		if particles:
			particles.emitting = false

func deactivate_and_fade() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
