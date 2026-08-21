extends GdUnitTestSuite

const Sim := preload("res://scripts/life_simulation.gd")


func make_sim(art: Array):
	var h: int = art.size()
	var w: int = (art[0] as String).length()
	var sim = Sim.new(w, h)
	for y in h:
		var line: String = art[y]
		for x in w:
			sim.set_cell(x, y, line[x] == "#")
	return sim


func to_art(sim) -> Array[String]:
	var out: Array[String] = []
	for y in sim.height:
		var line := ""
		for x in sim.width:
			line += "#" if sim.get_cell(x, y) else "."
		out.append(line)
	return out


func assert_grid(sim, expected: Array) -> void:
	assert_that("\n".join(to_art(sim))).is_equal("\n".join(expected))


func test_nova_grade_comeca_toda_morta():
	var sim = Sim.new(4, 3)
	assert_int(sim.population()).is_equal(0)
	assert_that(sim.get_cell(2, 1)).is_equal(false)
	assert_int(sim.generation).is_equal(0)


func test_set_e_get_marcam_celulas():
	var sim = Sim.new(4, 3)
	sim.set_cell(1, 1, true)
	assert_that(sim.get_cell(1, 1)).is_equal(true)
	assert_that(sim.get_cell(0, 0)).is_equal(false)
	sim.set_cell(1, 1, false)
	assert_that(sim.get_cell(1, 1)).is_equal(false)


func test_contagem_de_vizinhos_no_centro():
	var sim = make_sim([
		"...",
		"###",
		"...",
	])
	assert_int(sim.count_neighbors(1, 1)).is_equal(2)
	assert_int(sim.count_neighbors(1, 0)).is_equal(3)


func test_fora_da_grade_conta_como_morta():
	var sim = make_sim([
		"##..",
		"##..",
		"....",
	])
	assert_int(sim.count_neighbors(0, 0)).is_equal(3)
	assert_int(sim.count_neighbors(-1, -1)).is_equal(1)
	assert_int(sim.count_neighbors(3, 2)).is_equal(0)


func test_regra1_celula_solitaria_morre():
	var sim = make_sim([
		"#.......",
		"........",
	])
	sim.step()
	assert_int(sim.population()).is_equal(0)


func test_regra2_celula_com_dois_vizinhos_sobrevive():
	var sim = make_sim([
		"##.",
		"#..",
		"...",
	])
	sim.step()
	assert_that(sim.get_cell(0, 0)).is_equal(true)


func test_regra2_bloco_e_estavel():
	var bloco := [
		".##.",
		".##.",
		"....",
	]
	var sim = make_sim(bloco)
	sim.step()
	assert_grid(sim, bloco)


func test_regra3_celula_superpovoada_morre():
	var sim = make_sim([
		".#.",
		"###",
		".#.",
	])
	sim.step()
	assert_that(sim.get_cell(1, 1)).is_equal(false)


func test_regra4_celula_morta_com_tres_vizinhos_nasce():
	var sim = make_sim([
		"...",
		"###",
		"...",
	])
	sim.step()
	assert_that(sim.get_cell(1, 0)).is_equal(true)


func test_step_avanca_o_contador_de_geracoes():
	var sim = make_sim([
		".#.",
		".#.",
		".#.",
	])
	sim.step()
	assert_int(sim.generation).is_equal(1)
	sim.step()
	assert_int(sim.generation).is_equal(2)


func test_atualizacao_e_simultanea_blinker_oscila():
	var sim = make_sim([
		".#.",
		".#.",
		".#.",
	])
	sim.step()
	assert_grid(sim, ["...", "###", "..."])
	sim.step()
	assert_grid(sim, [".#.", ".#.", ".#."])


func test_glider_se_move_em_quatro_geracoes():
	var sim = make_sim([
		".#......",
		"..#.....",
		"###.....",
		"........",
		"........",
		"........",
	])
	for i in 4:
		sim.step()
	assert_grid(sim, [
		"........",
		"..#.....",
		"...#....",
		".###....",
		"........",
		"........",
	])


func test_clear_zera_grade_e_geracao():
	var sim = make_sim(["##", ".."])
	sim.step()
	sim.clear()
	assert_int(sim.population()).is_equal(0)
	assert_int(sim.generation).is_equal(0)


