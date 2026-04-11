# web-community-vault

## セットアップ

### ローカルにpython3仮装環境を立ち上げて MkDocsを動かしたい場合

```bash
uv venv .venv
source .venv/bin/activate
uv pip install -r requirements.txt
mkdocs serve
```

### docker でMkDocsを動かしたい場合

```bash
docker compose up
```

## MkDocs使い方

```bash
mkdocs serve # 開発環境立ち上げ
mkdocs build # ビルドファイル
mkdocs --help # ヘルプ
```
