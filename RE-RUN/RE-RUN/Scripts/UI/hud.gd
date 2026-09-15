extends CanvasLayer

signal countdown_finished
signal restart_requested
signal revive_requested

const SAVE_PATH = "user://rerun_save.cfg"

# Top Bar nodes
@onready var score_label: Label = $TopLeft/ScoreVBox/ScoreRow/ScoreVal
@onready var best_label: Label = $TopLeft/ScoreVBox/ScoreRow/BestVal
@onready var hearts_hbox: HBoxContainer = get_node_or_null("TopLeft/ScoreVBox/HeartsHBox")
@onready var heart_icons: Array[TextureRect] = [
	get_node_or_null("TopLeft/ScoreVBox/HeartsHBox/Heart1"),
	get_node_or_null("TopLeft/ScoreVBox/HeartsHBox/Heart2"),
	get_node_or_null("TopLeft/ScoreVBox/HeartsHBox/Heart3"),
	get_node_or_null("TopLeft/ScoreVBox/HeartsHBox/Heart4")
]
var tex_heart_full: Texture2D = preload("res://Assets/UI/heart_full.png")
var tex_heart_empty: Texture2D = preload("res://Assets/UI/heart_empty.png")
@onready var knowledge_label: Label = $TopRight/CoinsHBox/KnowledgeVal
@onready var hints_label: Label = $TopRight/CoinsHBox/HintsVal
@onready var coins_label: Label = get_node_or_null("TopRight/CoinsHBox/CoinsVal")
@onready var coin_icon: TextureRect = get_node_or_null("TopRight/CoinsHBox/CoinIcon")

# Countdown
@onready var countdown_label: Label = $CenterOverlay/CountdownLabel

# Menus
@onready var boss_intro_modal: Control = get_node_or_null("BossIntroModal")
@onready var boss_intro_title: Label = get_node_or_null("BossIntroModal/Panel/VBox/Title")
@onready var boss_intro_rule: Label = get_node_or_null("BossIntroModal/Panel/VBox/RuleLabel")
@onready var boss_start_btn: Button = get_node_or_null("BossIntroModal/Panel/VBox/StartExamBtn")

@onready var chase_warning_modal: Control = get_node_or_null("ChaseWarningModal")
@onready var chase_warning_title: Label = get_node_or_null("ChaseWarningModal/Panel/VBox/Title")
@onready var chase_warning_rule: Label = get_node_or_null("ChaseWarningModal/Panel/VBox/RuleLabel")
@onready var chase_warning_btn: Button = get_node_or_null("ChaseWarningModal/Panel/VBox/ContinueBtn")

@onready var fact_modal: Control = get_node_or_null("FactModal")
@onready var fact_modal_title: Label = get_node_or_null("FactModal/Panel/VBox/Title")
@onready var fact_modal_rule: Label = get_node_or_null("FactModal/Panel/VBox/RuleLabel")
@onready var fact_modal_btn: Button = get_node_or_null("FactModal/Panel/VBox/ContinueBtn")

var modal_open_time: int = 0

@onready var pause_menu: Control = $PauseMenu
@onready var game_over_menu: Control = $GameOverMenu
@onready var win_menu: Control = get_node_or_null("WinMenu")
@onready var toast_label: Label = $CenterOverlay/ToastLabel

# Boss Bar Panel
@onready var boss_bar_panel: Panel = get_node_or_null("BossBarPanel")
@onready var boss_face_rect: TextureRect = get_node_or_null("BossBarPanel/MainHBox/BossFaceRect")
@onready var boss_title_label: Label = get_node_or_null("BossBarPanel/MainHBox/VBox/BossTitle")
@onready var boss_hp_label: Label = get_node_or_null("BossBarPanel/MainHBox/VBox/StatusHBox/BossHP")
@onready var boss_progress_label: Label = get_node_or_null("BossBarPanel/MainHBox/VBox/StatusHBox/ExamProgress")

# Fact Toast Panel
@onready var fact_toast_panel: Panel = get_node_or_null("FactToast")
@onready var fact_toast_title: Label = get_node_or_null("FactToast/VBox/FactTitle")
@onready var fact_toast_content: Label = get_node_or_null("FactToast/VBox/FactContent")

# Tech Quiz Modal nodes
@onready var quiz_modal: Control = get_node_or_null("TechQuizModal")
@onready var quiz_title_label: Label = get_node_or_null("TechQuizModal/Panel/VBox/HeaderHBox/Title")
@onready var quiz_heart_icons: Array[TextureRect] = [
	get_node_or_null("TechQuizModal/Panel/VBox/HeaderHBox/QuizHeartsHBox/QHeart1"),
	get_node_or_null("TechQuizModal/Panel/VBox/HeaderHBox/QuizHeartsHBox/QHeart2"),
	get_node_or_null("TechQuizModal/Panel/VBox/HeaderHBox/QuizHeartsHBox/QHeart3"),
	get_node_or_null("TechQuizModal/Panel/VBox/HeaderHBox/QuizHeartsHBox/QHeart4")
]
@onready var quiz_q_label: Label = get_node_or_null("TechQuizModal/Panel/VBox/QuestionLabel")
@onready var quiz_opt1: Button = get_node_or_null("TechQuizModal/Panel/VBox/OptionsVBox/Opt1")
@onready var quiz_opt2: Button = get_node_or_null("TechQuizModal/Panel/VBox/OptionsVBox/Opt2")
@onready var quiz_opt3: Button = get_node_or_null("TechQuizModal/Panel/VBox/OptionsVBox/Opt3")
@onready var quiz_opt4: Button = get_node_or_null("TechQuizModal/Panel/VBox/OptionsVBox/Opt4")
@onready var quiz_hint_btn: Button = get_node_or_null("TechQuizModal/Panel/VBox/FooterHBox/HintBtn")
@onready var quiz_reward_hint: Label = get_node_or_null("TechQuizModal/Panel/VBox/FooterHBox/RewardHint")