func test_wrap_off_vizinho_alem_da_borda_e_morto():
	var sim = Sim.new(4, 4)
	sim.set_cell(0, 0, true)
	assert_int(sim.count_neighbors(3, 3)).is_equal(0)


func test_wrap_on_vizinho_dobra_pro_outro_lado():
	var sim = Sim.new(4, 4)
	sim.wrap_edges = true
	sim.set_cell(0, 0, true)
	assert_int(sim.count_neighbors(3, 3)).is_equal(1)


func test_wrap_on_glider_sobrevive_cruzando_a_borda():
	var sim = make_sim([
		".#......",
		"..#.....",
		"###.....",
		"........",
		"........",
		"........",
		"........",
		"........",
	])
	sim.wrap_edges = true
	for i in 40:
		sim.step()
	assert_int(sim.population()).is_equal(5)


func test_idade_de_recem_nascida_e_um():
	var sim = make_sim([
		"...",
		"###",
		"...",
	])
	sim.step()
	assert_int(sim.get_age(1, 0)).is_equal(1)


func test_idade_acumula_enquanto_celula_sobrevive():
	var sim = make_sim([
		".##.",
		".##.",
		"....",
	])
	sim.step()
	sim.step()
	assert_int(sim.get_age(1, 0)).is_equal(2)


func test_idade_zera_quando_celula_morre():
	var sim = make_sim([
		"#.......",
		"........",
	])
	sim.step()
	assert_int(sim.get_age(0, 0)).is_equal(0)


func test_stamp_coloca_padrao_na_origem():
	var sim = Sim.new(6, 6)
	sim.stamp([Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)], Vector2i(2, 2))
	assert_that(sim.get_cell(2, 2)).is_equal(true)
	assert_that(sim.get_cell(3, 2)).is_equal(true)
	assert_that(sim.get_cell(2, 3)).is_equal(true)
	assert_that(sim.get_cell(3, 3)).is_equal(false)


func test_stamp_ignora_partes_fora_da_grade():
	var sim = Sim.new(2, 2)
	sim.stamp([Vector2i(0, 0), Vector2i(-3, -3)], Vector2i.ZERO)
	assert_int(sim.population()).is_equal(1)


func test_regra_customizada_sobrevive_com_um_vizinho():
	var sim = make_sim([
		"##....",
		"......",
	])
	sim.set_rule([], [1])
	for i in 5:
		sim.step()
	assert_int(sim.population()).is_equal(2)


func test_seeds_solitaria_morre_sem_nascimento():
	var sim = make_sim([
		"#.......",
		"........",
	])
	sim.set_rule([2], [])
	sim.step()
	assert_int(sim.population()).is_equal(0)


func test_highlife_nasce_com_seis_vizinhos():
	var sim = Sim.new(6, 6)
	for offset in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)]:
		sim.set_cell(2 + offset.x, 2 + offset.y, true)
	assert_int(sim.count_neighbors(2, 2)).is_equal(6)
	sim.set_rule([3, 6], [2, 3])
	sim.step()
	assert_that(sim.get_cell(2, 2)).is_equal(true)


func test_conway_padrao_nao_nasce_com_seis_vizinhos():
	var sim = Sim.new(6, 6)
	for offset in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)]:
		sim.set_cell(2 + offset.x, 2 + offset.y, true)
	sim.step()
	assert_that(sim.get_cell(2, 2)).is_equal(false)


func test_historico_registra_populacao_apos_cada_geracao():
	var sim = make_sim([
		"#.......",
		"........",
	])
	assert_int(sim.population_history().size()).is_equal(0)
	sim.step()
	sim.step()
	assert_array(sim.population_history()).contains_exactly([0, 0])


func test_historico_blinker_mantem_populacao():
	var sim = make_sim([
		".#.",
		".#.",
		".#.",
	])
	sim.step()
	sim.step()
	assert_array(sim.population_history()).contains_exactly([3, 3])


func test_historico_limitado_as_ultimas_amostras():
	var sim = make_sim([
		"##..",
		"##..",
	])
	sim.history_limit = 3
	for i in 5:
		sim.step()
	assert_int(sim.population_history().size()).is_equal(3)
	assert_int(sim.population_history()[2]).is_equal(sim.population())


func test_clear_zera_o_historico():
	var sim = make_sim(["##", ".."])
	sim.step()
	sim.clear()
	assert_int(sim.population_history().size()).is_equal(0)