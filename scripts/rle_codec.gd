## Codificador/decodificador do formato RLE (Run Length Encoded) de Jogo da Vida.
## Header: "x = W, y = H, rule = B3/S23" · corpo: b=morta, o=viva, $=fim de linha, !=fim.

const DEFAULT_BIRTHS := [3]
const DEFAULT_SURVIVALS := [2, 3]


static func encode(sim) -> String:
	var header := "x = %d, y = %d, rule = %s" % [sim.width, sim.height, _rule_tag(sim)]
	var rows: Array[String] = []
	for y in sim.height:
		rows.append(_encode_row(sim, y))
	return header + "\n" + "$".join(rows) + "!"


static func decode(text: String) -> Dictionary:
	var cells: Array[Vector2i] = []
	var births := DEFAULT_BIRTHS.duplicate()
	var survivals := DEFAULT_SURVIVALS.duplicate()
	var body_lines: Array[String] = []

	for line in text.split("\n"):
		line = line.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		if _is_header(line):
			_parse_rule(line, births, survivals)
		else:
			body_lines.append(line)

	var count := ""
	var x := 0
	var y := 0
	for ch in "".join(body_lines):
		if ch >= "0" and ch <= "9":
			count += ch
		elif ch == "b" or ch == "B":
			x += _run(count)
			count = ""
		elif ch == "o" or ch == "O":
			var n := _run(count)
			count = ""
			for i in n:
				cells.append(Vector2i(x + i, y))
			x += n
		elif ch == "$":
			y += _run(count)
			count = ""
			x = 0
		elif ch == "!":
			break

	return {"cells": cells, "rule_births": births, "rule_survivals": survivals}


static func _is_header(line: String) -> bool:
	return line.begins_with("x") and line.contains("=")


static func _parse_rule(line: String, births: Array, survivals: Array) -> void:
	var idx := line.to_lower().find("rule")
	if idx == -1:
		return
	var rhs := line.substr(idx + 4).strip_edges().trim_prefix("=").strip_edges()
	var parts := rhs.split("/")
	if parts.size() > 0 and parts[0].length() > 1:
		births.clear()
		births.append_array(_digits(parts[0].substr(1)))
	if parts.size() > 1:
		survivals.clear()
		survivals.append_array(_digits(parts[1].substr(1)))


static func _digits(text: String) -> Array:
	var out := []
	for ch in text:
		out.append(int(ch))
	return out


static func _encode_row(sim, y: int) -> String:
	var out := ""
	var current := ""
	var run := 0
	for x in sim.width:
		var tag := "o" if sim.get_cell(x, y) else "b"
		if tag == current:
			run += 1
		else:
			out += _emit(current, run)
			current = tag
			run = 1
	return out + _emit(current, run)


static func _emit(tag: String, run: int) -> String:
	if run == 0:
		return ""
	if run == 1:
		return tag
	return "%d%s" % [run, tag]


static func _run(count: String) -> int:
	return int(count) if not count.is_empty() else 1


static func _rule_tag(sim) -> String:
	return "B%s/S%s" % [_counts_tag(sim._birth_counts), _counts_tag(sim._survival_counts)]


static func _counts_tag(counts: Dictionary) -> String:
	var keys := counts.keys()
	keys.sort()
	var out := ""
	for key in keys:
		out += str(key)
	return out
