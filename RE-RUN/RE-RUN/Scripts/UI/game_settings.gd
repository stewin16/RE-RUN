class_name GameSettings
extends RefCounted

static var selected_character: String = "student_m_a"
static var current_level: int = 1 # Level 1 to 5

# Active Power-up states
static var is_multiplier_active: bool = false
static var is_magnet_active: bool = false
static var has_shield: bool = false
static var power_up_timer: float = 0.0

# Educational & Quiz mechanics
static var lifelines: int = 3 # 3 Lifelines: ♥ ♥ ♥
static var hints: int = 0 # 💡 Max 1 per level
static var knowledge_score: int = 0 # 🧠 Knowledge points
static var learned_memory_shards: Array[Dictionary] = []

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
		"desc": "Sprint Specialist — Navy Gakuran & Gold Buttons"
	},
	"student_m_b": {
		"id": "student_m_b",
		"name": "Kai Sterling",
		"major": "Cybersecurity (Systems Defense)",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_B.png",
		"sprite": "res://Assets/Player/runner_student_m_b.png",
		"desc": "Security Hacker — Charcoal Stealth Blazer"
	},
	"student_m_c": {
		"id": "student_m_c",
		"name": "Ren Takahashi",
		"major": "Game Development (Physics & 3D)",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_C.png",
		"sprite": "res://Assets/Player/runner_student_m_c.png",
		"desc": "Engine Architect — Slate Grey Blazer & Emerald Tie"
	},
	"student_m_d": {
		"id": "student_m_d",
		"name": "Jin Mori",
		"major": "Cloud Systems & DevOps",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_D.png",
		"sprite": "res://Assets/Player/runner_student_m_d.png",
		"desc": "DevOps Architect — Cobalt Blue Blazer & Striped Tie"
	},
	"student_m_e": {
		"id": "student_m_e",
		"name": "Arata Sato",
		"major": "Robotics & Microcontrollers",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_E.png",
		"sprite": "res://Assets/Player/runner_student_m_e.png",
		"desc": "Hardware Specialist — Charcoal Vest & Crimson Tie"
	},
	"student_m_f": {
		"id": "student_m_f",
		"name": "Daiki Kudo",
		"major": "Computer Graphics & Shaders",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_F.png",
		"sprite": "res://Assets/Player/runner_student_m_f.png",
		"desc": "Rendering Pro — Dark Navy Cardigan & White Shirt"
	},
	"student_m_g": {
		"id": "student_m_g",
		"name": "Haruto Kuroda",
		"major": "Compilers & Systems (Rust/C++)",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_G.png",
		"sprite": "res://Assets/Player/runner_student_m_g.png",
		"desc": "Low-Level Coder — Midnight Black Jacket & Silver Pin"
	},
	"student_m_h": {
		"id": "student_m_h",
		"name": "Kaito Minami",
		"major": "Distributed Computing",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_H.png",
		"sprite": "res://Assets/Player/runner_student_m_h.png",
		"desc": "Cluster Engineer — Forest Green Blazer & Gold Tie"
	},
	"student_m_i": {
		"id": "student_m_i",
		"name": "Sora Tachibana",
		"major": "Bioinformatics & DNA Analysis",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_I.png",
		"sprite": "res://Assets/Player/runner_student_m_i.png",
		"desc": "Data Biologist — Sky Blue Blazer & Sapphire Ribbon"
	},
	"student_m_j": {
		"id": "student_m_j",
		"name": "Riku Nakajima",
		"major": "Silicon Architecture (RISC-V)",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_J.png",
		"sprite": "res://Assets/Player/runner_student_m_j.png",
		"desc": "Silicon Designer — Steel Grey Vest & Azure Tie"
	},
	"student_m_k": {
		"id": "student_m_k",
		"name": "Shinjiro Ito",
		"major": "Quantum Computing & Cryptography",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_M_K.png",
		"sprite": "res://Assets/Player/runner_student_m_k.png",
		"desc": "Quantum Theorist — Deep Purple Blazer & Platinum Clip"
	},

	# 11 Female Students
	"student_f_a": {
		"id": "student_f_a",
		"name": "Maya Chen",
		"major": "Software Engineering (Protocols)",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_A.png",
		"sprite": "res://Assets/Player/runner_student_f_a.png",
		"desc": "Agile Coder — Navy Sailor Blazer & White Collar"
	},
	"student_f_b": {
		"id": "student_f_b",
		"name": "Chloe Laurent",
		"major": "Data Science (Big Data Architecture)",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_B.png",
		"sprite": "res://Assets/Player/runner_student_f_b.png",
		"desc": "Data Analyst — Royal Navy & Crimson Ribbon"
	},
	"student_f_c": {
		"id": "student_f_c",
		"name": "Aoi Hoshino",
		"major": "Artificial Intelligence (Neural Nets)",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_C.png",
		"sprite": "res://Assets/Player/runner_student_f_c.png",
		"desc": "Robotics Researcher — Charcoal Vest & Rose Ribbon"
	},
	"student_f_d": {
		"id": "student_f_d",
		"name": "Yuna Kirishima",
		"major": "Network Security & Penetration Testing",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_D.png",
		"sprite": "res://Assets/Player/runner_student_f_d.png",
		"desc": "Ethical Hacker — Midnight Blue Sailor Suit & Teal Scarf"
	},
	"student_f_e": {
		"id": "student_f_e",
		"name": "Hana Fujisaki",
		"major": "Human-Computer Interaction & UX",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_E.png",
		"sprite": "res://Assets/Player/runner_student_f_e.png",
		"desc": "Interface Designer — Powder Blue Blazer & Ribbon Bow"
	},
	"student_f_f": {
		"id": "student_f_f",
		"name": "Rin Shinguji",
		"major": "Cryptographic Engineering (ZK Proofs)",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_F.png",
		"sprite": "res://Assets/Player/runner_student_f_f.png",
		"desc": "Cryptographer — Raven Black Blazer & Violet Ribbon"
	},
	"student_f_g": {
		"id": "student_f_g",
		"name": "Mei Lin",
		"major": "Computer Vision & NeRFs",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_G.png",
		"sprite": "res://Assets/Player/runner_student_f_g.png",
		"desc": "Vision Researcher — Emerald Green Sailor Uniform"
	},
	"student_f_h": {
		"id": "student_f_h",
		"name": "Sayaka Endo",
		"major": "Database Storage Engines",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_H.png",
		"sprite": "res://Assets/Player/runner_student_f_h.png",
		"desc": "Storage Architect — Burgundy Blazer & Gold Hairpin"
	},
	"student_f_i": {
		"id": "student_f_i",
		"name": "Sakura Hirasawa",
		"major": "Operating Systems & Kernels",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_I.png",
		"sprite": "res://Assets/Player/runner_student_f_i.png",
		"desc": "Kernel Hacker — Classic Navy Blazer & Pink Ribbon"
	},
	"student_f_j": {
		"id": "student_f_j",
		"name": "Nozomi Kasai",
		"major": "Embedded Sensor Networks",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_J.png",
		"sprite": "res://Assets/Player/runner_student_f_j.png",
		"desc": "Firmware Engineer — Slate Grey Uniform & Yellow Scarf"
	},
	"student_f_k": {
		"id": "student_f_k",
		"name": "Erika Von Braun",
		"major": "Autonomous Cybernetics",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Student_F_K.png",
		"sprite": "res://Assets/Player/runner_student_f_k.png",
		"desc": "Cybernetics Lead — Alpine Navy Blazer & Crimson Cravat"
	},

	# Backward-compatible short aliases
	"leo": { "alias": "student_m_a" },
	"maya": { "alias": "student_f_a" },
	"kai": { "alias": "student_m_b" },
	"chloe": { "alias": "student_f_b" },
	"ren": { "alias": "student_m_c" },
	"aoi": { "alias": "student_f_c" }
}

