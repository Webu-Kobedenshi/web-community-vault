# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

このリポジトリは、神戸電子専門学校の非公式コミュニティ「We部」のナレッジベースです。MkDocs（Material テーマ）で構築されたドキュメントサイトで、GitHub Pages にデプロイされています。また、OpenClawの記憶領域としても使用されます。

**コミュニティ概要：**
- 対象：神戸電子専門学校 IT 学科の主に 1・2 年生
- 主な活動：チーム制作（成果物作成・チーム開発経験の積み上げ）
- その他の活動：LT 会、就職対策（今後拡充予定）
- 設立目的：長期インターン採用に向けた成果物・チーム開発経験の獲得、エンジニアとしての基礎力向上
- メンバー：神戸電子専門学校 IT 学科の学生。株式会社オプティムの OB・社員は見学、意見。
- 外部連携：株式会社オプティム

**NotebookLM 連携の目的：**
コミュニティメンバーが運営に質問せずとも、このリポジトリに蓄積されたドキュメントから NotebookLM を通じて自己解決できる仕組みを目指す。

## 開発コマンド

### ローカル開発（Python 仮想環境）

```bash
uv venv .venv
source .venv/bin/activate
uv pip install -r requirements.txt
mkdocs serve          # 開発サーバー起動（http://localhost:8000）
```

### Docker で起動する場合

```bash
docker compose up     # http://localhost:18000 でアクセス可能
```

## アーキテクチャ

- **`mkdocs.yml`** — サイト設定。ナビゲーション構造はここで管理する。テーマは `material`（日本語設定済み）、Mermaid 図表をサポートする `pymdownx.superfences` が有効。
- **`docs/`** — すべてのコンテンツ（Markdown ファイル）。新しいページはここに追加し、`mkdocs.yml` の `nav` セクションに登録する。
- **`.github/workflows/ci.yml`** — `main` または `master` ブランチへの push で自動的に `mkdocs gh-deploy` が実行される。
- **`requirements.txt`** — `mkdocs` と `mkdocs-material` のみ。

## コンテンツ方針

**蓄積する内容：**
- コミュニティの説明・理念・目的（抽象レベルの概要）
- 活動内容・活動報告
- 今後の活動予定・方針

**蓄積しない内容：**
- 技術記事（具体的な実装方法など）は対象外

**NotebookLM を意識した書き方：**
ドキュメントは「コミュニティメンバーが質問したときに AI が答えられる」ことを前提に、Q&A 的に読み解きやすい構造で書く。

## コンテンツ追加のルール

- 新しいページは `docs/` 配下に Markdown で作成し、`mkdocs.yml` の `nav` に追加する。
- Mermaid 記法による図表が使用可能（` ```mermaid ` ブロック）。
- サイト全体の言語は日本語（`language: ja`）。
