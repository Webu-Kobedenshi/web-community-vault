# web-community-vault

このリポジトリはvscodeで編集することを前提としています。以下が推奨の拡張機能です。

- mosapride.zenkaku
- davidanson.vscode-markdownlint
- takumii.markdowntable
- yzhang.markdown-all-in-one
- bierner.markdown-mermaid

## セットアップ (どちらもホットリロード未対応)

### docker でMkDocsを動かしたい場合 (推奨)

```bash
docker compose up
```

- [http://localhost:18000/]

### ローカルにpython3仮装環境を立ち上げて MkDocsを動かしたい場合

```bash
uv venv .venv
source .venv/bin/activate
uv pip install -r requirements.txt
mkdocs serve
```

- [http://localhost:8000/]

## MkDocs使い方

```bash
mkdocs serve # 開発環境立ち上げ
mkdocs build # ビルドファイル
mkdocs --help # ヘルプ
```
