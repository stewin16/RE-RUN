extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D

@onready var label: Label = get_node_or_null("Label")

var warning_text: String = "[!] WARNING!"

func _ready() -> void:
	if sfx:
		sfx.play()

	if not label:
		label = Label.new()
		label.name = "Label"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(-70, -28)
		label.custom_minimum_size = Vector2(140, 20)
		label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 4)
		label.add_theme_font_size_override("font_size", 9)
		var pixel_font: Font = load("res://Assets/Fonts/PressStart2P.ttf")
		if pixel_font:
			label.add_theme_font_override("font", pixel_font)
		add_child(label)

	label.text = warning_text

	# Fast flashing and pop animation
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
	tween.tween_property(sprite, "modulate:a", 0.3, 0.1)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	tween.tween_property(sprite, "modulate:a", 0.3, 0.1)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	tween.tween_interval(0.6)
	tween.tween_callback(queue_free)

func set_warning(msg: String) -> void:
	warning_text = msg
	if label:
		label.text = warning_text
