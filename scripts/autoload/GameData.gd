extends Node
## Центральное хранилище состояния игры "Питомец Финни".

signal state_changed
signal toast(message: String)

const SAVE_PATH := "user://save_game.json"
const PERIOD_LENGTH := 5
const DAILY_INCOME := 25
const LOGIN_BONUS := 10
const SAVINGS_RATE := 0.05
const MINIGAME_REWARD_PER_COIN := 1

var shop_items: Array = []
var tasks: Array = []
var goals_catalog: Array = []
var glossary: Array = []

# ---- профиль ----
var first_launch: bool = true
var pet_created: bool = false
var pet_name: String = "Финни"
var body_color_index: int = 0
var pattern_index: int = 0
var equipped_hat: String = ""
var pet_stage: int = 0
var growth_points: int = 0

var mood: int = 80
var hunger: int = 80

var wallet: int = 60           # монеты, ждущие распределения
var mandatory_budget: int = 0  # кошелёк "обязательное"
var optional_budget: int = 0   # кошелёк "желаемое"
var savings: int = 0           # накопления

var current_goal_id: String = ""

var period_active: bool = false
var period_number: int = 1
var day_in_period: int = 1

# план в процентах
var plan_pct_mandatory: int = 50
var plan_pct_optional: int = 30
var plan_pct_savings: int = 20

# факт за период (в монетах)
var plan_mandatory: int = 0
var plan_optional: int = 0
var plan_savings: int = 0
var fact_mandatory: int = 0
var fact_optional: int = 0

var inventory: Dictionary = {}
var completed_tasks: Array = []
var history: Array = []
var purchase_log: Array = []

var last_minigame_day_key: int = -1
var global_day_counter: int = 0
var last_login_day_key: int = -1

var is_demo_profile: bool = false


func _ready() -> void:
	_load_content()
	load_game()


func _load_content() -> void:
	shop_items = _read_json_array("res://data/shop_items.json")
	tasks = _read_json_array("res://data/tasks.json")
	var edu := _read_json_dict("res://data/education_tips.json")
	goals_catalog = edu.get("goals", [])
	glossary = edu.get("glossary", [])


func _read_json_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		return parsed
	return []


func _read_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


# ---------------- SAVE / LOAD ----------------

