extends AnimatableBody2D

@export var move_offset: Vector2 = Vector2(120, 0)
@export var duration: float = 3.0

var start_pos: Vector2

func _ready() -> void:
	start_pos = global_position
	start_tween()

func start_tween() -> void:
	var tween := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", start_pos + move_offset, duration)
	tween.tween_property(self, "global_position", start_pos, duration)
