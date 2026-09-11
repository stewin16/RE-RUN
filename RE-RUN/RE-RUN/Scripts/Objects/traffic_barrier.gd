extends Area2D

signal near_miss_triggered(pos: Vector2)

@onready var near_miss_area: Area2D = $NearMissArea
@onready var sprite: Sprite2D = $Sprite2D

var has_triggered_near_miss: bool = false
var has_hit: bool = false

func _ready() -> void:
	if near_miss_area:
		near_miss_area.body_entered.connect(_on_near_miss_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		has_hit = true
		body.take_damage(1)

func _on_near_miss_body_entered(body: Node2D) -> void:
	if not has_hit and not has_triggered_near_miss and body.is_in_group("player"):
		has_triggered_near_miss = true
		emit_signal("near_miss_triggered", global_position + Vector2(0, -24))
		# Small wobble game feel
		var tween := create_tween()
		tween.tween_property(sprite, "rotation", 0.08, 0.05)
		tween.tween_property(sprite, "rotation", -0.08, 0.05)
		tween.tween_property(sprite, "rotation", 0.0, 0.05)
