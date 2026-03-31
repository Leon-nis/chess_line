# Chess Line

Chess Line e um prototipo de batalha simultanea em Bend. Cada lado escolhe uma peca da reserva, confirma a jogada, e a linha inteira resolve junto: movimento, cruzamento, dano e resultado.

Este repositorio existe para publicar o jogo sem carregar o repo inteiro do Bend2. Aqui fica so o necessario para compilar o app, versionar os assets e fazer deploy automatico no GitHub Pages.

## O que tem aqui

- `src/chess_line/main.bend`: codigo do jogo
- `src/chess_line/assets/`: sprites das pecas
- `scripts/build-pages.sh`: gera o site estatico em `dist/`
- `.github/workflows/pages.yml`: publica no GitHub Pages a cada push em `main`

## Como jogar

- White: `A` pawn, `S` bishop, `D` knight, `F` rook, `G` queen, `,` pass
- Black: `Y` pawn, `U` bishop, `I` knight, `O` rook, `P` queen, `.` pass
- `Enter`: confirma o turno
- `R`: reinicia a partida

## Build local

Se voce ja tiver um checkout do Bend2 na maquina:

```bash
BEND2_DIR=/caminho/para/Bend2 bash ./scripts/build-pages.sh
```

O site gerado vai para `dist/index.html`.

Se quiser abrir localmente:

```bash
cd dist
python3 -m http.server 8080
```

Depois acesse:

```text
http://localhost:8080
```

## Publicacao

Depois do primeiro push, o fluxo do GitHub Pages fica simples:

1. abrir o repositorio no GitHub
2. entrar em `Settings > Pages`
3. selecionar `GitHub Actions` em `Build and deployment`
4. deixar o workflow `Deploy Pages` cuidar do resto

URL esperada:

```text
https://Leon-nis.github.io/chess_line/
```

## Atualizando o jogo

Sempre que voce mudar `src/chess_line/main.bend` ou os arquivos em `src/chess_line/assets/`, basta commitar e dar push. O workflow recompila e publica a nova versao.
