class_name LifeSimulation
extends RefCounted

## Autômato celular de Conway (Game of Life).
## Grade fixa com bordas mortas ou toroidal e atualização simultânea (double buffering).

const ALIVE := 1
const DEAD := 0

var width: int
var height: int
var cells: PackedByteArray
var wrap_edges := false

var _birth_counts := {}
var _survival_counts := {2: true, 3: true}

var _next: PackedByteArray
var _ages: PackedByteArray
var _next_ages: PackedByteArray
var _history := PackedInt32Array()
var generation: int
var history_limit := 256


func _init(grid_width: int, grid_height: int) -> void:
	width = maxi(1, grid_width)
	height = maxi(1, grid_height)
	cells.resize(width * height)
	_next.resize(width * height)
	_ages.resize(width * height)
	_next_ages.resize(width * height)
	generation = 0
	set_rule([3], [2, 3])


func set_rule(births: Array, survivals: Array) -> void:
	_birth_counts = {}
	for value in births:
		_birth_counts[value] = true
	_survival_counts = {}
	for value in survivals:
		_survival_counts[value] = true


func get_cell(x: int, y: int) -> bool:
	if _out_of_bounds(x, y):
		return false
	return cells[_index(x, y)] == ALIVE


func get_age(x: int, y: int) -> int:
	if _out_of_bounds(x, y):
		return 0
	return _ages[_index(x, y)]


func set_cell(x: int, y: int, alive: bool) -> void:
	if _out_of_bounds(x, y):
		return
	cells[_index(x, y)] = ALIVE if alive else DEAD


func stamp(offsets: Array, origin: Vector2i) -> void:
	for offset in offsets:
		set_cell(origin.x + offset.x, origin.y + offset.y, true)


func count_neighbors(x: int, y: int) -> int:
	var count := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx := x + dx
			var ny := y + dy
			if wrap_edges:
				nx = posmod(nx, width)
				ny = posmod(ny, height)
			if get_cell(nx, ny):
				count += 1
	return count


func step() -> void:
	for y in height:
		for x in width:
			var i := _index(x, y)
			var neighbors := count_neighbors(x, y)
			var alive := cells[i] == ALIVE
			var survives := _birth_counts.has(neighbors) if not alive else _survival_counts.has(neighbors)
			_next[i] = ALIVE if survives else DEAD
			_next_ages[i] = mini(_ages[i] + 1, 255) if survives else 0
	var swap_cells := cells
	var swap_ages := _ages
	cells = _next
	_ages = _next_ages
	_next = swap_cells
	_next_ages = swap_ages
	generation += 1
	_history.append(population())
	if _history.size() > history_limit:
		_history = _history.slice(_history.size() - history_limit)


func population_history() -> PackedInt32Array:
	return _history


func clear() -> void:
	cells.fill(DEAD)
	_ages.fill(0)
	_history.clear()
	generation = 0


func population() -> int:
	var count := 0
	for value in cells:
		if value == ALIVE:
			count += 1
	return count


func _index(x: int, y: int) -> int:
	return y * width + x


func _out_of_bounds(x: int, y: int) -> bool:
	return x < 0 or y < 0 or x >= width or y >= height
