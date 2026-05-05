---
date: 2026-05-05
authors:
  - junhat6
categories:
  - 運営の独り言
slug: sync-attendance
---

# コミュニティ出欠確認を「Discord 内で完結」させる

## TL;DR

- 活動日に「誰が来た／来てない」を毎週記録したかった
- Google フォームは外部サイトに飛ぶのが面倒、GAS は Discord チャンネルを直接読むのがセキュリティ要件で詰んだ
- **GitHub Actions の cron に全部寄せる** ことで、Discord の Poll 機能と Google スプレッドシートを橋渡しする仕組みを作った
- 設計の肝は「冪等性」「Discord 側を真実とする」「集計ロジックを純粋関数に切り出す」の3つ

リポジトリ: `Webu-Kobedenshi/webu-attendance`

<!-- more -->

---

## 1. やりたかったこと

学生団体（We部）の活動日が毎週木曜にあり、運営として「最近来てない人いない？」を継続的に把握したい。が、現状は雰囲気で察するしかない。

要件を整理するとこんな感じです。

- 活動日の朝〜開始直前に、Discord に出欠確認が **自動で** 流れる
- 部員は **Discord 内で** 回答できる（外部サイトに飛びたくない）
- 結果は Google スプレッドシートに溜まり、運営は1枚のシートを見れば「3週連続で欠席」「ずっと未回答」みたいな兆候を察知できる
- リアルタイム性は要らない。**未回答の人もちゃんと集計対象に入る** ことの方が大事

「外部サイトに飛びたくない」と「未回答も拾う」の2点が、後の技術選定を決めることになります。

---

## 2. 候補の比較と「なぜGASを諦めたか」

最初に検討した選択肢は2つでした。

### 案A: Google フォーム + スプレッドシート

- ✅ 構築コストほぼゼロ
- ❌ Discord から **離脱して回答** しなければならない
- ❌ そもそも「未回答者」をフォーム単体で拾うのは難しい（誰が回答してないか集計するには別途名簿の突合が必要）

「Discord 内で完結」を満たさないので却下。

### 案B: GAS (Google Apps Script) で Discord を読む

「GAS から Discord API を叩けば、Discord で完結＋スプレッドシートに反映、までワンストップでいけるじゃん」と最初は思いました。書き込み（Webhook 経由のメッセージ送信）はあっさり通る、という記事もよく見かけます。

**ところが、`UrlFetchApp` から Discord の読み取り系 API を叩くと、片っ端から 403 で弾かれます。**

```
Exception: Request failed for https://discord.com returned code 403.
```

Bot Token を正しく `Authorization: Bot xxxx` に入れていてもダメ。最初は権限不足や Intent 設定を疑って試行錯誤しましたが、調べていくと同じ症状の人が大量に居て、原因は GAS 側のリクエスト元（Google のサーバ群の IP / User-Agent）が Discord の保護レイヤ（Cloudflare）に弾かれているらしい、という結論。回避策として中継サーバや特殊なリトライを噛ませている記事もありますが、運用するシステムとしてやりたくない領域です。

