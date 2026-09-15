extends Node

var selected_character: String = "student_m_a"
var current_level: int = 1 # Level 1 to 5

# Persistent player wallet coins across all runs, levels, and retries
var wallet_coins: int = 0
const SAVE_PATH = "user://rerun_save.cfg"

# Active Power-up states
var is_multiplier_active: bool = false
var is_magnet_active: bool = false
var has_shield: bool = false
var power_up_timer: float = 0.0

# Educational & Quiz mechanics
var lifelines: int = 3 # 3 Lifelines: ♥ ♥ ♥
var hints: int = 0 # 💡 Max 1 per level
var knowledge_score: int = 0 # 🧠 Knowledge points
var learned_memory_shards: Array[Dictionary] = []

func _ready() -> void:
	load_wallet()
	var env_lvl := OS.get_environment("COLLEGE_RUN_LEVEL")
	if env_lvl != "":
		current_level = clampi(int(env_lvl), 1, 10)

	var user_args := OS.get_cmdline_user_args()
	for i in range(user_args.size()):
		if user_args[i] == "--level" and i + 1 < user_args.size():
			current_level = clampi(int(user_args[i + 1]), 1, 10)

func save_wallet() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("player", "wallet_coins", wallet_coins)
	cfg.save(SAVE_PATH)

func load_wallet() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		wallet_coins = cfg.get_value("player", "wallet_coins", 0)

const STUDENT_KEYS = [
	"student_m_a", "student_m_b", "student_m_c", "student_m_d", "student_m_e", "student_m_f", "student_m_g", "student_m_h", "student_m_i", "student_m_j", "student_m_k",
	"student_f_a", "student_f_b", "student_f_c", "student_f_d", "student_f_e", "student_f_f", "student_f_g", "student_f_h", "student_f_i", "student_f_j", "student_f_k"
]

