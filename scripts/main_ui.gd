extends Control

@onready var chance_input = $vbox_container/bottom_ui_container/chance_input_row/chance_input
@onready var roll_button = $vbox_container/bottom_ui_container/chance_input_row/roll_button
@onready var log_output = $vbox_container/bottom_ui_container/log_output
@onready var stats_label = $vbox_container/bottom_ui_container/stats_label
@onready var roll_line = $vbox_container/graph_panel/roll_line
@onready var graph_panel = $vbox_container/graph_panel
@onready var success_line = $vbox_container/graph_panel/success_line
@onready var fail_line = $vbox_container/graph_panel/fail_line
@onready var threshold_line = $vbox_container/graph_panel/threshold_line
@onready var blast_count_input = $vbox_container/bottom_ui_container/blast_row/blast_count_input
@onready var blast_button = $vbox_container/bottom_ui_container/blast_row/blast_button
@onready var confirm_blast_dialog = $confirm_blast_dialog

var success_count = 0
var fail_count = 0
var recent_rolls: Array[float] = []
var success_points: Array[float] = []
var fail_points: Array[float] = []
const MAX_ROLLS = 100 # Number of points on the graph
var roll_history: Array[Dictionary] = []
var last_chance: float = -1.0
var MAX_SAFE_BLAST = 500000
var BLAST_WARNING_THRESHOLD = 10000
var blast_count = 0
var log_limit = 200
var num_rolls = 0
var in_anomaly = false


#danger zone
var roll_held := false

func _ready():
	roll_button.pressed.connect(_on_roll_pressed)
	blast_button.pressed.connect(_on_blast_button_pressed)
	confirm_blast_dialog.confirmed.connect(_on_confirm_blast)

func _on_roll_pressed():
	# log cleanup before anything else
	# move this later, for now just see if we're at log_limit data stored
	if num_rolls > 50:
		log_cleanup(false)
		num_rolls = 0
	else:
		num_rolls += 1
	
	var chance_text = chance_input.text.strip_edges()
	
	var chance = float(chance_input.text)
	
	if not chance_text.is_valid_float():
		_append_to_log("Invalid input: not a number.")
		return
	
	if chance < 0.0 or chance > 100.0:
		_append_to_log("Chance must be between 0 and 100.")
		return
	
	var roll = randf() * 100.0
	var is_success = roll < chance
	
	if is_success:
		if success_points.is_empty():
			success_points.append(chance)
		success_points.append(roll)
	else:
		if fail_points.is_empty():
			fail_points.append(chance)
		fail_points.append(roll)
			
	if is_success:
		success_count += 1
		success_points.append(roll)
	else:
		fail_count += 1
		fail_points.append(roll)
		
	if success_points.size() >= MAX_ROLLS or fail_points.size() >= MAX_ROLLS:
		if success_points.size() > 0:
			success_points.pop_front()
		if fail_points.size() > 0:
			fail_points.pop_front()

	
	var result_text = "SUCCESS" if is_success else "FAIL"

	# anomaly tracking with state and optional spam
	var z = z_score(success_count, success_count + fail_count, chance)
	var anomaly_tag = ""
	print(str(success_count) + " : " + str(fail_count) + " : " + str(z))
	if abs(z) > 3.0:
		if not in_anomaly:
			in_anomaly = true
			anomaly_tag = "😱📉 ABSURD ANOMALY STARTED"
		else:
			anomaly_tag = "😱📉 ABSURD ANOMALY" if GameSettings.allow_anomaly_spam else ""
	elif abs(z) > 2.0:
		if not in_anomaly:
			in_anomaly = true
			anomaly_tag = "⚠️🧪 ANOMALY DETECTED"
		else:
			anomaly_tag = "⚠️🧪" if GameSettings.allow_anomaly_spam else ""
	elif in_anomaly and abs(z) < 1.0:
		in_anomaly = false
		anomaly_tag = "✅ Anomaly resolved."

	var log_line = "Rolled %.2f vs %.2f%% → %s%s" % [roll, chance, result_text, anomaly_tag]
	
	_append_to_log(log_line)
	_update_stats()
	
	# Store and clamp roll data
	recent_rolls.append(roll)
	if recent_rolls.size() > MAX_ROLLS:
		recent_rolls.pop_front()
	
	_update_graph()
	
	#if is_success:
		#success_line.default_color = Color8(randi() % 255, randi() % 255, randi() % 255)
	#else:
		#fail_line.default_color = Color8(randi() % 255, randi() % 255, randi() % 255)


func _append_to_log(text: String):
	log_output.text += text + "\n"
	log_output.scroll_vertical = log_output.get_line_count()

func _update_stats():
	var avg = (float(success_count) / (success_count + fail_count)) * 100.0
	stats_label.text = "Success: %d | Fail: %d | Success Percent: %.2f%%" % [success_count, fail_count, avg]
	
