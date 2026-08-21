# GDD — Jogo da Vida (Conway's Game of Life)

**Projeto:** game-of-life · **Engine:** Godot 4.7 (GL Compatibility) · **Data:** 2026-08-21

---

## 1. Visão geral

Simulação do autômato celular de Conway: uma grade de células vivas/mortas que evolui
geração após geração seguindo 4 regras simples. Não há vitória nem derrota — é um
*brinquedo* de simulação (sandbox interativo) onde a diversão vem dos padrões emergentes.
Projeto de aprendizado de Godot, escopo deliberadamente pequeno.

## 2. Objetivos

### Aprendizado (motivação principal)
- Ciclo básico da engine: cena → script → rodar
- Modelar uma grade de dados e renderizá-la
- Input de mouse (pintar células)
- Tick de simulação desacoplado do framerate (timer/acumulador)
- UI mínima (botões, slider)

### Experiência do jogador
- Observar padrões emergentes (gliders, osciladores, ainda-lifes)
- Desenhar e experimentar livremente na grade

## 3. Mecânica central — Regras de Conway

Cada célula olha para seus 8 vizinhos. A cada geração, simultaneamente:

1. Viva com **menos de 2** vizinhos vivos → morre (solidão)
2. Viva com **2 ou 3** vizinhos vivos → sobrevive
3. Viva com **mais de 3** vizinhos vivos → morre (superpopulação)
4. Morta com **exatamente 3** vizinhos vivos → nasce

## 4. Grade

| Propriedade | Valor |
|---|---|
| Tamanho inicial | 64 × 36 células (célula de 16 px ⇒ 1024 × 576) |
| Estados por célula | viva / morta |
| Bordas (MVP) | fixas: fora da grade conta como morta |
| Bordas (fase 2) | wrap-around toroidal, alternável |

## 5. Controles

| Ação | Entrada |
|---|---|
| Pintar células | Clique esquerdo (ou arrastar) |
| Apagar células | Clique direito (ou arrastar) |
| Play / Pause | `Espaço` ou botão |
| Avançar 1 geração | `.` ou botão |
| Limpar grade | `C` ou botão |
| Aleatorizar | `R` ou botão |
| Velocidade do tick | Slider (ex.: 1–30 gen/s) |

## 6. HUD mínimo

Botões Play/Pause · Step · Clear · Random, slider de velocidade,
e contadores: **geração atual** e **população viva**.

## 7. Escopo

### MVP (fase 1)
Grade fixa, as 4 regras, pintura com mouse, play/pause/step/clear/random, contadores.

### Fase 2
Wrap toroidal (toggle), presets de padrões (glider, LWSS, pulsar, Gosper gun),
envelhecimento visual das células (cor muda com a idade).

### Fase 3 (ideias)
Regras customizáveis B/S (HighLife, Seeds…), zoom e pan, salvar/carregar padrões
(formato RLE), estatísticas históricas.

## 8. Notas técnicas (Godot 4.x)

- Uma cena `Main.tscn`; simulação num nó raiz `Node2D`.
- **Dados:** dois buffers planos (`PackedByteArray` 0/1) com *double-buffering* —
  calcular a próxima geração lendo só o buffer atual; mutar durante o passo corrompe a regra 4.
- **Render:** duas opções viáveis:
  - `TileMapLayer` com 2 tiles (vivo/morto) — idiomático, usa o editor;
  - `_draw()` custom (`draw_rect`) — mais didático e fácil de colorir por idade.
  Recomendação: começar com `_draw()`, migrar depois se quiser.
- **Tick:** acumulador de tempo em `_process(delta)` (gen/s configurável), não usar FPS.
- **Input:** pintura via `_unhandled_input`; converter posição global do mouse → índice
  de célula (considerando escala/janela).
- Física desnecessária (Jolt fica configurado mas sem uso).

## 9. Critérios de pronto (MVP)

- [ ] Um glider desenhado à mão anda corretamente pela grade
- [ ] Pintar/apagar funciona pausado **e** rodando
- [ ] Slider altera a velocidade sem engasgar a UI
- [ ] Contadores de geração e população batem com o estado visível