const CHARACTERS = {
	# 11 Male Students
	"student_m_a": {
		"id": "student_m_a",
		"name": "Leo Tanaka",
		"major": "Computer Science (Algorithms)",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_A.png",
		"sprite": "res://Assets/Player/runner_student_m_a.png",
		"desc": "Sprint Specialist — Navy Gakuran & Gold Buttons",
		"skill_name": "Optimized Velocity",
		"skill_desc": "+10% Base Sprint Speed & Faster Acceleration",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Yellow1.png"
	},
	"student_m_b": {
		"id": "student_m_b",
		"name": "Kai Sterling",
		"major": "Cybersecurity (Systems Defense)",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_B.png",
		"sprite": "res://Assets/Player/runner_student_m_b.png",
		"desc": "Security Hacker — Charcoal Stealth Blazer",
		"skill_name": "Firewall Shield",
		"skill_desc": "Starts level with an active Shield absorbing 1 hit",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Blue3.png"
	},
	"student_m_c": {
		"id": "student_m_c",
		"name": "Ren Takahashi",
		"major": "Game Development (Physics & 3D)",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_C.png",
		"sprite": "res://Assets/Player/runner_student_m_c.png",
		"desc": "Engine Architect — Slate Grey Blazer & Emerald Tie",
		"skill_name": "Low-Gravity Engine",
		"skill_desc": "+20% Jump Height & Floaty Aerial Control",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Green4.png"
	},
	"student_m_d": {
		"id": "student_m_d",
		"name": "Jin Mori",
		"major": "Cloud Systems & DevOps",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_D.png",
		"sprite": "res://Assets/Player/runner_student_m_d.png",
		"desc": "DevOps Architect — Cobalt Blue Blazer & Striped Tie",
		"skill_name": "Auto-Scaling Infrastructure",
		"skill_desc": "Auto-triggers emergency Shield when dropped to 1 HP",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Blue8.png"
	},
	"student_m_e": {
		"id": "student_m_e",
		"name": "Arata Sato",
		"major": "Robotics & Microcontrollers",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_E.png",
		"sprite": "res://Assets/Player/runner_student_m_e.png",
		"desc": "Hardware Specialist — Charcoal Vest & Crimson Tie",
		"skill_name": "Overclocked Actuators",
		"skill_desc": "Magnet Power-Ups last 15s instead of 10s",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Red5.png"
	},
	"student_m_f": {
		"id": "student_m_f",
		"name": "Daiki Kudo",
		"major": "Computer Graphics & Shaders",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_F.png",
		"sprite": "res://Assets/Player/runner_student_m_f.png",
		"desc": "Rendering Pro — Dark Navy Cardigan & White Shirt",
		"skill_name": "Bloom Radiance",
		"skill_desc": "2x Score Multipliers last +50% longer",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Yellow7.png"
	},
	"student_m_g": {
		"id": "student_m_g",
		"name": "Haruto Kuroda",
		"major": "Compilers & Systems (Rust/C++)",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_G.png",
		"sprite": "res://Assets/Player/runner_student_m_g.png",
		"desc": "Low-Level Coder — Midnight Black Jacket & Silver Pin",
		"skill_name": "Zero-Cost Abstraction",
		"skill_desc": "Doubles all Near-Miss hurdle bonus scores (+100)",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Purple2.png"
	},
	"student_m_h": {
		"id": "student_m_h",
		"name": "Kaito Minami",
		"major": "Distributed Computing",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_H.png",
		"sprite": "res://Assets/Player/runner_student_m_h.png",
		"desc": "Cluster Engineer — Forest Green Blazer & Gold Tie",
		"skill_name": "Cluster Load Balancer",
		"skill_desc": "+25% Bonus Score for every Coin Streak",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Green10.png"
	},
	"student_m_i": {
		"id": "student_m_i",
		"name": "Sora Tachibana",
		"major": "Bioinformatics & DNA Analysis",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_I.png",
		"sprite": "res://Assets/Player/runner_student_m_i.png",
		"desc": "Data Biologist — Sky Blue Blazer & Sapphire Ribbon",
		"skill_name": "Cellular Regeneration",
		"skill_desc": "Recovers 1 lost Heart (lifeline) after clearing Level Exam",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Red1.png"
	},
	"student_m_j": {
		"id": "student_m_j",
		"name": "Riku Nakajima",
		"major": "Silicon Architecture (RISC-V)",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_J.png",
		"sprite": "res://Assets/Player/runner_student_m_j.png",
		"desc": "Silicon Designer — Steel Grey Vest & Azure Tie",
		"skill_name": "Direct Memory Access",
		"skill_desc": "Earns +15 Knowledge Points per Question Block hit",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Blue12.png"
	},
	"student_m_k": {
		"id": "student_m_k",
		"name": "Shinjiro Ito",
		"major": "Quantum Computing & Cryptography",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_K.png",
		"sprite": "res://Assets/Player/runner_student_m_k.png",
		"desc": "Quantum Theorist — Deep Purple Blazer & Platinum Clip",
		"skill_name": "Quantum Superposition",
		"skill_desc": "Quizzes allow 1 mistake without losing a heart",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Purple14.png"
	},

	# 11 Female Students
	"student_f_a": {
		"id": "student_f_a",
		"name": "Maya Chen",
		"major": "Software Engineering (Protocols)",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_A.png",
		"sprite": "res://Assets/Player/runner_student_f_a.png",
		"desc": "Agile Coder — Navy Sailor Blazer & White Collar",
		"skill_name": "Agile Sprint",
		"skill_desc": "Slide duration extended +35% with speed bonus",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Yellow2.png"
	},
	"student_f_b": {
		"id": "student_f_b",
		"name": "Chloe Laurent",
		"major": "Data Science (Big Data Architecture)",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_B.png",
		"sprite": "res://Assets/Player/runner_student_f_b.png",
		"desc": "Data Analyst — Royal Navy & Crimson Ribbon",
		"skill_name": "Data Mining",
		"skill_desc": "+30% Bonus Coins collected from all trails",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Yellow10.png"
	},
	"student_f_c": {
		"id": "student_f_c",
		"name": "Aoi Hoshino",
		"major": "Artificial Intelligence (Neural Nets)",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_C.png",
		"sprite": "res://Assets/Player/runner_student_f_c.png",
		"desc": "Robotics Researcher — Charcoal Vest & Rose Ribbon",
		"skill_name": "Predictive AI",
		"skill_desc": "Quiz Hint removes 2 wrong options instead of 1",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Purple9.png"
	},
	"student_f_d": {
		"id": "student_f_d",
		"name": "Yuna Kirishima",
		"major": "Network Security & Penetration Testing",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_D.png",
		"sprite": "res://Assets/Player/runner_student_f_d.png",
		"desc": "Ethical Hacker — Midnight Blue Sailor Suit & Teal Scarf",
		"skill_name": "Exploit Bypass",
		"skill_desc": "Smashes 1 Traffic Barrier per level harmlessly",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Red9.png"
	},
	"student_f_e": {
		"id": "student_f_e",
		"name": "Hana Fujisaki",
		"major": "Human-Computer Interaction & UX",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_E.png",
		"sprite": "res://Assets/Player/runner_student_f_e.png",
		"desc": "Interface Designer — Powder Blue Blazer & Ribbon Bow",
		"skill_name": "Ergonomic Buffer",
		"skill_desc": "Grants +5 extra seconds during Quiz questions",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/White6.png"
	},
	"student_f_f": {
		"id": "student_f_f",
		"name": "Rin Shinguji",
		"major": "Cryptographic Engineering (ZK Proofs)",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_F.png",
		"sprite": "res://Assets/Player/runner_student_f_f.png",
		"desc": "Cryptographer — Raven Black Blazer & Violet Ribbon",
		"skill_name": "Phantom Magnetism",
		"skill_desc": "Passive coin magnet active at 2x pickup range",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Purple6.png"
	},
	"student_f_g": {
		"id": "student_f_g",
		"name": "Mei Lin",
		"major": "Computer Vision & NeRFs",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_G.png",
		"sprite": "res://Assets/Player/runner_student_f_g.png",
		"desc": "Vision Researcher — Emerald Green Sailor Uniform",
		"skill_name": "Thermal Vision HUD",
		"skill_desc": "Highlights upcoming spikes & pipes with warning trails",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Green7.png"
	},
	"student_f_h": {
		"id": "student_f_h",
		"name": "Sayaka Endo",
		"major": "Database Storage Engines",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_H.png",
		"sprite": "res://Assets/Player/runner_student_f_h.png",
		"desc": "Storage Architect — Burgundy Blazer & Gold Hairpin",
		"skill_name": "B-Tree Indexing",
		"skill_desc": "Starts level with 2 free Hints (💡) instead of 1",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/White11.png"
	},
	"student_f_i": {
		"id": "student_f_i",
		"name": "Sakura Hirasawa",
		"major": "Operating Systems & Kernels",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_I.png",
		"sprite": "res://Assets/Player/runner_student_f_i.png",
		"desc": "Kernel Hacker — Classic Navy Blazer & Pink Ribbon",
		"skill_name": "Interrupt Handler",
		"skill_desc": "Invulnerability after damage increased to 3.0s",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Red12.png"
	},
	"student_f_j": {
		"id": "student_f_j",
		"name": "Nozomi Kasai",
		"major": "Embedded Sensor Networks",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_J.png",
		"sprite": "res://Assets/Player/runner_student_f_j.png",
		"desc": "Firmware Engineer — Slate Grey Uniform & Yellow Scarf",
		"skill_name": "Proximity Sensor",
		"skill_desc": "Near-miss detection range increased +50% (+75 pts)",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Yellow14.png"
	},
	"student_f_k": {
		"id": "student_f_k",
		"name": "Erika Von Braun",
		"major": "Autonomous Cybernetics",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_K.png",
		"sprite": "res://Assets/Player/runner_student_f_k.png",
		"desc": "Cybernetics Lead — Alpine Navy Blazer & Crimson Cravat",
		"skill_name": "Nanite Hull Upgrade",
		"skill_desc": "Starts level with 4 Hearts (♥ ♥ ♥ ♥)",
		"skill_icon": "res://Assets/AbilityIcons/Ability Icons/Icons (All)/Red15.png"
	}
}

