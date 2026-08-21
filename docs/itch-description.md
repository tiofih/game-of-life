# Jogo da Vida — descrição para itch.io

## Título curto

Jogo da Vida (Godot 4)

## Frase de efeito (slogan)

Desenhe vida, observe a emergência — o autômato celular de Conway com TDD, toro e canhão de Gosper.

---

## Descrição (colar no campo "Description")

Um brinquedo de simulação do famoso **autômato celular de Conway**, feito em **Godot 4.7**
como projeto de aprendizado da engine — com **TDD desde o primeiro commit** (36 testes).

Não há vitória nem derrota: desenhe células na grade, aperte Play e observe padrões
emergirem das quatro regras mais simples do universo dos jogos.

### Destaques

- 🖌️ Pinte com o mouse (esquerdo desenha, direito apaga)
- 🧬 Pincéis de padrões clássicos: Glider, LWSS, Pulsar e **Canhão de Gosper**
- 🔄 Modo **Toro**: bordas conectadas — gliders dão a volta no mundo
- ⚗️ Quatro universos alternativos: Conway, HighLife, Seeds e Day & Night
- 🎨 Células que envelhecem (verde → azul) e gráfico de população ao vivo
- 💾 Salve/carregue seus padrões em **RLE** — compatível com LifeWiki
- 🔍 Zoom com pinça/roda e pan com dois dedos/botão do meio

### Como jogar

1. Desenhe células com o botão esquerdo (ou estampe um padrão pelo pincel)
2. Aperte **Play** ou `Espaço`
3. Experimente: botão **Random** + regra **Seeds** = fogos de artifício instantâneos

Feito com Godot 4 · GL Compatibility · gdUnit4

---

## Checklist de upload

- [ ] Cover image: `docs/media/cover.png` (630×500)
- [ ] Screenshots: `docs/media/screenshot.png` (1024×672)
- [ ] Kind of project: **Downloadable** → também marcar "This file will be played in the browser"
- [ ] Upload do arquivo: zip do conteúdo de `export/web/` (index.html, index.js, index.wasm, index.pck, ícones)
- [ ] Classificação: Todos / Ferramenta ou Toy
- [ ] Tags sugeridas: sandbox, simulation, cellular-automata, godot, toy, educational