const LEVEL_TEACHERS = {
	1: {
		"name": "Prof. Sterling",
		"title": "Semester 1: Computer Systems & Core Data Structures",
		"sprite": "res://Assets/Characters/teacher_lvl1.png",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Teacher_M_A.png",
		"subject": "ALGORITHMS & BIG-O",
		"sign": "🏛️ SEMESTER 1: PROF. STERLING'S EXAMINATION HALL 🏛️",
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
		"title": "Semester 2: Computer Networks & Cyber Infrastructure",
		"sprite": "res://Assets/Characters/teacher_lvl2.png",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Teacher_F_A.png",
		"subject": "NETWORKING & SECURITY",
		"sign": "🏛️ SEMESTER 2: DR. EVELYN VANCE'S CYBER LAB 🏛️",
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
		"title": "Semester 3: Database Architecture & Cloud Scaling",
		"sprite": "res://Assets/Characters/teacher_lvl3.png",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Teacher_M_B.png",
		"subject": "DATABASES & CLOUD",
		"sign": "🏛️ SEMESTER 3: PROF. THORNE'S DATABASE ARENA 🏛️",
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
		"title": "Semester 4: Artificial Intelligence & Machine Learning",
		"sprite": "res://Assets/Characters/teacher_lvl4.png",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Teacher_F_B.png",
		"subject": "AI & NEURAL NETWORKS",
		"sign": "🏛️ SEMESTER 4: DR. HAYES'S AI RESEARCH HALL 🏛️",
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
		"name": "Dean Arthur Vance",
		"title": "Semester 5: Capstone Review & The Grand Examination",
		"sprite": "res://Assets/Characters/teacher_lvl5.png",
		"face": "res://Assets/KW_School_Characters/64X64 Face/Teacher_M_C.png",
		"subject": "CAPSTONE EXAMINATION",
		"sign": "🏛️ GRAND FINALS: DEAN ARTHUR'S CAPSTONE AUDITORIUM 🏛️",
		"questions": [
			{
				"q": "In Git, which command stages all modified and newly created files in workspace?",
				"correct": "git add .",
				"wrongs": ["git push -all", "git commit -a", "git stage --hard"]
			},
			{
				"q": "What problem asks if every problem whose solution can be quickly verified can also be solved quickly?",
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

static func reset_run_state() -> void:
	is_multiplier_active = false
	is_magnet_active = false
	has_shield = false
	power_up_timer = 0.0
	lifelines = 3
	hints = 0
	knowledge_score = 0
	learned_memory_shards.clear()

static func activate_tech_power_up(duration: float = 10.0) -> void:
	is_multiplier_active = true
	is_magnet_active = true
	has_shield = true
	power_up_timer = duration

static func get_current_character() -> Dictionary:
	var key: String = selected_character
	if CHARACTERS.has(key) and CHARACTERS[key].has("alias"):
		key = CHARACTERS[key]["alias"]
	if CHARACTERS.has(key):
		return CHARACTERS[key]
	return CHARACTERS["student_m_a"]


static func get_current_teacher() -> Dictionary:
	var lvl: int = clampi(current_level, 1, 5)
	if LEVEL_TEACHERS.has(lvl):
		return LEVEL_TEACHERS[lvl]
	return LEVEL_TEACHERS[1]
