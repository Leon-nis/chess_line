# chess_line

Repo standalone do app `chess_line`, pronto para publicar no GitHub Pages.

## Estrutura

- `src/chess_line/main.bend`: app Bend
- `src/chess_line/assets/`: imagens das peças
- `scripts/build-pages.sh`: gera `dist/index.html`
- `.github/workflows/pages.yml`: build + deploy no GitHub Pages

## Uso local

Se voce ja tiver um checkout do Bend2:

```bash
BEND2_DIR=/caminho/para/Bend2 ./scripts/build-pages.sh
```

Sem um checkout local, o script baixa o Bend2 automaticamente no commit fixado.

O output vai para `dist/`.

## Subir para o GitHub

Crie um repo vazio no GitHub, depois rode na raiz deste diretorio:

```bash
git init
git add .
git commit -m "Initial standalone chess_line site"
git branch -M main
git remote add origin git@github.com:SEU_USUARIO/chess-line.git
git push -u origin main
```

## Ativar Pages

Depois do primeiro push:

1. Abra o repo no GitHub.
2. Entre em `Settings > Pages`.
3. Em `Build and deployment`, escolha `GitHub Actions`.
4. Espere o workflow `Deploy Pages` terminar.

URL esperada:

```text
https://SEU_USUARIO.github.io/chess-line/
```

## Atualizar o jogo

Sempre que voce mudar `src/chess_line/main.bend` ou `src/chess_line/assets/`, basta dar push na branch `main`. O workflow recompila e publica de novo.