# Power up badge
@onready var powerup_badge: Panel = get_node_or_null("PowerUpBadge")
@onready var powerup_label: Label = get_node_or_null("PowerUpBadge/Label")

# Game Over elements
@onready var go_title: Label = $GameOverMenu/Panel/VBox/Title
@onready var go_new_best: Label = $GameOverMenu/Panel/VBox/NewBestLabel
@onready var go_score_box: Control = $GameOverMenu/Panel/VBox/ScoreContainer
@onready var go_score_val: Label = $GameOverMenu/Panel/VBox/ScoreContainer/ScoreRow/ScoreNum
@onready var go_coins_val: Label = get_node_or_null("GameOverMenu/Panel/VBox/ScoreContainer/CoinsRow/CoinsNum")
@onready var go_best_val: Label = $GameOverMenu/Panel/VBox/ScoreContainer/BestRow/BestNum
@onready var go_buttons: Control = $GameOverMenu/Panel/VBox/ButtonContainer
@onready var go_revive_btn: Button = get_node_or_null("GameOverMenu/Panel/VBox/ReviveBtn")

# Win Menu elements
@onready var win_stats_label: Label = get_node_or_null("WinMenu/Panel/VBox/StatsLabel")
@onready var skill_btn: Button = get_node_or_null("BottomRight/SkillBtn")

# Audio players
@onready var click_sfx: AudioStreamPlayer = $ClickSFX
@onready var hs_sfx: AudioStreamPlayer = $HighscoreSFX
@onready var quiz_correct_sfx: AudioStreamPlayer = get_node_or_null("QuizCorrectSFX")
@onready var quiz_wrong_sfx: AudioStreamPlayer = get_node_or_null("QuizWrongSFX")
@onready var hint_used_sfx: AudioStreamPlayer = get_node_or_null("HintUsedSFX")
@onready var fact_chime_sfx: AudioStreamPlayer = get_node_or_null("FactChimeSFX")

var current_score: float = 0.0
var displayed_score: float = 0.0
var coins: int = 0
var best_score: int = 0
var is_new_best: bool = false
var is_counting_down: bool = false

# Quiz state
var current_correct_idx: int = 0
var current_option_buttons: Array[Button] = []
var active_quiz_terminal: Node2D = null
var hint_used_for_current_q: bool = false

# Boss Battle state
var is_in_boss_battle: bool = false
var active_boss_node: Node2D = null
var boss_hp: int = 5
var boss_round: int = 0
var boss_correct_count: int = 0
var boss_questions_queue: Array = []

const QUIZ_QUESTIONS = [
	{
		"q": "What is the time complexity of searching a sorted array using Binary Search?",
		"correct": "O(log n)",
		"wrongs": ["O(n)", "O(n^2)", "O(1)"]
	},
	{
		"q": "Which fundamental data structure operates on a Last-In, First-Out (LIFO) model?",
		"correct": "Stack",
		"wrongs": ["Queue", "Binary Tree", "Hash Map"]
	},
	{
		"q": "What default port is used worldwide for encrypted HTTPS network traffic?",
		"correct": "Port 443",
		"wrongs": ["Port 80", "Port 22", "Port 8080"]
	},
	{
		"q": "Which Python keyword defines an anonymous inline function?",
		"correct": "lambda",
		"wrongs": ["inline", "def", "func"]
	},
	{
		"q": "In Git, which command stages all modified and newly created files in workspace?",
		"correct": "git add .",
		"wrongs": ["git push -all", "git commit -a", "git stage --hard"]
	},
	{
		"q": "What does SQL stand for in database management?",
		"correct": "Structured Query Language",
		"wrongs": ["Sequential Quick Logic", "System Query Link", "Standard Queue Logic"]
	},
	{
		"q": "Which boolean logic gate outputs TRUE only when the two inputs differ?",
		"correct": "XOR Gate",
		"wrongs": ["AND Gate", "NOR Gate", "NAND Gate"]
	},
	{
		"q": "Which sorting algorithm guarantees O(n log n) worst-case time complexity?",
		"correct": "Merge Sort",
		"wrongs": ["Bubble Sort", "Quick Sort", "Insertion Sort"]
	},
	{
		"q": "In networking, what does the abbreviation DNS stand for?",
		"correct": "Domain Name System",
		"wrongs": ["Digital Network Server", "Dynamic Node Sector", "Data Name Signal"]
	},
	{
		"q": "Which HTTP status code signifies that a requested resource was NOT FOUND?",
		"correct": "404",
		"wrongs": ["200", "500", "403"]
	}
]

