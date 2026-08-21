extends GdUnitTestSuite

const Codec := preload("res://scripts/rle_codec.gd")
const Sim := preload("res://scripts/life_simulation.gd")


func test_encode_blinker():
	var sim = Sim.new(5, 3)
	sim.set_cell(1, 1, true)
	sim.set_cell(2, 1, true)
	sim.set_cell(3, 1, true)
	assert_str(Codec.encode(sim)).is_equal("x = 5, y = 3, rule = B3/S23\n5b$b3ob$5b!")


func test_decode_blinker():
	var data := Codec.decode("x = 5, y = 3, rule = B3/S23\n5b$b3ob$5b!")
	assert_int(data.cells.size()).is_equal(3)
	assert_that(data.cells.has(Vector2i(1, 1))).is_equal(true)
	assert_that(data.cells.has(Vector2i(2, 1))).is_equal(true)
	assert_that(data.cells.has(Vector2i(3, 1))).is_equal(true)
	assert_array(data.rule_births).contains(3)
	assert_array(data.rule_survivals).contains(2, 3)


func test_decode_aceita_quebras_de_linha_no_corpo():
	var data := Codec.decode("x = 5, y = 3, rule = B3/S23\n5b$\nb3ob$\n5b!")
	assert_int(data.cells.size()).is_equal(3)


func test_decode_regra_highlife():
	var data := Codec.decode("x = 3, y = 3, rule = B36/S23\nbo!")
	assert_array(data.rule_births).contains(3, 6)
	assert_array(data.rule_survivals).contains(2, 3)


func test_decode_sem_regra_usa_conway():
	var data := Codec.decode("x = 3, y = 3\no!")
	assert_array(data.rule_births).contains(3)
	assert_int(data.rule_survivals.size()).is_equal(2)


func test_round_trip_preserva_padrao_e_regra():
	var original = Sim.new(8, 6)
	for offset in [Vector2i(1, 0), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]:
		original.set_cell(3 + offset.x, 2 + offset.y, true)
	original.set_rule([3, 6], [2, 3])

	var restored = Sim.new(8, 6)
	var data := Codec.decode(Codec.encode(original))
	restored.set_rule(data.rule_births, data.rule_survivals)
	restored.stamp(data.cells, Vector2i.ZERO)

	assert_int(restored.population()).is_equal(original.population())
	for y in 6:
		for x in 8:
			assert_that(restored.get_cell(x, y)).is_equal(original.get_cell(x, y))


func test_decode_ignora_comentarios():
	var text := "#N Blinker\nx = 5, y = 3, rule = B3/S23\n#C padrao classico\n5b$b3ob$5b!"
	var data := Codec.decode(text)
	assert_int(data.cells.size()).is_equal(3)
