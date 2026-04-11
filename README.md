# web-community-vault

このリポジトリはvscodeで編集することを前提としています。
推奨の拡張機能は[.vscode/setting.json]をご覧ください。

## セットアップ (どちらもホットリロード未対応)

### docker でMkDocsを動かしたい場合 (推奨)

```bash
docker compose up
```

- [http://localhost:8900/]

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

## git hook セットアップ（コミット前自動フォーマット）

`git commit` 時に変更した Markdown ファイルへ自動で markdownlint が実行されます。
Node.js が必要です。

```bash
git config core.hooksPath .githooks
```

## 一括フォーマット

`jbockle.jbockle-format-files`を使用。
コマンドパレット（Ctrl+Shift+P）を開き、「Start Format Files: Workspace」と入力。
全てのファイルがフォーマットされる。
