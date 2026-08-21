extends Node2D

const LifeSim := preload("res://scripts/life_simulation.gd")
const LifePatterns := preload("res://scripts/life_patterns.gd")
const RleCodec := preload("res://scripts/rle_codec.gd")

const CELL_SIZE := 16
const GRID_WIDTH := 64
const GRID_HEIGHT := 36
const MIN_SPEED := 1.0
const MAX_SPEED := 30.0
const RANDOM_DENSITY := 0.28

const BOARD_COLOR := Color(0.08, 0.09, 0.12)
const GRID_LINE_COLOR := Color(1.0, 1.0, 1.0, 0.05)
const CELL_YOUNG_COLOR := Color(0.45, 1.0, 0.55)
const CELL_OLD_COLOR := Color(0.45, 0.5, 0.95)
const AGE_FULL_TINT_AT := 45.0
const MIN_ZOOM := 0.5
const MAX_ZOOM := 8.0
const GRAPH_SIZE := Vector2(240, 72)
const GRAPH_MARGIN := 10.0

const RULES := {
	"Conway": [[3], [2, 3]],
	"HighLife": [[3, 6], [2, 3]],
	"Seeds": [[2], []],
	"Day & Night": [[3, 6, 7, 8], [3, 4, 6, 7, 8]],
}

var simulation = LifeSim.new(GRID_WIDTH, GRID_HEIGHT)
var running := false
var generations_per_second := 10.0

var _step_accumulator := 0.0
var _painting := false
var _paint_alive := true
var _panning := false
var _selected_pattern: Array[Vector2i] = []
var _camera: Camera2D

var _play_button: Button
var _save_dialog: FileDialog
var _open_dialog: FileDialog


func _ready() -> void:
	_build_hud()
	_build_camera()
	_seed_showcase()
	_update_status()
	queue_redraw()


func _process(delta: float) -> void:
	if not running:
		return
	_step_accumulator += delta
	var step_time := 1.0 / generations_per_second
	while _step_accumulator >= step_time:
		_step_accumulator -= step_time
		simulation.step()
	_update_status()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = event.pressed
		elif event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			_painting = event.pressed
			_paint_alive = event.button_index == MOUSE_BUTTON_LEFT
			if event.pressed:
				_apply_brush_at(get_global_mouse_position())
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(1.15)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(1.0 / 1.15)
	elif event is InputEventMouseMotion:
		if _panning:
			_camera.position -= event.relative / _camera.zoom.x
			_clamp_camera()
		elif _painting and _paint_alive:
			_apply_brush_at(get_global_mouse_position())
	elif event is InputEventMagnifyGesture:
		_zoom_at(event.factor)
	elif event is InputEventPanGesture:
		_camera.position -= Vector2(event.delta.x, event.delta.y) * _camera.zoom.x
		_clamp_camera()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_toggle_running()
			KEY_PERIOD:
				_single_step()
			KEY_C:
				_clear_board()
			KEY_R:
				_randomize_board()


func _draw() -> void:
	var board_size := Vector2(GRID_WIDTH, GRID_HEIGHT) * CELL_SIZE
	draw_rect(Rect2(Vector2.ZERO, board_size), BOARD_COLOR)
	for x in GRID_WIDTH + 1:
		draw_line(Vector2(x * CELL_SIZE, 0), Vector2(x * CELL_SIZE, board_size.y), GRID_LINE_COLOR)
	for y in GRID_HEIGHT + 1:
		draw_line(Vector2(0, y * CELL_SIZE), Vector2(board_size.x, y * CELL_SIZE), GRID_LINE_COLOR)
	for y in GRID_HEIGHT:
		for x in GRID_WIDTH:
			if simulation.get_cell(x, y):
				var age_ratio := clampf(simulation.get_age(x, y) / AGE_FULL_TINT_AT, 0.0, 1.0)
				var color := CELL_YOUNG_COLOR.lerp(CELL_OLD_COLOR, age_ratio)
				draw_rect(Rect2(Vector2(x, y) * CELL_SIZE, Vector2(CELL_SIZE - 1, CELL_SIZE - 1)), color)
	draw_string(ThemeDB.fallback_font, Vector2(12, 24), "Geração %d · População %d" % [simulation.generation, simulation.population()], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 1.0, 1.0, 0.8))
	_draw_population_graph()


