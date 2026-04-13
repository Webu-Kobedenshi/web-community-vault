---
date: 2026-04-13
authors:
  - junhat6
categories:
  - 運営の独り言
slug: notebooklm-sync
---

# NotebookLM との自動同期、ようやく動いた

4月11日の投稿で「いつかやりたい」と書いていた NotebookLM 自動同期の仕組みが、完成しました。GitHub Actions で `docs/` の内容を Google ドライブに自動で送り込む仕組みです。思ったより NotebookLM の制約が多くて、だいぶ遠回りしました。

<!-- more -->

## NotebookLM の制約と格闘した話

### 「Google ドライブのフォルダごと参照」はできない

最初、NotebookLM に Google ドライブのフォルダを丸ごと参照させるつもりでいました。ドキュメントを更新して同期すれば自動でナレッジが更新される——そういうイメージです。

ところが実際には、**NotebookLM はフォルダ参照に対応していません。ファイルを1つずつ個別に追加する必要があります。**

### `.md` ファイルは参照できない

次に、Google ドライブ上の Markdown ファイルをそのまま参照しようとしたのですが、これも駄目でした。NotebookLM がソースとして読み込めるのは `.txt`・`.pdf` などのフォーマットで、`.md` は対象外です。

つまり「Google ドライブに `.md` を置いて参照させる」という方法は最初から成立しない話でした。

### ファイルを1個ずつ追加するのが面倒

`.txt` に変換したとしても、ファイル参照は1個ずつ手動で追加しなければなりません。`docs/` 配下のファイルが増えるたびに NotebookLM 側でも追加作業が発生するのは、運用として続きません。

### 解決策：全ファイルを1つの `.txt` にまとめて送る

結局、`docs/` 配下のすべての Markdown を **1つの `combined-docs.txt` に結合してから Google ドライブに送る** 方針に落ち着きました。NotebookLM に追加するのはこの1ファイルだけ。ドキュメントが増えても NotebookLM 側の操作は変わりません。

## 今日やったこと

### GitHub Actions × rclone で Google ドライブ同期

`main` ブランチへのpushをトリガーに、`docs/` 配下のファイルを Google ドライブの `web-community-vault/` フォルダへ rclone で同期するワークフローを新規作成しました（`.github/workflows/sync-google-drive.yml`）。

rclone の設定は `secrets.RCLONE_CONF` に格納する方針で、認証情報をリポジトリに含めることなく動かしています。

### ワークフローの安定化

試行錯誤のなかでいくつか細かい問題が出たので順番に対処しました：

- `actions/checkout@master` を `actions/checkout@v4` に変更（`master` 指定は不安定なため）
- 複数ファイルを別々にpushしていた箇所を、結合した一つのファイルにまとめて送るよう整理

### NotebookLM リンクと同期手順をトップページに追加

サイトの `index.md` に NotebookLM へのリンクを外部リンク一覧に追加しました。また、NotebookLM はファイルの再読み込みが自動ではないため、「Google ドライブと同期」ボタンを手動で押す必要があります。その手順を tip として明記しています。

## 今後について

これでドキュメントを更新して `main` にpushすれば、Google ドライブ側の `combined-docs.txt` が自動更新され、NotebookLM で同期ボタンを押すだけで最新のナレッジが反映される流れが整いました。

「同期ボタンを手動で押す」というステップはまだ残っていますが、ひとまず運用できるレベルには到達したと思っています。NotebookLM の API や自動化の余地があるか、引き続き調べていくつもりです。