func _update_graph():
	success_line.clear_points()
	fail_line.clear_points()
	
	var width = graph_panel.size.x
	var height = graph_panel.size.y
	var spacing = width / MAX_ROLLS

	for i in range(success_points.size()):
		var x = i * spacing
		var y = height - (success_points[i] / 100.0) * height
		success_line.add_point(Vector2(x, y))
	
	for i in range(fail_points.size()):
		var x = i * spacing
		var y = height - (fail_points[i] / 100.0) * height
		fail_line.add_point(Vector2(x, y))
		
	# Update threshold line
	threshold_line.clear_points()
	if chance_input.text.is_valid_float():
		var chance = float(chance_input.text)
		var threshold_y = height - (chance / 100.0) * height
		threshold_line.add_point(Vector2(0, threshold_y))
		threshold_line.add_point(Vector2(width, threshold_y))
		
func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		roll_held = true
	elif event.is_action_released("ui_accept"):
		roll_held = false
	
func _process(delta):
	if roll_held:
		_on_roll_pressed()

func z_score(actual_successes: int, total_rolls: int, chance: float) -> float:
	var p = chance / 100.0
	var expected = total_rolls * p
	var std_dev = sqrt(total_rolls * p * (1.0 - p))
	if std_dev == 0:
		return 0
	return (actual_successes - expected) / std_dev

func run_mass_rolls(count := 10000):
	blast_button.disabled = true
	blast_count_input.editable = false
	
	# cleanup the log before blast
	log_cleanup(true)

	var chance = float(chance_input.text)
	
	if chance != last_chance:
		_reset_stats()
		last_chance = chance
	
	for i in count:
		var roll = randf() * 100.0
		var is_success = roll < chance
		
		roll_history.append({
			"value": roll,
			"success": is_success
		})
		if roll_history.size() > 10000:
			roll_history.pop_front()

		if is_success:
			success_count += 1
			if success_points.is_empty():
				success_points.append(chance)
			success_points.append(roll)
		else:
			fail_count += 1
			if fail_points.is_empty():
				fail_points.append(chance)
			fail_points.append(roll)

		# Keep sizes in sync
		if success_points.size() >= MAX_ROLLS or fail_points.size() >= MAX_ROLLS:
			if success_points.size() > 0:
				success_points.pop_front()
			if fail_points.size() > 0:
				fail_points.pop_front()

	# Just update stats/graph once at the end
	_update_stats()
	_update_graph()

	# Optional: print outcome to console
	var total = success_count + fail_count
	var percent = float(success_count) / total * 100.0
	
	var z = z_score(success_count, total, chance)
	var anomaly_text = ""

	if abs(z) > 3.0:
		anomaly_text = "🚨 ABSURD ANOMALY (Z = %.2f)" % z
	elif abs(z) > 2.0:
		anomaly_text = "⚠️ Statistically Unlikely (Z = %.2f)" % z
	else:
		anomaly_text = "Z-Score: %.2f (within expected range)" % z
		
	var recent = roll_history.slice(-100)
	var recent_successes = 0
	var recent_fails = 0
	var recent_values = ""

	for entry in recent:
		if entry.success:
			recent_successes += 1
			recent_values += "✅ "
		else:
			recent_fails += 1
			recent_values += "❌ "

	_append_to_log("========== BLAST COMPLETE ==========")
	_append_to_log("Mass roll complete: %d total | Success: %d (%.2f%%)" % [total, success_count, percent])
	_append_to_log(anomaly_text)
	_append_to_log("Last 100 rolls — Success: %d | Fail: %d" % [recent_successes, recent_fails])
	_append_to_log("Roll Trend: %s" % recent_values.strip_edges())
	_append_to_log("====================================")
	
	blast_button.disabled = false
	blast_count_input.editable = true


func _on_blast_button_pressed():
	var input_text = blast_count_input.text.strip_edges()
	if not input_text.is_valid_int():
		_append_to_log("🚫 Invalid blast count!")
		return

	var count = int(input_text)
	if count <= 0:
		_append_to_log("🚫 Blast count must be greater than 0.")
		return

	if count > MAX_SAFE_BLAST:
		_append_to_log("⚠️ Blast count capped at %d to avoid cooking your PC." % MAX_SAFE_BLAST)
		count = MAX_SAFE_BLAST

	if count >= BLAST_WARNING_THRESHOLD:
		blast_count = count
		confirm_blast_dialog.dialog_text = "You're about to roll %d times.\n\nThis might freeze or lag your system.\nProceed?" % count
		confirm_blast_dialog.popup_centered()
	else:
		run_mass_rolls(count)

func _reset_stats():
	success_count = 0
	fail_count = 0
	success_points.clear()
	fail_points.clear()
	roll_history.clear()
	_update_stats()
	_update_graph()

func _on_confirm_blast():
	run_mass_rolls(blast_count)
	
func log_cleanup(is_blast=false):
	var lines = log_output.text.split("\n")
	if is_blast:
		# clear the whole log
		log_output.clear()
	elif lines.size() > log_limit: 
		# check for log_limit (200) lines, and trim appropriately
		log_output.text = "\n".join(lines.slice(-log_limit))

# Debug tool: simulate anomaly
func _on_force_anomaly_pressed():
	if not in_anomaly:
		success_count = 0
		fail_count = 100
		print("anomaly forced")
	else:
		success_count = 0
		fail_count = 0
		print("exiting anomaly")
	
func _input(event):
	if event.is_action_pressed("force_anomaly"):
		_on_force_anomaly_pressed()
