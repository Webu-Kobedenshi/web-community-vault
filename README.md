# web-community-vault

## セットアップ

このリポジトリでは `uv` で仮想環境を作って、`requirements.txt` から依存を入れます。

```bash
uv venv .venv
source .venv/bin/activate
uv pip install -r requirements.txt
mkdocs serve
```

仮想環境を有効化せずに実行したい場合は、次でも動きます。

```bash
uv venv .venv
uv pip install -r requirements.txt
uv run mkdocs serve
```