func _ready() -> void:
	# --- Connect all button signals ---
	if boss_start_btn:
		boss_start_btn.pressed.connect(_on_start_boss_exam_pressed)
	if skill_btn:
		skill_btn.pressed.connect(_on_skill_btn_pressed)

	# Quiz option buttons
	if quiz_opt1:
		quiz_opt1.pressed.connect(_on_quiz_opt1_pressed)
	if quiz_opt2:
		quiz_opt2.pressed.connect(_on_quiz_opt2_pressed)
	if quiz_opt3:
		quiz_opt3.pressed.connect(_on_quiz_opt3_pressed)
	if quiz_opt4:
		quiz_opt4.pressed.connect(_on_quiz_opt4_pressed)
	if quiz_hint_btn:
		quiz_hint_btn.pressed.connect(_on_hint_pressed)

	# Pause menu buttons
	var resume_btn: Button = get_node_or_null("PauseMenu/Panel/VBox/ResumeBtn")
	if resume_btn:
		resume_btn.pressed.connect(_on_resume_pressed)
	var pause_restart_btn: Button = get_node_or_null("PauseMenu/Panel/VBox/RestartBtn")
	if pause_restart_btn:
		pause_restart_btn.pressed.connect(_on_retry_pressed)
	var pause_menu_btn: Button = get_node_or_null("PauseMenu/Panel/VBox/MenuBtn")
	if pause_menu_btn:
		pause_menu_btn.pressed.connect(_on_menu_pressed)

	# Game Over buttons
	if go_revive_btn:
		go_revive_btn.pressed.connect(_on_revive_pressed)
	var retry_btn: Button = get_node_or_null("GameOverMenu/Panel/VBox/ButtonContainer/RetryBtn")
	if retry_btn:
		retry_btn.pressed.connect(_on_retry_pressed)
	var go_menu_btn: Button = get_node_or_null("GameOverMenu/Panel/VBox/ButtonContainer/MenuBtn")
	if go_menu_btn:
		go_menu_btn.pressed.connect(_on_menu_pressed)

	add_to_group("hud")

	# Win Menu buttons
	var next_btn: Button = get_node_or_null("WinMenu/Panel/VBox/ButtonContainer/NextLevelBtn")
	if next_btn:
		next_btn.pressed.connect(_on_next_level_pressed)
	var win_menu_btn: Button = get_node_or_null("WinMenu/Panel/VBox/ButtonContainer/MenuBtn")
	if win_menu_btn:
		win_menu_btn.pressed.connect(_on_menu_pressed)

	load_best_score()
	GameSettings.reset_run_state()
	coins = GameSettings.wallet_coins
	if coins_label:
		coins_label.text = "%d" % coins
	pause_menu.visible = false
	game_over_menu.visible = false
	if win_menu:
		win_menu.visible = false
	if quiz_modal:
		quiz_modal.visible = false
	if boss_bar_panel:
		boss_bar_panel.visible = false
	if powerup_badge:
		powerup_badge.visible = false
	if countdown_label:
		countdown_label.visible = false
	if toast_label:
		toast_label.visible = false

	current_option_buttons = [quiz_opt1, quiz_opt2, quiz_opt3, quiz_opt4]

	if chase_warning_btn:
		chase_warning_btn.pressed.connect(_on_dismiss_chase_warning)
	if fact_modal_btn:
		fact_modal_btn.pressed.connect(_on_dismiss_fact_modal)
	if chase_warning_modal:
		chase_warning_modal.visible = false
	if fact_modal:
		fact_modal.visible = false

	var pixel_font: Font = load("res://Assets/Fonts/PressStart2P.ttf")
	if not pixel_font:
		pixel_font = load("res://Assets/Fonts/ArcadeClassic.ttf")
	if pixel_font:
		apply_pixel_font_recursive(self, pixel_font)

	update_hud_instant()

func apply_pixel_font_recursive(node: Node, font: Font) -> void:
	if node is Label:
		node.add_theme_font_override("font", font)
		node.add_theme_constant_override("line_spacing", 6)
	elif node is Button:
		node.add_theme_font_override("font", font)
	for child in node.get_children():
		apply_pixel_font_recursive(child, font)

func _process(delta: float) -> void:
	# Score interpolation
	if displayed_score < current_score:
		displayed_score = move_toward(displayed_score, current_score, max(20.0, (current_score - displayed_score) * 12.0 * delta))
		score_label.text = "%06d" % int(displayed_score)

	# Power-up countdown timer & badge
	if GameSettings.power_up_timer > 0.0:
		GameSettings.power_up_timer -= delta
		if powerup_badge:
			powerup_badge.visible = true
			powerup_label.text = "PWR 2X + MAGNET: %.1fs" % GameSettings.power_up_timer
		if GameSettings.power_up_timer <= 0.0:
			GameSettings.is_multiplier_active = false
			GameSettings.is_magnet_active = false
			if powerup_badge:
				powerup_badge.visible = false
	elif powerup_badge and powerup_badge.visible:
		powerup_badge.visible = false

	# Update Skill Button UI state & unique character ability icon
	if skill_btn:
		skill_btn.text = ""
		var c_info: Dictionary = GameSettings.get_current_character()
		var s_icon_path: String = c_info.get("skill_icon", "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Yellow1.png")
		var icon_rect: TextureRect = skill_btn.get_node_or_null("Icon") as TextureRect
		if icon_rect:
			if icon_rect.texture == null or icon_rect.texture.resource_path != s_icon_path:
				var icon_tex: Texture2D = load(s_icon_path)
				if not icon_tex:
					icon_tex = load("res://Assets/AbilityIcons/Ability Icons/Icons (All)/Yellow1.png")
				if icon_tex:
					icon_rect.texture = icon_tex

		var hotkey_lbl: Label = skill_btn.get_node_or_null("HotkeyLabel") as Label
		if hotkey_lbl:
			hotkey_lbl.visible = false
			hotkey_lbl.text = ""
		if GameSettings.is_character_skill_used:
			skill_btn.disabled = true
			skill_btn.modulate = Color(0.4, 0.4, 0.4, 0.5)
		else:
			skill_btn.disabled = false
			skill_btn.modulate = Color.WHITE