func save_game() -> void:
	var data := {
		"first_launch": first_launch,
		"pet_created": pet_created,
		"pet_name": pet_name,
		"body_color_index": body_color_index,
		"pattern_index": pattern_index,
		"equipped_hat": equipped_hat,
		"pet_stage": pet_stage,
		"growth_points": growth_points,
		"mood": mood,
		"hunger": hunger,
		"wallet": wallet,
		"mandatory_budget": mandatory_budget,
		"optional_budget": optional_budget,
		"savings": savings,
		"current_goal_id": current_goal_id,
		"period_active": period_active,
		"period_number": period_number,
		"day_in_period": day_in_period,
		"plan_pct_mandatory": plan_pct_mandatory,
		"plan_pct_optional": plan_pct_optional,
		"plan_pct_savings": plan_pct_savings,
		"plan_mandatory": plan_mandatory,
		"plan_optional": plan_optional,
		"plan_savings": plan_savings,
		"fact_mandatory": fact_mandatory,
		"fact_optional": fact_optional,
		"inventory": inventory,
		"completed_tasks": completed_tasks,
		"history": history,
		"purchase_log": purchase_log,
		"last_minigame_day_key": last_minigame_day_key,
		"global_day_counter": global_day_counter,
		"last_login_day_key": last_login_day_key,
		"is_demo_profile": is_demo_profile,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		return
	var d: Dictionary = parsed
	first_launch = d.get("first_launch", true)
	pet_created = d.get("pet_created", false)
	pet_name = d.get("pet_name", "Финни")
	body_color_index = d.get("body_color_index", 0)
	pattern_index = d.get("pattern_index", 0)
	equipped_hat = d.get("equipped_hat", "")
	pet_stage = d.get("pet_stage", 0)
	growth_points = d.get("growth_points", 0)
	mood = d.get("mood", 80)
	hunger = d.get("hunger", 80)
	wallet = d.get("wallet", 60)
	mandatory_budget = d.get("mandatory_budget", 0)
	optional_budget = d.get("optional_budget", 0)
	savings = d.get("savings", 0)
	current_goal_id = d.get("current_goal_id", "")
	period_active = d.get("period_active", false)
	period_number = d.get("period_number", 1)
	day_in_period = d.get("day_in_period", 1)
	plan_pct_mandatory = d.get("plan_pct_mandatory", 50)
	plan_pct_optional = d.get("plan_pct_optional", 30)
	plan_pct_savings = d.get("plan_pct_savings", 20)
	plan_mandatory = d.get("plan_mandatory", 0)
	plan_optional = d.get("plan_optional", 0)
	plan_savings = d.get("plan_savings", 0)
	fact_mandatory = d.get("fact_mandatory", 0)
	fact_optional = d.get("fact_optional", 0)
	inventory = d.get("inventory", {})
	completed_tasks = d.get("completed_tasks", [])
	history = d.get("history", [])
	purchase_log = d.get("purchase_log", [])
	last_minigame_day_key = d.get("last_minigame_day_key", -1)
	global_day_counter = d.get("global_day_counter", 0)
	last_login_day_key = d.get("last_login_day_key", -1)
	is_demo_profile = d.get("is_demo_profile", false)


func reset_profile(demo: bool = false) -> void:
	first_launch = true
	pet_created = false
	pet_name = "Финни"
	body_color_index = 0
	pattern_index = 0
	equipped_hat = ""
	pet_stage = 0
	growth_points = 0
	mood = 80
	hunger = 80
	wallet = 60
	mandatory_budget = 0
	optional_budget = 0
	savings = 0
	current_goal_id = ""
	period_active = false
	period_number = 1
	day_in_period = 1
	plan_pct_mandatory = 50
	plan_pct_optional = 30
	plan_pct_savings = 20
	plan_mandatory = 0
	plan_optional = 0
	plan_savings = 0
	fact_mandatory = 0
	fact_optional = 0
	inventory = {}
	completed_tasks = []
	history = []
	purchase_log = []
	last_minigame_day_key = -1
	global_day_counter = 0
	last_login_day_key = -1
	is_demo_profile = demo
	save_game()
	state_changed.emit()


# ---------------- ОНБОРДИНГ / ПИТОМЕЦ ----------------

func finish_intro() -> void:
	first_launch = false
	save_game()


func create_pet(name: String, color_index: int, pattern: int) -> void:
	pet_name = name if name.strip_edges() != "" else "Финни"
	body_color_index = color_index
	pattern_index = pattern
	pet_created = true
	if goals_catalog.size() > 0:
		current_goal_id = goals_catalog[0].get("id", "")
	save_game()
	state_changed.emit()


# ---------------- ВНУТРЕННЕЕ: РАСПРЕДЕЛЕНИЕ ДОХОДА ----------------

func _distribute_income(amount: int) -> void:
	## Раскидывает amount монет по трём кошелькам согласно процентам плана.
	## Если план не активен — просто кладёт в wallet.
	if amount <= 0:
		return
	if not period_active:
		wallet += amount
		return
	var m := int(floor(amount * plan_pct_mandatory / 100.0))
	var o := int(floor(amount * plan_pct_optional / 100.0))
	var s := amount - m - o
	mandatory_budget += m
	optional_budget += o
	savings += s
	plan_mandatory += m
	plan_optional += o
	plan_savings += s


func _add_income(amount: int, source: String) -> void:
	if amount <= 0:
		return
	if period_active:
		_distribute_income(amount)
	else:
		wallet += amount
	save_game()
	state_changed.emit()


# ---------------- ЕЖЕДНЕВНЫЙ ВХОД ----------------

func can_claim_daily_income() -> bool:
	return last_login_day_key != global_day_counter


func claim_daily_income() -> void:
	if not can_claim_daily_income():
		return
	last_login_day_key = global_day_counter
	_add_income(LOGIN_BONUS, "бонус за вход")
	toast.emit("Бонус за вход: +%d монет" % LOGIN_BONUS)


# ---------------- МИНИ-ИГРА ----------------

func can_play_minigame() -> bool:
	return last_minigame_day_key != global_day_counter


func reward_minigame(coins_caught: int) -> void:
	var reward := coins_caught * MINIGAME_REWARD_PER_COIN
	last_minigame_day_key = global_day_counter
	_add_income(reward, "мини-игра")
	toast.emit("Мини-игра: +%d монет" % reward)


# ---------------- ПЛАН БЮДЖЕТА ----------------

func confirm_plan(pct_m: int, pct_o: int, pct_s: int) -> bool:
	if pct_m < 0 or pct_o < 0 or pct_s < 0:
		return false
	if pct_m + pct_o + pct_s != 100:
		return false
	if pct_m == 0:
		return false
	plan_pct_mandatory = pct_m
	plan_pct_optional = pct_o
	plan_pct_savings = pct_s
	# распределяем текущий wallet по новым процентам
	var start_amount := wallet
	wallet = 0
	mandatory_budget = 0
	optional_budget = 0
	# savings не трогаем — оно уже накоплено
	plan_mandatory = 0
	plan_optional = 0
	plan_savings = 0
	fact_mandatory = 0
	fact_optional = 0
	purchase_log = []
	period_active = true
	day_in_period = 1
	period_number = max(1, period_number)
	_distribute_income(start_amount)
	save_game()
	state_changed.emit()
	return true


# ---------------- ПОКУПКИ ----------------

func get_item(item_id: String) -> Dictionary:
	for it in shop_items:
		if it.get("id") == item_id:
			return it
	return {}


func can_afford(item_id: String) -> Dictionary:
	var item := get_item(item_id)
	if item.is_empty():
		return {"ok": false, "reason": "Такого товара нет."}
	var cat: String = item.get("category", "mandatory")
	var price: int = item.get("price", 0)
	if not period_active:
		return {"ok": false, "reason": "Сначала составь план бюджета на вкладке «Бюджет»."}
	var bucket := mandatory_budget if cat == "mandatory" else optional_budget
	if bucket < price:
		var label := "обязательное" if cat == "mandatory" else "желаемое"
		return {"ok": false, "reason": "Не хватает %d монет в категории «%s». Сейчас доступно: %d." % [price - bucket, label, bucket]}
	return {"ok": true, "reason": ""}


func buy_item(item_id: String) -> Dictionary:
	var check := can_afford(item_id)
	if not check.get("ok"):
		return check
	var item := get_item(item_id)
	var cat: String = item.get("category", "mandatory")
	var price: int = item.get("price", 0)
	if cat == "mandatory":
		mandatory_budget -= price
		fact_mandatory += price
	else:
		optional_budget -= price
		fact_optional += price
	hunger = clampi(hunger + int(item.get("hunger", 0)), 0, 100)
	mood = clampi(mood + int(item.get("mood", 0)), 0, 100)
	if item.has("slot") and item.get("slot") == "hat":
		equipped_hat = item_id
	inventory[item_id] = int(inventory.get(item_id, 0)) + 1
	purchase_log.append({"name": item.get("name"), "price": price, "category": cat})
	toast.emit("Куплено: %s" % item.get("name"))
	save_game()
	state_changed.emit()
	return {"ok": true, "reason": ""}


func unequip_hat() -> void:
	equipped_hat = ""
	save_game()
	state_changed.emit()


func equip_hat(item_id: String) -> void:
	if int(inventory.get(item_id, 0)) > 0:
		equipped_hat = item_id
		save_game()
		state_changed.emit()


# ---------------- НАКОПЛЕНИЯ / ЦЕЛИ ----------------

func get_goal(goal_id: String) -> Dictionary:
	for g in goals_catalog:
		if g.get("id") == goal_id:
			return g
	return {}


func select_goal(goal_id: String) -> void:
	current_goal_id = goal_id
	save_game()
	state_changed.emit()


func average_saving_per_period() -> float:
	if history.is_empty():
		return float(plan_savings)
	var sum := 0
	var n := 0
	for h in history:
		sum += int(h.get("plan_savings", 0))
		n += 1
	if n == 0:
		return float(plan_savings)
	return float(sum) / float(n)


func estimate_periods_to_goal(goal_id: String) -> Variant:
	var g := get_goal(goal_id)
	if g.is_empty():
		return null
	var remaining: int = max(0, int(g.get("cost", 0)) - savings)
	if remaining == 0:
		return 0
	var avg := average_saving_per_period()
	if avg <= 0:
		return null
	return int(ceil(float(remaining) / avg))


func withdraw_savings(amount: int) -> bool:
	if amount <= 0 or amount > savings:
		return false
	savings -= amount
	# снятые монеты попадают в кошелёк, оттуда их можно распределить заново
	wallet += amount
	save_game()
	state_changed.emit()
	return true


# ---------------- ЗАДАНИЯ ----------------

func is_task_completed(task_id: String) -> bool:
	return completed_tasks.has(task_id)


func complete_task(task_id: String, reward: int = 10) -> void:
	if not is_task_completed(task_id):
		completed_tasks.append(task_id)
		_add_income(reward, "задание")
		toast.emit("Задание выполнено! +%d монет" % reward)
		return
	save_game()
	state_changed.emit()


# ---------------- ТЕЧЕНИЕ ДНЯ / ПЕРИОДА ----------------

func advance_day() -> Dictionary:
	global_day_counter += 1

	# ежедневный доход приходит каждый день
	_add_income(DAILY_INCOME, "ежедневный доход")

	# естественное снижение показателей
	hunger = clampi(hunger - 18, 0, 100)
	var mood_decay := 6
	if hunger < 30:
		mood_decay += 8
	mood = clampi(mood - mood_decay, 0, 100)

	if not period_active:
		save_game()
		state_changed.emit()
		return {}

	day_in_period += 1
	if day_in_period > PERIOD_LENGTH:
		var summary := _close_period()
		save_game()
		state_changed.emit()
		return summary
	save_game()
	state_changed.emit()
	return {}


func _close_period() -> Dictionary:
	var interest := int(round(savings * SAVINGS_RATE))
	savings += interest
	var good_period: bool = fact_mandatory > 0 and mood >= 50 and hunger >= 40
	if good_period:
		growth_points += 1
	var old_stage := pet_stage
	if growth_points >= 4 and pet_stage < 2:
		pet_stage = 2
	elif growth_points >= 2 and pet_stage < 1:
		pet_stage = 1
	var grew := pet_stage != old_stage

	var summary := {
		"period_number": period_number,
		"plan_mandatory": plan_mandatory,
		"plan_optional": plan_optional,
		"plan_savings": plan_savings,
		"fact_mandatory": fact_mandatory,
		"fact_optional": fact_optional,
		"interest": interest,
		"good_period": good_period,
		"grew": grew,
		"new_stage": pet_stage,
		"end_mood": mood,
		"end_hunger": hunger,
	}
	history.append(summary)

	# неизрасходованные кошельки возвращаются в wallet
	wallet += mandatory_budget + optional_budget
	mandatory_budget = 0
	optional_budget = 0
	period_active = false
	period_number += 1
	day_in_period = 1
	return summary


func stage_name() -> String:
	match pet_stage:
		0: return "Котёнок"
		1: return "Подросший кот"
		_: return "Взрослый кот-мудрец"


func mood_face() -> String:
	if mood >= 70:
		return "happy"
	elif mood >= 35:
		return "neutral"
	else:
		return "sad"