const LEVEL_TEACHERS = {
	1: {
		"name": "Prof. Sterling",
		"title": "Level 1: Computer Systems & Core Data Structures",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Teacher_M_A.png",
		"sprite": "res://Assets/KW_School_Characters/16x16 Character/Teacher_M_A.png",
		"subject": "ALGORITHMS & BIG-O",
		"sign": "🏛️ LEVEL 1: PROF. STERLING'S EXAMINATION HALL 🏛️",
		"questions": [
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
				"q": "How many bits are in a single standard byte of memory?",
				"correct": "8 bits",
				"wrongs": ["4 bits", "16 bits", "32 bits"]
			}
		]
	},
	2: {
		"name": "Dr. Evelyn Vance",
		"title": "Level 2: Computer Networks & Cyber Infrastructure",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Teacher_F_A.png",
		"sprite": "res://Assets/KW_School_Characters/16x16 Character/Teacher_F_A.png",
		"subject": "NETWORKING & SECURITY",
		"sign": "🏛️ LEVEL 2: DR. EVELYN VANCE'S CYBER LAB 🏛️",
		"questions": [
			{
				"q": "What default port is used worldwide for encrypted HTTPS network traffic?",
				"correct": "Port 443",
				"wrongs": ["Port 80", "Port 22", "Port 8080"]
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
			},
			{
				"q": "What type of cryptographic key pair does RSA public-key encryption use?",
				"correct": "Public and Private keys",
				"wrongs": ["Shared secret key only", "Single symmetric session key", "MAC hash only"]
			},
			{
				"q": "How many packets are exchanged in a standard TCP connection handshake?",
				"correct": "3 (SYN, SYN-ACK, ACK)",
				"wrongs": ["2 (SYN, ACK)", "4 (SYN, PING, PONG, ACK)", "1 (CONNECT)"]
			}
		]
	},
	3: {
		"name": "Prof. Marcus Thorne",
		"title": "Level 3: Database Architecture & Cloud Scaling",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Teacher_M_B.png",
		"sprite": "res://Assets/KW_School_Characters/16x16 Character/Teacher_M_B.png",
		"subject": "DATABASES & CLOUD",
		"sign": "🏛️ LEVEL 3: PROF. THORNE'S DATABASE ARENA 🏛️",
		"questions": [
			{
				"q": "What does SQL stand for in relational database management?",
				"correct": "Structured Query Language",
				"wrongs": ["Sequential Quick Logic", "System Query Link", "Standard Queue Logic"]
			},
			{
				"q": "In database transactions, what does the 'A' in ACID properties stand for?",
				"correct": "Atomicity",
				"wrongs": ["Asynchrony", "Authentication", "Allocation"]
			},
			{
				"q": "Which data structure is most commonly used for relational database table indexing?",
				"correct": "B+ Tree",
				"wrongs": ["Linked List", "Adjacency Matrix", "Queue"]
			},
			{
				"q": "Which SQL clause is used to filter records resulting from an aggregate GROUP BY?",
				"correct": "HAVING",
				"wrongs": ["WHERE", "ORDER BY", "FILTER"]
			},
			{
				"q": "What technology packages an application and its dependencies into an isolated container?",
				"correct": "Docker",
				"wrongs": ["Git", "Apache Kafka", "Redis"]
			}
		]
	},
	4: {
		"name": "Dr. Samantha Hayes",
		"title": "Level 4: Artificial Intelligence & Neural Networks",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Teacher_F_B.png",
		"sprite": "res://Assets/KW_School_Characters/16x16 Character/Teacher_F_B.png",
		"subject": "AI & NEURAL NETWORKS",
		"sign": "🏛️ LEVEL 4: DR. HAYES'S AI RESEARCH HALL 🏛️",
		"questions": [
			{
				"q": "Which algorithm calculates gradients via the chain rule to train Neural Networks?",
				"correct": "Backpropagation",
				"wrongs": ["Dijkstra's Algorithm", "Binary Search", "Breadth-First Search"]
			},
			{
				"q": "Which Python keyword defines an anonymous inline lambda function?",
				"correct": "lambda",
				"wrongs": ["inline", "def", "func"]
			},
			{
				"q": "When an AI model performs exceptionally on training data but poorly on test data, it is:",
				"correct": "Overfitting",
				"wrongs": ["Underfitting", "Converging", "Quantizing"]
			},
			{
				"q": "Which non-linear activation function maps input values into the range [0, 1]?",
				"correct": "Sigmoid",
				"wrongs": ["ReLU", "Linear Step", "Softplus"]
			},
			{
				"q": "In NLP and vector databases, what metric measures the angle between two semantic vectors?",
				"correct": "Cosine Similarity",
				"wrongs": ["Manhattan Distance", "Hamming Distance", "Jaccard Index"]
			}
		]
	},
	5: {
		"name": "Prof. Vikram Patel",
		"title": "Level 5: Operating Systems & Compiler Design",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Teacher_M_C.png",
		"sprite": "res://Assets/KW_School_Characters/16x16 Character/Teacher_M_C.png",
		"subject": "KERNELS & COMPILERS",
		"sign": "🏛️ LEVEL 5: PROF. PATEL'S KERNEL LAB 🏛️",
		"questions": [
			{
				"q": "Which OS scheduling state occurs when a process waits for I/O completion?",
				"correct": "Blocked / Waiting",
				"wrongs": ["Running", "Ready", "Terminated"]
			},
			{
				"q": "In compiler optimization, what phase converts AST into machine code instructions?",
				"correct": "Code Generation",
				"wrongs": ["Lexical Analysis", "Parsing", "Semantic Analysis"]
			},
			{
				"q": "What mechanism allows virtual memory addresses to translate into physical RAM locations?",
				"correct": "Page Table & MMU",
				"wrongs": ["DMA Controller", "Bus Arbiter", "Cache L1"]
			},
			{
				"q": "Which system call in Unix/Linux creates a duplicate child process?",
				"correct": "fork()",
				"wrongs": ["exec()", "clone()", "spawn()"]
			},
			{
				"q": "What condition occurs when two processes wait infinitely for resources held by each other?",
				"correct": "Deadlock",
				"wrongs": ["Race Condition", "Starvation", "Livelock"]
			}
		]
	},
	6: {
		"name": "Dr. Beatrice Dupont",
		"title": "Level 6: Distributed Systems & Microservices",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Teacher_F_C.png",
		"sprite": "res://Assets/KW_School_Characters/16x16 Character/Teacher_F_C.png",
		"subject": "DISTRIBUTED CLUSTERS",
		"sign": "🏛️ LEVEL 6: DR. DUPONT'S CLUSTER AUDITORIUM 🏛️",
		"questions": [
			{
				"q": "In CAP theorem, what does the 'P' stand for?",
				"correct": "Partition Tolerance",
				"wrongs": ["Performance", "Parallelism", "Persistence"]
			},
			{
				"q": "Which consensus algorithm is widely used in Raft and Paxos implementations?",
				"correct": "Leader Election",
				"wrongs": ["Round Robin", "Least Connections", "Consistent Hashing"]
			},
			{
				"q": "What architectural pattern decouples services via publish-subscribe message brokers?",
				"correct": "Event-Driven Architecture",
				"wrongs": ["Monolithic Core", "Shared Memory", "Direct RPC"]
			},
			{
				"q": "Which caching strategy writes data to cache and DB simultaneously?",
				"correct": "Write-Through",
				"wrongs": ["Write-Back", "Cache-Aside", "Write-Around"]
			},
			{
				"q": "What metric measures the maximum rate of data transmission over a network path?",
				"correct": "Bandwidth",
				"wrongs": ["Latency", "Jitter", "Throughput"]
			}
		]
	},
	7: {
		"name": "Prof. Kenji Takahashi",
		"title": "Level 7: Computer Graphics & GPU Shaders",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Teacher_M_D.png",
		"sprite": "res://Assets/KW_School_Characters/16x16 Character/Teacher_M_D.png",
		"subject": "GRAPHICS & RAYS",
		"sign": "🏛️ LEVEL 7: PROF. TAKAHASHI'S RENDERING STUDIO 🏛️",
		"questions": [
			{
				"q": "Which GPU shader stage runs per vertex to project 3D space into 2D coordinates?",
				"correct": "Vertex Shader",
				"wrongs": ["Fragment Shader", "Compute Shader", "Tessellation Shader"]
			},
			{
				"q": "What matrix transforms model coordinates into world space coordinates?",
				"correct": "Model Matrix",
				"wrongs": ["Projection Matrix", "View Matrix", "Normal Matrix"]
			},
			{
				"q": "Which lighting model combines Ambient, Diffuse, and Specular light components?",
				"correct": "Phong Reflection Model",
				"wrongs": ["Ray Marching", "Radiosity", "Subsurface Scattering"]
			},
			{
				"q": "What texture filtering technique prevents aliasing on distant tilted surfaces?",
				"correct": "Anisotropic Filtering",
				"wrongs": ["Bilinear Filtering", "Nearest Neighbor", "Trilinear Filtering"]
			},
			{
				"q": "What rendering technique simulates realistic lighting by tracing ray paths?",
				"correct": "Ray Tracing",
				"wrongs": ["Rasterization", "Sprite Stacking", "Z-Buffering"]
			}
		]
	},
	8: {
		"name": "Dr. Sofia Rodriguez",
		"title": "Level 8: Embedded Robotics & Microcontrollers",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Teacher_F_D.png",
		"sprite": "res://Assets/KW_School_Characters/16x16 Character/Teacher_F_D.png",
		"subject": "EMBEDDED ROBOTICS",
		"sign": "🏛️ LEVEL 8: DR. RODRIGUEZ'S ROBOTICS HANGAR 🏛️",
		"questions": [
			{
				"q": "What type of controller uses Proportional, Integral, and Derivative feedback?",
				"correct": "PID Controller",
				"wrongs": ["Bang-Bang Controller", "State Machine", "PWM Driver"]
			},
			{
				"q": "Which serial bus protocol uses SDA and SCL lines for multi-master communication?",
				"correct": "I2C Bus",
				"wrongs": ["SPI Bus", "UART Serial", "CAN Bus"]
			},
			{
				"q": "What technique controls motor speed by varying signal pulse width on/off ratios?",
				"correct": "PWM (Pulse-Width Modulation)",
				"wrongs": ["Frequency Modulation", "Amplitude Shift", "Phase Inversion"]
			},
			{
				"q": "Which sensor measures angular velocity and orientation changes in robotics?",
				"correct": "Gyroscope",
				"wrongs": ["Barometer", "Thermistor", "Hall Effect Sensor"]
			},
			{
				"q": "What component prevents inductive voltage spikes from damaging microcontroller pins when driving motors?",
				"correct": "Flyback Diode",
				"wrongs": ["Pull-up Resistor", "Zener Diode", "Decoupling Capacitor"]
			}
		]
	},
	9: {
		"name": "Prof. Alexander Wright",
		"title": "Level 9: Advanced Cryptography & Quantum Computing",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Teacher_M_E.png",
		"sprite": "res://Assets/KW_School_Characters/16x16 Character/Teacher_M_E.png",
		"subject": "QUANTUM COMPUTING",
		"sign": "🏛️ LEVEL 9: PROF. WRIGHT'S QUANTUM LAB 🏛️",
		"questions": [
			{
				"q": "What fundamental quantum phenomenon allows qubits to exist in 0, 1, or both states simultaneously?",
				"correct": "Superposition",
				"wrongs": ["Entanglement", "Quantum Tunneling", "Decoherence"]
			},
			{
				"q": "Which quantum algorithm provides quadratic speedup for unstructured database search?",
				"correct": "Grover's Algorithm",
				"wrongs": ["Shor's Algorithm", "Deutsch-Jozsa", "Simon's Algorithm"]
			},
			{
				"q": "What post-quantum cryptography approach relies on high-dimensional mathematical lattices?",
				"correct": "Lattice-Based Cryptography",
				"wrongs": ["RSA 4096", "Elliptic Curve ED25519", "Diffie-Hellman"]
			},
			{
				"q": "What unit of quantum information is the 2-state quantum mechanical system equivalent of a classical bit?",
				"correct": "Qubit",
				"wrongs": ["Qbyte", "Quat", "Trit"]
			},
			{
				"q": "Which quantum principle prevents copying an unknown quantum state exactly?",
				"correct": "No-Cloning Theorem",
				"wrongs": ["Heisenberg Uncertainty", "Pauli Exclusion", "Bell Inequality"]
			}
		]
	},
	10: {
		"name": "Principal Arthur Pendelton",
		"title": "Level 10: Grand Capstone Examination & Graduation Finals",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Other_M_B.png",
		"sprite": "res://Assets/KW_School_Characters/16x16 Character/Other_M_B.png",
		"subject": "GRAND FINALS (ALL SUBJECTS)",
		"sign": "🏛️ LEVEL 10: PRINCIPAL PENDELTON'S GRAND CAPSTONE AUDITORIUM 🏛️",
		"quote": "So... you have finally come!",
		"questions": [
			{
				"q": "In Git, which command stages all modified and newly created files in workspace?",
				"correct": "git add .",
				"wrongs": ["git push -all", "git commit -a", "git stage --hard"]
			},
			{
				"q": "What millennium prize problem asks if P equals NP in computational complexity?",
				"correct": "P versus NP",
				"wrongs": ["Halting Problem", "Turing Completeness", "Traveling Salesperson"]
			},
			{
				"q": "Which cryptographic hash function produces a 256-bit fixed-size digest?",
				"correct": "SHA-256",
				"wrongs": ["MD5", "CRC32", "AES-256"]
			},
			{
				"q": "Which computer architecture component predicts which direction a conditional branch will take?",
				"correct": "Branch Predictor",
				"wrongs": ["ALU Register", "Cache Controller", "TLB Buffer"]
			},
			{
				"q": "In distributed computing, CAP theorem states you can choose at most two of: Consistency, Partition tolerance, and:",
				"correct": "Availability",
				"wrongs": ["Authentication", "Accuracy", "Atomicity"]
			}
		]
	}
}

var is_character_skill_used: bool = false

func reset_run_state() -> void:
	is_multiplier_active = false
	is_magnet_active = false
	has_shield = false
	is_character_skill_used = false
	power_up_timer = 0.0
	lifelines = 3
	hints = 0
	knowledge_score = 0
	learned_memory_shards.clear()

func activate_tech_power_up(duration: float = 10.0) -> void:
	is_multiplier_active = true
	is_magnet_active = true
	has_shield = true
	power_up_timer = duration

func get_current_character() -> Dictionary:
	var key: String = selected_character
	if CHARACTERS.has(key) and CHARACTERS[key].has("alias"):
		key = CHARACTERS[key]["alias"]
	if CHARACTERS.has(key):
		return CHARACTERS[key]
	return CHARACTERS["student_m_a"]


func get_current_teacher() -> Dictionary:
	var lvl: int = clampi(current_level, 1, 10)
	if LEVEL_TEACHERS.has(lvl):
		return LEVEL_TEACHERS[lvl]
	return LEVEL_TEACHERS[1]