func _input(event: InputEvent) -> void:
	var now := Time.get_ticks_msec()

	if is_counting_down and event.is_pressed() and not (event is InputEventMouseMotion):
		finish_countdown()
		return

	if chase_warning_modal and chase_warning_modal.visible:
		if now - modal_open_time >= 250:
			if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
				_on_dismiss_chase_warning()
		return

	if fact_modal and fact_modal.visible:
		if now - modal_open_time >= 250:
			if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
				_on_dismiss_fact_modal()
		return

	if boss_intro_modal and boss_intro_modal.visible:
		if now - modal_open_time >= 250:
			if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
				_on_start_boss_exam_pressed()
		return

	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_E or event.keycode == KEY_K):
		_on_skill_btn_pressed()
		return

	if (event.is_action_pressed("ui_cancel") and not event.is_echo()) or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P):
		if not game_over_menu.visible and (win_menu == null or not win_menu.visible) and not countdown_label.visible and (quiz_modal == null or not quiz_modal.visible):
			toggle_pause()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		if game_over_menu.visible or pause_menu.visible or (win_menu and win_menu.visible):
			get_tree().paused = false
			get_tree().reload_current_scene()

func _on_skill_btn_pressed() -> void:
	if GameSettings.is_character_skill_used or get_tree().paused:
		return
	var player_node: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player_node and player_node.has_method("trigger_unique_skill"):
		if player_node.trigger_unique_skill():
			play_click()
			var c_info: Dictionary = GameSettings.get_current_character()
			show_floating_text("PWR: %s ACTIVATED!" % c_info.get("skill_name", "SKILL").to_upper(), Vector2(80, 100), Color(0.2, 0.95, 0.5))

