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
	if not (body.is_in_group("player") or body.name == "Player"):
		return

	# 1. If player is sliding, they safely pass underneath!
	if "is_sliding" in body and body.is_sliding:
		trigger_dodged()
		return

	# 2. If player attacked / slashed through the obstacle:
	if "is_attacking" in body and body.is_attacking:
		trigger_dodged()
		return

	# 3. If player jumped / is airborne (high jump dodge, double jump, or airborne arc):
	# Any jump attempt or airborne state means player has initiated a jump dodge!
	var is_jumping_or_airborne: bool = false
	if body.has_method("is_on_floor") and not body.is_on_floor():
		is_jumping_or_airborne = true
	if "velocity" in body and abs(body.velocity.y) > 10.0:
		is_jumping_or_airborne = true
	if "jumps_left" in body and body.jumps_left < 2:
		is_jumping_or_airborne = true
	if body.global_position.y < global_position.y - 4.0:
		is_jumping_or_airborne = true

	if is_jumping_or_airborne:
		trigger_dodged()
		return

	# 4. Only take damage if running upright into the barrier at ground level without dodging:
	if not has_hit and body.has_method("take_damage"):
		has_hit = true
		body.take_damage(1)

func trigger_dodged() -> void:
	if not has_triggered_near_miss:
		has_triggered_near_miss = true
		emit_signal("near_miss_triggered", global_position + Vector2(0, -28))
		wobble()

func _on_near_miss_body_entered(body: Node2D) -> void:
	if not has_hit and not has_triggered_near_miss and (body.is_in_group("player") or body.name == "Player"):
		trigger_dodged()

func wobble() -> void:
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "rotation", 0.08, 0.05)
		tween.tween_property(sprite, "rotation", -0.08, 0.05)
		tween.tween_property(sprite, "rotation", 0.0, 0.05)