func _draw_population_graph() -> void:
	var history := simulation.population_history()
	if history.size() < 2:
		return
	var origin := Vector2(GRID_WIDTH, GRID_HEIGHT) * CELL_SIZE - GRAPH_SIZE - Vector2(GRAPH_MARGIN, GRAPH_MARGIN)
	draw_rect(Rect2(origin, GRAPH_SIZE), Color(0.0, 0.0, 0.0, 0.55))
	var max_pop := 1
	for value in history:
		max_pop = maxi(max_pop, value)
	var points := PackedVector2Array()
	var last := history.size() - 1
	for i in history.size():
		var t := float(i) / float(last)
		var x := origin.x + 6.0 + t * (GRAPH_SIZE.x - 12.0)
		var y := origin.y + GRAPH_SIZE.y - 6.0 - (float(history[i]) / max_pop) * (GRAPH_SIZE.y - 20.0)
		points.append(Vector2(x, y))
	draw_polyline(points, Color(0.45, 1.0, 0.55, 0.9), 1.5)
	draw_string(ThemeDB.fallback_font, origin + Vector2(6, 14), "pop %d · máx %d" % [simulation.population(), max_pop], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.75))


func _zoom_at(factor: float) -> void:
	var mouse_world := get_global_mouse_position()
	var new_zoom := clampf(_camera.zoom.x * factor, MIN_ZOOM, MAX_ZOOM)
	factor = new_zoom / _camera.zoom.x
	_camera.zoom = Vector2(new_zoom, new_zoom)
	_camera.position += (mouse_world - _camera.position) * (1.0 - 1.0 / factor)
	_clamp_camera()
	queue_redraw()


func _clamp_camera() -> void:
	var board_size := Vector2(GRID_WIDTH, GRID_HEIGHT) * CELL_SIZE
	_camera.position = _camera.position.clamp(Vector2.ZERO, board_size)


func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.position = Vector2(GRID_WIDTH, GRID_HEIGHT) * CELL_SIZE / 2.0
	add_child(_camera)


func _apply_brush_at(screen_position: Vector2) -> void:
	var cell := Vector2i((screen_position / float(CELL_SIZE)).floor())
	if not _paint_alive:
		simulation.set_cell(cell.x, cell.y, false)
	elif _selected_pattern.is_empty():
		simulation.set_cell(cell.x, cell.y, true)
	else:
		simulation.stamp(_selected_pattern, cell - _pattern_half_size())
	_update_status()
	queue_redraw()


func _pattern_half_size() -> Vector2i:
	var max_x := 0
	var max_y := 0
	for offset in _selected_pattern:
		max_x = maxi(max_x, offset.x)
		max_y = maxi(max_y, offset.y)
	@warning_ignore("integer_division")
	return Vector2i(max_x, max_y) / 2


func _toggle_running() -> void:
	running = not running
	_play_button.text = "Pause" if running else "Play"


func _single_step() -> void:
	running = false
	_play_button.text = "Play"
	simulation.step()
	_update_status()
	queue_redraw()


func _clear_board() -> void:
	simulation.clear()
	_update_status()
	queue_redraw()


func _randomize_board() -> void:
	simulation.clear()
	for y in GRID_HEIGHT:
		for x in GRID_WIDTH:
			simulation.set_cell(x, y, randf() < RANDOM_DENSITY)
	_update_status()
	queue_redraw()


func _seed_showcase() -> void:
	var mid_y := int(GRID_HEIGHT / 2.0)
	var gun := LifePatterns.offsets_from_art(LifePatterns.PATTERNS["Canhão"])
	simulation.stamp(gun, Vector2i(4, mid_y - 5))
	var pulsar := LifePatterns.offsets_from_art(LifePatterns.PATTERNS["Pulsar"])
	simulation.stamp(pulsar, Vector2i(GRID_WIDTH - 20, mid_y - 7))
	var lwss := LifePatterns.offsets_from_art(LifePatterns.PATTERNS["LWSS"])
	simulation.stamp(lwss, Vector2i(int(GRID_WIDTH / 2.0) + 6, 3))
	simulation.stamp(lwss, Vector2i(int(GRID_WIDTH / 2.0) + 14, GRID_HEIGHT - 8))


func _select_pattern(key: String) -> void:
	if key.is_empty():
		_selected_pattern = []
	else:
		_selected_pattern = LifePatterns.offsets_from_art(LifePatterns.PATTERNS[key])