func start_countdown() -> void:
	is_counting_down = true
	countdown_label.visible = true
	get_tree().paused = true
	
	if toast_label:
		var c_info: Dictionary = GameSettings.get_current_character()
		toast_label.text = "RUNNER: %s" % c_info.get("name", "STUDENT").to_upper()
		toast_label.visible = true
		toast_label.modulate.a = 1.0
	
	for count in ["3", "2", "1", "RUN!"]:
		if not is_counting_down:
			break
		countdown_label.text = count
		countdown_label.scale = Vector2(0.6, 0.6)
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(countdown_label, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(countdown_label, "scale", Vector2.ONE, 0.08)
		play_click()
		await get_tree().create_timer(0.35).timeout

	finish_countdown()

func finish_countdown() -> void:
	if not is_counting_down and not countdown_label.visible:
		return
	is_counting_down = false
	countdown_label.visible = false
	get_tree().paused = false
	
	if toast_label and toast_label.visible:
		var tween := create_tween()
		tween.tween_interval(0.6)
		tween.tween_property(toast_label, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func():
			if toast_label:
				toast_label.visible = false
				toast_label.modulate.a = 1.0
		)
	
	emit_signal("countdown_finished")

# --- LIFELINES & POWER-UPS DISPLAY ---
func update_hud_instant() -> void:
	score_label.text = "%06d" % int(current_score)
	if coins_label:
		coins_label.text = "%d" % coins
	best_label.text = "BEST: %06d" % best_score
	update_hearts_display(GameSettings.lifelines)
	if knowledge_label:
		knowledge_label.text = "KNOW: %02d" % GameSettings.knowledge_score
	if hints_label:
		hints_label.text = "HINT: %d" % GameSettings.hints

func update_hearts_display(lifelines: int) -> void:
	GameSettings.lifelines = lifelines
	# Total slots is either 3 or 4 depending on character perk
	var max_hearts := 4 if (GameSettings.selected_character == "student_f_k" or lifelines > 3) else 3
	for i in range(heart_icons.size()):
		var icon = heart_icons[i]
		if icon and is_instance_valid(icon):
			if i < max_hearts:
				icon.visible = true
				if i < lifelines:
					icon.texture = tex_heart_full
				else:
					icon.texture = tex_heart_empty
			else:
				icon.visible = false

	# Also update quiz modal hearts if present
	for j in range(quiz_heart_icons.size()):
		var q_icon = quiz_heart_icons[j]
		if q_icon and is_instance_valid(q_icon):
			if j < max_hearts:
				q_icon.visible = true
				if j < lifelines:
					q_icon.texture = tex_heart_full
				else:
					q_icon.texture = tex_heart_empty
			else:
				q_icon.visible = false

func get_boss_hp_str(hp: int) -> String:
	var s = "HP: ["
	for i in range(5):
		if i < hp:
			s += "X "
		else:
			s += "_ "
	s = s.strip_edges() + "]"
	return s

# --- FACT MODAL (Boss-Style Paused Modal) ---
func show_knowledge_fact(fact: String) -> void:
	if fact_chime_sfx:
		fact_chime_sfx.play()
	update_hud_instant()
	if fact_modal_title:
		fact_modal_title.text = "KNOWLEDGE ACQUIRED!"
	if fact_modal_rule:
		fact_modal_rule.text = "\"%s\"\n\nREWARD: +10 KNOWLEDGE & 2X SCORE MULTIPLIER\n*(Remember this fact for your Final Exam!)*" % fact
	modal_open_time = Time.get_ticks_msec()
	get_tree().paused = true
	if fact_modal:
		fact_modal.visible = true

func show_memory_shard_banner(fact: String) -> void:
	if fact_chime_sfx:
		fact_chime_sfx.play()
	update_hud_instant()
	if fact_modal_title:
		fact_modal_title.text = "EXAM MEMORY RECOVERED!"
	if fact_modal_rule:
		fact_modal_rule.text = "\"%s\"\n\nREWARD: +50 SCORE & EXAM CLUE REVEALED\n*(Remember this fact for your Final Exam!)*" % fact
	modal_open_time = Time.get_ticks_msec()
	get_tree().paused = true
	if fact_modal:
		fact_modal.visible = true

func _on_dismiss_fact_modal() -> void:
	play_click()
	if fact_modal:
		fact_modal.visible = false
	get_tree().paused = false

# --- CHASE WARNING MODAL (Boss-Style Paused Modal) ---
func show_pre_chase_warning(msg: String) -> void:
	if hs_sfx:
		hs_sfx.play()
	if chase_warning_title:
		chase_warning_title.text = "CAMPUS PURSUIT ALERT"
	if chase_warning_rule:
		chase_warning_rule.text = "\"%s\"\n\nHEAD JANITOR IS IN PURSUIT!\nSprint forward, dodge obstacles, and outrun the chase!" % msg
	modal_open_time = Time.get_ticks_msec()
	get_tree().paused = true
	if chase_warning_modal:
		chase_warning_modal.visible = true

func show_chase_warning(chaser_name: String, speech_line: String = "") -> void:
	if hs_sfx:
		hs_sfx.play()
	if chase_warning_title:
		chase_warning_title.text = "CAMPUS PURSUIT ALERT"
	var speech_text = speech_line if speech_line != "" else "YOU'RE LATE!"
	if chase_warning_rule:
		chase_warning_rule.text = "\"%s\"\n\n%s IS IN PURSUIT!\nSprint forward, dodge obstacles, and outrun the chase!" % [speech_text, chaser_name.to_upper()]
	modal_open_time = Time.get_ticks_msec()
	get_tree().paused = true
	if chase_warning_modal:
		chase_warning_modal.visible = true

func _on_dismiss_chase_warning() -> void:
	play_click()
	if chase_warning_modal:
		chase_warning_modal.visible = false
	get_tree().paused = false

# --- TECHNICAL QUIZ MODAL ---
func show_tech_quiz(terminal_node: Node2D = null) -> void:
	if not quiz_modal:
		return
	if fact_toast_panel:
		fact_toast_panel.visible = false
	is_in_boss_battle = false
	active_quiz_terminal = terminal_node
	hint_used_for_current_q = false
	get_tree().paused = true
	quiz_modal.visible = true

	if quiz_title_label:
		quiz_title_label.text = "CAMPUS QUIZ"
	update_hearts_display(GameSettings.lifelines)
	if quiz_reward_hint:
		quiz_reward_hint.text = "REWARD: +5 COINS 🪙"

	update_hint_btn_ui()

	# Select question: if learned memory shards exist, 50% chance to test memory!
	var q_data: Dictionary
	if GameSettings.learned_memory_shards.size() > 0 and randf() < 0.6:
		var shard = GameSettings.learned_memory_shards[randi() % GameSettings.learned_memory_shards.size()]
		q_data = {
			"q": shard["q"],
			"correct": shard["correct"],
			"wrongs": shard["wrongs"]
		}
	else:
		q_data = QUIZ_QUESTIONS[randi() % QUIZ_QUESTIONS.size()]

	populate_quiz_ui(q_data)

func update_hint_btn_ui() -> void:
	if not quiz_hint_btn:
		return
	if GameSettings.hints > 0 and not hint_used_for_current_q:
		quiz_hint_btn.disabled = false
		quiz_hint_btn.text = "HINT: USE 50:50 (%d LEFT)" % GameSettings.hints
	else:
		quiz_hint_btn.disabled = true
		if hint_used_for_current_q:
			quiz_hint_btn.text = "HINT USED"
		else:
			quiz_hint_btn.text = "NO HINTS LEFT"

func populate_quiz_ui(q_data: Dictionary) -> void:
	quiz_q_label.text = q_data["q"]

	# Prepare 4 options: 1 correct + 3 wrongs
	var wrongs: Array = q_data["wrongs"].duplicate()
	while wrongs.size() < 3:
		wrongs.append("None of the above")
	wrongs.shuffle()

	var all_choices = [
		{"text": q_data["correct"], "is_correct": true},
		{"text": wrongs[0], "is_correct": false},
		{"text": wrongs[1], "is_correct": false},
		{"text": wrongs[2], "is_correct": false}
	]
	all_choices.shuffle()

	var prefixes = ["A. ", "B. ", "C. ", "D. "]
	for i in range(4):
		var btn = current_option_buttons[i]
		if btn:
			btn.disabled = false
			btn.visible = true
			btn.modulate = Color.WHITE
			btn.text = prefixes[i] + all_choices[i]["text"]
			if all_choices[i]["is_correct"]:
				current_correct_idx = i

func _on_hint_pressed() -> void:
	if hint_used_for_current_q:
		return
	if GameSettings.hints <= 0:
		if GameSettings.knowledge_score >= 50:
			GameSettings.knowledge_score -= 50
			GameSettings.hints += 1
			show_floating_text("HINT BOUGHT FOR 50 KNOWLEDGE!", Vector2(100, 100), Color(0.3, 0.9, 1.0))
		else:
			show_floating_text("NEED 50 KNOWLEDGE POINTS TO BUY HINT!", Vector2(80, 100), Color(1.0, 0.3, 0.3))
			return

	GameSettings.hints -= 1
	hint_used_for_current_q = true
	if hint_used_sfx:
		hint_used_sfx.play()
	update_hud_instant()
	update_hint_btn_ui()

	# Eliminate 2 incorrect options
	var wrong_indices: Array[int] = []
	for i in range(4):
		if i != current_correct_idx:
			wrong_indices.append(i)
	wrong_indices.shuffle()

	# Disable first two wrong choices
	for k in range(min(2, wrong_indices.size())):
		var w_idx = wrong_indices[k]
		var btn = current_option_buttons[w_idx]
		if btn:
			btn.disabled = true
			btn.modulate = Color(0.35, 0.35, 0.45, 0.4)

func _on_select_runner_pressed() -> void:
	play_click()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")

func _on_quiz_opt1_pressed() -> void:
	process_quiz_choice(0)

func _on_quiz_opt2_pressed() -> void:
	process_quiz_choice(1)

func _on_quiz_opt3_pressed() -> void:
	process_quiz_choice(2)

func _on_quiz_opt4_pressed() -> void:
	process_quiz_choice(3)

func process_quiz_choice(selected_idx: int) -> void:
	play_click()
	if is_in_boss_battle:
		process_boss_battle_choice(selected_idx)
	else:
		process_standard_quiz_choice(selected_idx)

func process_standard_quiz_choice(selected_idx: int) -> void:
	if not quiz_modal:
		return
	quiz_modal.visible = false
	get_tree().paused = false

	if selected_idx == current_correct_idx:
		if quiz_correct_sfx:
			quiz_correct_sfx.play()
		add_coin(5)
		add_score(250)
		GameSettings.knowledge_score += 50
		update_hud_instant()
		show_floating_text("CORRECT! +5 COINS! 🪙", Vector2(100, 110), Color(1.0, 0.85, 0.2))
	else:
		if quiz_wrong_sfx:
			quiz_wrong_sfx.play()
		var player_node: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D
		if player_node and player_node.has_method("trigger_hit_stop"):
			player_node.trigger_hit_stop(0.06)
		GameSettings.lifelines = max(0, GameSettings.lifelines - 1)
		update_hud_instant()
		show_floating_text("INCORRECT! LOST 1 LIFELINE!", Vector2(110, 110), Color(1.0, 0.4, 0.4))

	if is_instance_valid(active_quiz_terminal):
		active_quiz_terminal.deactivate_and_fade()
	active_quiz_terminal = null

	if GameSettings.lifelines <= 0:
		show_game_over_sequence("OUT OF LIFELINES")

# --- TEACHER FINAL BOSS BATTLE (PROF. STERLING) ---
func start_boss_battle(boss_node: Node2D) -> void:
	is_in_boss_battle = true
	active_boss_node = boss_node
	boss_hp = 5
	boss_round = 0
	boss_correct_count = 0
	if fact_toast_panel:
		fact_toast_panel.visible = false

	var teacher_info: Dictionary = GameSettings.get_current_teacher()

	# Populate boss question queue: prioritizing memory shards learned by player, then teacher's curriculum!
	boss_questions_queue.clear()
	var memory_shards = GameSettings.learned_memory_shards.duplicate()
	memory_shards.shuffle()
	for shard in memory_shards:
		boss_questions_queue.append({
			"q": shard["q"],
			"correct": shard["correct"],
			"wrongs": shard["wrongs"]
		})

	var teacher_questions: Array = teacher_info.get("questions", []).duplicate()
	teacher_questions.shuffle()
	for q in teacher_questions:
		if boss_questions_queue.size() >= 5:
			break
		boss_questions_queue.append(q)

	var general_pool = QUIZ_QUESTIONS.duplicate()
	general_pool.shuffle()
	for q in general_pool:
		if boss_questions_queue.size() >= 5:
			break
		boss_questions_queue.append(q)

	if boss_bar_panel:
		boss_bar_panel.visible = true
		if boss_face_rect:
			var face_tex = load(teacher_info.get("face", ""))
			if face_tex:
				boss_face_rect.texture = face_tex
		if boss_title_label:
			boss_title_label.text = "%s - LEVEL %d" % [teacher_info.get("name", "PROFESSOR").to_upper(), GameSettings.current_level]
		if boss_hp_label:
			boss_hp_label.text = get_boss_hp_str(boss_hp)
		if boss_progress_label:
			boss_progress_label.text = "EXAM: 1/5 (3/5 PASS)"

	show_boss_intro_modal()

func show_boss_intro_modal() -> void:
	modal_open_time = Time.get_ticks_msec()
	get_tree().paused = true
	var teacher_info: Dictionary = GameSettings.get_current_teacher()
	var next_lvl = min(10, GameSettings.current_level + 1)
	
	var quote: String = teacher_info.get("quote", "")
	var quote_str: String = ""
	if quote != "":
		quote_str = '"%s"\n\n' % quote

	if boss_intro_title:
		boss_intro_title.text = "LEVEL %d FINAL EXAM\n%s" % [GameSettings.current_level, teacher_info.get("name", "PROFESSOR").to_upper()]
	if boss_intro_rule:
		boss_intro_rule.text = quote_str + "PASS REQUIREMENT:\nAnswer AT LEAST 3 OUT OF 5 questions correctly to defeat the Professor and unlock Level %d!\n\nNOTE: Scoring less than 3/5 fails the exam and returns you to Level Start!" % next_lvl

	if boss_intro_modal:
		boss_intro_modal.visible = true

func _on_start_boss_exam_pressed() -> void:
	play_click()
	if boss_intro_modal:
		boss_intro_modal.visible = false
	present_next_boss_question()

func present_next_boss_question() -> void:
	if boss_round >= 5:
		finish_boss_battle()
		return

	var teacher_info: Dictionary = GameSettings.get_current_teacher()
	boss_round += 1
	hint_used_for_current_q = false
	get_tree().paused = true
	quiz_modal.visible = true

	if quiz_title_label:
		quiz_title_label.text = "%s: EXAM %d/5" % [teacher_info.get("name", "PROFESSOR").to_upper(), boss_round]
	update_hearts_display(GameSettings.lifelines)
	if quiz_reward_hint:
		quiz_reward_hint.text = "PASS: 3/5 (SCORE: %d)" % boss_correct_count

	if boss_progress_label:
		boss_progress_label.text = "EXAM: ROUND %d/5 (SCORE: %d)" % [boss_round, boss_correct_count]

	update_hint_btn_ui()

	var q_data: Dictionary
	if boss_round - 1 < boss_questions_queue.size():
		q_data = boss_questions_queue[boss_round - 1]
	else:
		q_data = QUIZ_QUESTIONS[randi() % QUIZ_QUESTIONS.size()]

	populate_quiz_ui(q_data)

func process_boss_battle_choice(selected_idx: int) -> void:
	quiz_modal.visible = false
	get_tree().paused = false

	var was_correct := (selected_idx == current_correct_idx)
	if was_correct:
		boss_correct_count += 1
		boss_hp = max(0, boss_hp - 1)
		if quiz_correct_sfx:
			quiz_correct_sfx.play()
		if boss_hp_label:
			boss_hp_label.text = get_boss_hp_str(boss_hp)
		if is_instance_valid(active_boss_node) and active_boss_node.has_method("take_exam_damage"):
			active_boss_node.take_exam_damage()
		show_floating_text("[OK] CORRECT! PROFESSOR DAMAGED!", Vector2(100, 100), Color(0.2, 0.95, 0.4))
	else:
		if quiz_wrong_sfx:
			quiz_wrong_sfx.play()
		GameSettings.lifelines = max(0, GameSettings.lifelines - 1)
		update_hud_instant()
		if is_instance_valid(active_boss_node) and active_boss_node.has_method("launch_exam_attack"):
			active_boss_node.launch_exam_attack()
		show_floating_text("[X] WRONG! PROFESSOR ATTACKS! LOST 1 LIFELINE!", Vector2(40, 100), Color(1.0, 0.35, 0.35))

	if boss_progress_label:
		boss_progress_label.text = "EXAM: ROUND %d/5 (SCORE: %d)" % [boss_round, boss_correct_count]

	if not was_correct and GameSettings.lifelines <= 0:
		await get_tree().create_timer(1.2).timeout
		if boss_bar_panel:
			boss_bar_panel.visible = false
		show_game_over_sequence("EXAM FAILED\nOUT OF LIFELINES")
		return

	await get_tree().create_timer(1.4).timeout
	present_next_boss_question()

func finish_boss_battle() -> void:
	if boss_bar_panel:
		boss_bar_panel.visible = false
	is_in_boss_battle = false
	var teacher_info: Dictionary = GameSettings.get_current_teacher()

	if boss_correct_count >= 3:
		# WIN: Passed the final exam!
		show_floating_text("--- FINAL EXAM PASSED! ---", Vector2(120, 80), Color(0.2, 0.95, 0.5))
		if is_instance_valid(active_boss_node) and active_boss_node.has_method("play_state"):
			active_boss_node.play_state("defeat")
		await get_tree().create_timer(1.0).timeout
		show_win_menu_sequence()
	else:
		# LOSE: Failed the final exam
		show_floating_text("--- EXAM FAILED (SCORE: %d/5) ---" % boss_correct_count, Vector2(60, 80), Color(1.0, 0.3, 0.3))
		await get_tree().create_timer(1.0).timeout
		show_game_over_sequence("EXAM FAILED\n%s" % teacher_info.get("name", "PROFESSOR").to_upper())

func show_win_menu_sequence() -> void:
	get_tree().paused = true
	var teacher_info: Dictionary = GameSettings.get_current_teacher()
	if win_menu:
		win_menu.visible = true
		var title_lbl: Label = win_menu.get_node_or_null("Panel/VBox/Title")
		var sub_lbl: Label = win_menu.get_node_or_null("Panel/VBox/Subtitle")
		var next_btn: Button = win_menu.get_node_or_null("Panel/VBox/ButtonContainer/NextLevelBtn")
		
		if GameSettings.current_level < 10:
			if title_lbl:
				title_lbl.text = "--- LEVEL %d CLEARED! ---" % GameSettings.current_level
			if sub_lbl:
				sub_lbl.text = "%s'S EXAM PASSED! ADVANCING TO LEVEL %d!" % [teacher_info.get("name", "TEACHER"), GameSettings.current_level + 1]
			if next_btn:
				next_btn.text = "NEXT LEVEL (LVL %d)" % (GameSettings.current_level + 1)
		else:
			if title_lbl:
				title_lbl.text = "--- GRADUATION DAY! ---"
			if sub_lbl:
				sub_lbl.text = "SUMMA CUM LAUDE! PRINCIPAL PENDELTON & ALL 10 PROFESSORS DEFEATED!"
			if next_btn:
				next_btn.text = "PLAY AGAIN"
				
		if win_stats_label:
			win_stats_label.text = "Score: %06d | Exam: %d/5 PASSED!" % [int(current_score), boss_correct_count]
		if hs_sfx:
			hs_sfx.play()

func _on_next_level_pressed() -> void:
	play_click()
	get_tree().paused = false
	if GameSettings.current_level < 10:
		GameSettings.current_level += 1
	else:
		GameSettings.current_level = 1
	OS.set_environment("COLLEGE_RUN_LEVEL", str(GameSettings.current_level))
	GameSettings.lifelines = 3
	GameSettings.is_multiplier_active = false
	GameSettings.is_magnet_active = false
	GameSettings.has_shield = false
	get_tree().reload_current_scene()

# --- STANDARD GAME SCORE & STATE ---
func add_score(amount: int) -> void:
	if GameSettings.is_multiplier_active:
		amount *= 2
	current_score += amount
	if int(current_score) > best_score:
		best_score = int(current_score)
		is_new_best = true
		save_best_score()
		best_label.text = "BEST: %06d" % best_score

func update_health(current_health: int, _max_health: int = 3) -> void:
	update_hearts_display(current_health)

func add_coin(amount: int = 1) -> void:
	coins += amount
	GameSettings.wallet_coins = coins
	GameSettings.save_wallet()
	add_score(100)
	if coin_icon:
		var tween := create_tween()
		coin_icon.scale = Vector2(1.4, 1.4)
		tween.tween_property(coin_icon, "scale", Vector2.ONE, 0.15)
	if coins_label:
		coins_label.text = "%d" % coins
		var tween := create_tween()
		coins_label.scale = Vector2(1.2, 1.2)
		tween.tween_property(coins_label, "scale", Vector2.ONE, 0.12)

func show_floating_text(text: String, global_pos: Vector2, color: Color = Color(0.98, 0.8, 0.08)) -> void:
	var label := Label.new()
	label.text = text
	label.top_level = true
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.09, 0.08, 0.15))
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_font_size_override("font_size", 10)
	label.global_position = global_pos
	add_child(label)
	
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(label, "global_position:y", global_pos.y - 25.0, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

func show_speed_up() -> void:
	toast_label.text = "SPEED UP!"
	toast_label.visible = true
	toast_label.scale = Vector2(0.5, 0.5)
	var tween := create_tween()
	tween.tween_property(toast_label, "scale", Vector2.ONE, 0.15)
	tween.tween_interval(0.6)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func(): toast_label.visible = false; toast_label.modulate.a = 1.0)