> 参考: GAS から Discord の読み取り API が 403 で弾かれる問題は複数記事で報告されています。例: [GAS と Discord 連携の難しさについて](https://note.com/manavi_va/n/n8e050c9df82c)
>
> Google の AI Overview でも同様に「GAS 側から定期的に Discord API を叩いて新着メッセージを確認する手法はセキュリティの壁があり難易度が高い」と書かれています。

つまり、

- **送信（Webhook）はいける**
- **読み取り（メッセージ取得・Poll 投票者取得など）はほぼ通らない**

という非対称性があり、今回やりたい「Poll に誰が投票したかを後から集計する」 は完全に **読み取り側** の話なので、GAS では事実上詰みました。

### 採用: GitHub Actions に全振り

GitHub Actions 上で叩いた Discord API は **同じトークンですんなり通った** ので、結果的にこっちで全部組むことに。副次的なメリットとして、

- cron は GitHub Actions の `schedule` で書ける
- Bot Token / Service Account の鍵は GitHub Secrets に置ける
- ジョブの履歴・ログが Actions のタブにそのまま残る（実行成否を後から追える）
- ロジックは普通の TypeScript として書ける（型・補完・テストの恩恵がある）

「やむを得ず GitHub Actions」だったのが、運用してみたら **履歴管理という意味で結果オーライ** だった、というのが正直なところです。

## 3. システム全体像

```
木曜 09:00 JST  ─┐
                 │ GitHub Actions (cron) が Discord に Poll を自動投稿
                 │   → 「【YYYY-MM-DD】本日の出欠を回答してください」
                 │   → 選択肢: 出席 / 欠席（8時間後に Discord 側で自動締切）
                 │
木曜 17:05 JST  ─┤ GitHub Actions (cron) が Poll の投票結果を集計
                 │   → Discord から投票者リストを取得
                 │   → members シートと突合し「出席 / 欠席 / 未回答」を判定
                 │   → raw_log に追記、dashboard を再生成
                 │
任意のタイミング ─┘ 運営が dashboard シートを目視確認
```

Workflow は3本：

| Workflow       | トリガー                   | 役割                                                |
| -------------- | -------------------------- | --------------------------------------------------- |
| `post-poll`    | cron 木曜 09:00 JST + 手動 | Poll を立てる                                       |
| `collect-poll` | cron 木曜 17:05 JST + 手動 | 投票結果を集計してダッシュボード再生成              |
| `sync-members` | 手動のみ                   | members シートを Discord Guild の最新状態で全上書き |

毎日変わらない `members` の同期は cron に乗せず、運営が必要なときに `workflow_dispatch` で叩く設計。**クリティカルパス（毎週確実に走らせたい post/collect）と、メンテ系のジョブを分離** したかったためです。

---

## 4. 設計の核

ここが一番伝えたい部分です。書いてみると当たり前ですが、最初は意識しないと普通に泥団子化していきます。

### 4.1 冪等性 — cron は二重実行されるという前提

GitHub Actions の cron は「ジッタがある」「リトライ可能」「人間が `workflow_dispatch` でも叩ける」ので、**同じ日に複数回走り得る** と仮定して設計します。

そのために `activity_log` シートに「今日 Poll を投稿したか／集計したか」という状態を持たせています。

```
activity_log
| date       | message_id | status    | posted_at           | collected_at        |
| ---------- | ---------- | --------- | ------------------- | ------------------- |
| 2026-05-01 | 12345...   | collected | 2026-05-01T09:00:01 | 2026-05-01T17:05:08 |
| 2026-05-08 | 67890...   | posted    | 2026-05-08T09:00:01 |                     |
```

`post-poll` は「同日に既にレコードがあれば何もせず終わる」、`collect-poll` は「`status === "collected"` なら何もせず終わる」。実装はこれだけです。

```ts
// scripts/post-poll.ts
const existing = await findActivityLogByDate(today);
if (existing) {
  console.log(`既に投稿済みのためスキップ`);
  return;
}
```

「強制再集計したい場合は `status` を手動で `posted` に戻せばよい」という運用エスケープハッチを残してあるのもポイント。完全自動化を目指すと、**異常系の人手介入が逆にしんどく** なるので、シートを直接いじって戻す経路を残す方が現実的でした。

### 4.2 Discord 側を「真実」として扱う

「メンバーリスト」は Sheets と Discord のどっちで持つか問題が必ず発生します。両方に持たせると **同期がバグる** のは見えていたので、

> Discord Guild が真実、Sheets はその派生データ

と決めました。具体的には：

- `members` シートは `sync-members` で **全上書き**（merge ではなく clear → write）
- 退会者は次の同期で消える
- ロール未付与の人も載る（Discord に居る = 集計対象）

```ts
// src/sheets.ts
export async function overwriteMembers(members: Member[]): Promise<void> {
  // [1] 既存シートを全消し
  await sheets.spreadsheets.values.clear({ ... });
  // [2] ヘッダー + データを書き込む
  await sheets.spreadsheets.values.update({ ... });
}
```

「全消し→全書き」を選んだ理由は、**差分同期はバグを書きやすいそうだった** から。

### 4.3 集計ロジックを純粋関数に切り出す

ダッシュボード生成（誰がいつ出席／欠席／未回答だったかを2次元配列にする処理）は、**Sheets API を一切呼ばない純粋関数** にしました。

```ts
// src/dashboard.ts
export function buildDashboard(
  rawLog: RawLogRow[],
  members: Member[],
): string[][] {
  // ... チーム → 表示名でソートして2次元配列を作るだけ
}
```

呼び出し側はこう。

```ts
// scripts/collect-poll.ts
const allRawLog = await getAllRawLog();
const allMembers = await getMembers();
const dashboardData = buildDashboard(allRawLog, allMembers); // ← 純粋関数
await rewriteDashboard(dashboardData);                       // ← I/O
```

こうしておくと、

- ロジックの単体テストが Sheets API なしで書ける
- 仕様変更（並び順を「チーム → 表示名」→「最終出席日順」に変えたい等）が一箇所で済む
- 「シートを読む処理がぶっ壊れたとき」と「並び替えロジックがぶっ壊れたとき」が切り分けられる

「I/O とロジックを分ける」って何度言われても忘れがちですが、こういう小さいプロジェクトでも刺さります。

### 4.4 「未回答」を一級市民にする

最初の要件で書いた「**未回答もちゃんと集計に入る**」をどう実装するか。

`collect-poll` のロジックは、Poll の投票者を取って終わりではなく、

1. `members` シートから現役メンバー全員を取得
2. Discord Poll API から「出席」「欠席」それぞれの投票者を取得
3. **メンバー全員を for ループで回し、投票していない人は `未回答` として行を作る**

```ts
for (const member of members) {
  if (attendMap.has(member.discordId)) {
    attendance = "出席";
  } else if (absentMap.has(member.discordId)) {
    attendance = "欠席";
  } else {
    attendance = "未回答"; // ← ここがほしかった
  }
  rawLogRows.push({ date: today, discordId: member.discordId, ..., attendance });
}
```

Google フォームでは「フォームに来なかった人」を集計対象にするのが手間でしたが、**メンバーマスタを起点にループする** ことで自然に解決しました。Discord Poll 側のデータと突合する向きを「メンバー × Poll 投票」にするのがコツです。

ダッシュボード上は `○ / × / △ / 空` の4状態。

|     | 表示名 | ロール | 2026-04-24 | 2026-05-01 | 2026-05-08 |
| --- | ------ | ------ | ---------- | ---------- | ---------- |
|     | 山田   | team1  | ○          | ○          | △          |
|     | 佐藤   | team2  | ○          | ×          | ×          |

「△ や × が3つ並んでる行」を運営が目視で拾えるようにする、というのが当初のゴールでした。

---

## 5. 設計判断のメタな話

このプロジェクト、コード量自体は1000行ちょっとで、全然大したものではありません。にも関わらず、設計判断は意外と多くしました。中でも自分的に「やってよかった」のはこの3つ。

1. **状態管理を Sheets に押し付けた**
   → 「`activity_log` の `status` 列」というたった1列で冪等性が成り立つ。RDB を立てるとか KV ストアを契約するとかをしなくて済む。**運用環境が既にあるなら、そこに状態を寄せる** のは強い。

2. **「Discord 側が真実」を明文化した**
   → 「mastersデータをどこに置くか」は揉めがち。最初に方針を決めて README に書いておくと、機能追加で迷わない。

3. **完全自動化を目指さず、運用エスケープハッチを残した**
   → 「強制再集計したいときは status を手で戻して」みたいな運用手順を README に書いてある。**自動化の網に穴を空けておく** のは弱さではなく、現実的な強さだと思っています。

---

## 6. まとめ

- 「Discord で完結する出欠確認」を、GitHub Actions + Discord Poll + Google Sheets で組んだ
- GAS は403で弾かれるため、Github Actionsを採用。結果的に履歴管理やチームメンバーとの共有、透明性が保ちやすくなったため結果オーライ。
- 設計の鍵は **冪等性・Discord 側を真実とする・I/O とロジックの分離** の3つ
- 小さいプロジェクトでも、「状態をどこに置くか」「真実はどっちにあるか」を最初に決めると、後々ラク

リポジトリ: <https://github.com/Webu-Kobedenshi/webu-attendance>

---