func _on_rule_selected(index: int, option: OptionButton) -> void:
	var rule: Array = RULES[option.get_item_text(index)]
	simulation.set_rule(rule[0], rule[1])


func _update_status() -> void:
	queue_redraw()


func _build_hud() -> void:
	var panel := VBoxContainer.new()
	panel.position = Vector2(8, GRID_HEIGHT * CELL_SIZE + 8)
	panel.add_theme_constant_override("separation", 4)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	_play_button = _make_button("Play", _toggle_running)
	controls.add_child(_play_button)
	controls.add_child(_make_button("Step", _single_step))
	controls.add_child(_make_button("Limpar", _clear_board))
	controls.add_child(_make_button("Random", _randomize_board))
	controls.add_child(_make_button("Salvar", _show_save_dialog))
	controls.add_child(_make_button("Abrir", _show_open_dialog))

	var torus_button := Button.new()
	torus_button.text = "Toro"
	torus_button.toggle_mode = true
	torus_button.focus_mode = Control.FOCUS_NONE
	torus_button.toggled.connect(func(on: bool) -> void: simulation.wrap_edges = on)
	controls.add_child(torus_button)

	var rules_option := OptionButton.new()
	for rule_name in RULES:
		rules_option.add_item(rule_name)
	rules_option.focus_mode = Control.FOCUS_NONE
	rules_option.item_selected.connect(_on_rule_selected.bind(rules_option))
	controls.add_child(rules_option)

	var brushes := HBoxContainer.new()
	brushes.add_theme_constant_override("separation", 8)
	var group := ButtonGroup.new()
	brushes.add_child(_make_brush_button("Lápis", "", group, true))
	for pattern_name in LifePatterns.PATTERNS:
		brushes.add_child(_make_brush_button(pattern_name, pattern_name, group, false))

	var speed_label := Label.new()
	speed_label.text = "Vel:"
	brushes.add_child(speed_label)

	var slider := HSlider.new()
	slider.min_value = MIN_SPEED
	slider.max_value = MAX_SPEED
	slider.step = 1.0
	slider.value = generations_per_second
	slider.custom_minimum_size = Vector2(120, 16)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect(func(value: float) -> void: generations_per_second = value)
	brushes.add_child(slider)

	panel.add_child(controls)
	panel.add_child(brushes)

	var layer := CanvasLayer.new()
	layer.add_child(panel)
	add_child(layer)

	_build_file_dialogs()


func _build_file_dialogs() -> void:
	_save_dialog = FileDialog.new()
	_save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_save_dialog.filters = PackedStringArray(["*.rle ; Padrão RLE"])
	_save_dialog.current_file = "padrao.rle"
	_save_dialog.file_selected.connect(_on_save_path)
	add_child(_save_dialog)

	_open_dialog = FileDialog.new()
	_open_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_open_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_open_dialog.filters = PackedStringArray(["*.rle ; Padrão RLE"])
	_open_dialog.file_selected.connect(_on_open_path)
	add_child(_open_dialog)


func _show_save_dialog() -> void:
	_save_dialog.popup_centered(Vector2i(640, 420))


func _show_open_dialog() -> void:
	_open_dialog.popup_centered(Vector2i(640, 420))


func _on_save_path(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(RleCodec.encode(simulation))
	file.close()


func _on_open_path(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var data := RleCodec.decode(file.get_as_text())
	file.close()
	simulation.clear()
	simulation.set_rule(data.rule_births, data.rule_survivals)
	simulation.stamp(data.cells, _centered_origin(data.cells))
	_update_status()
	queue_redraw()


func _centered_origin(cells: Array[Vector2i]) -> Vector2i:
	var max_x := 0
	var max_y := 0
	for cell in cells:
		max_x = maxi(max_x, cell.x)
		max_y = maxi(max_y, cell.y)
	var origin := Vector2i(floori((GRID_WIDTH - max_x) / 2.0), floori((GRID_HEIGHT - max_y) / 2.0))
	return origin.max(Vector2i.ZERO)


func _make_brush_button(text: String, pattern_key: String, group: ButtonGroup, pressed: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.button_pressed = pressed
	button.button_group = group
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: _select_pattern(pattern_key))
	return button


func _make_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button