func show_game_over_sequence(custom_title: String = "") -> void:
	get_tree().paused = true
	game_over_menu.visible = true
	
	if custom_title != "":
		go_title.text = custom_title
	else:
		go_title.text = "GAME OVER"

	go_title.modulate.a = 0.0
	go_new_best.visible = false
	go_score_box.modulate.a = 0.0
	go_buttons.modulate.a = 0.0
	if go_revive_btn:
		go_revive_btn.modulate.a = 0.0
		if coins >= 50:
			go_revive_btn.text = "REVIVE HERE (50 COINS)"
			go_revive_btn.disabled = false
		else:
			go_revive_btn.text = "NEED 50 COINS (HAVE %d)" % coins
			go_revive_btn.disabled = true
	
	go_score_val.text = "%06d" % int(current_score)
	if go_coins_val:
		go_coins_val.text = "%d" % coins
	go_best_val.text = "%06d" % best_score
	
	await get_tree().create_timer(0.3).timeout
	var t1 := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t1.tween_property(go_title, "modulate:a", 1.0, 0.2)
	
	await get_tree().create_timer(0.2).timeout
	if is_new_best:
		go_new_best.visible = true
		if hs_sfx:
			hs_sfx.play()
	
	await get_tree().create_timer(0.2).timeout
	var t2 := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t2.tween_property(go_score_box, "modulate:a", 1.0, 0.2)
	
	await get_tree().create_timer(0.2).timeout
	if go_revive_btn:
		var t_rev := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t_rev.tween_property(go_revive_btn, "modulate:a", 1.0, 0.2)
	var t3 := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t3.tween_property(go_buttons, "modulate:a", 1.0, 0.2)

func _on_revive_pressed() -> void:
	if coins >= 50:
		play_click()
		coins -= 50
		GameSettings.wallet_coins = coins
		GameSettings.save_wallet()
		coins_label.text = "%d" % coins
		GameSettings.lifelines = 3
		update_hud_instant()
		game_over_menu.visible = false
		get_tree().paused = false
		emit_signal("revive_requested")
		show_floating_text("REVIVED! +3 LIVES!", Vector2(120, 100), Color(0.2, 0.95, 0.4))
	else:
		show_floating_text("NEED 50 COINS TO REVIVE!", Vector2(100, 100), Color(1.0, 0.3, 0.3))

func toggle_pause() -> void:
	var is_paused := not get_tree().paused
	get_tree().paused = is_paused
	pause_menu.visible = is_paused
	play_click()

func _on_resume_pressed() -> void:
	play_click()
	toggle_pause()

func _on_retry_pressed() -> void:
	play_click()
	get_tree().paused = false
	GameSettings.lifelines = 3
	GameSettings.is_multiplier_active = false
	GameSettings.is_magnet_active = false
	GameSettings.has_shield = false
	emit_signal("restart_requested")

func _on_menu_pressed() -> void:
	play_click()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")

func play_click() -> void:
	if click_sfx:
		click_sfx.play()

func load_best_score() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err == OK:
		best_score = config.get_value("save", "high_score", 0)
	else:
		best_score = 0

func save_best_score() -> void:
	var config := ConfigFile.new()
	config.set_value("save", "high_score", best_score)
	config.save(SAVE_PATH)
