# 歌詞チェーン機能 詳細設計

## 概要

すれ違い時にユーザーが歌詞の一節を投稿し、4〜8人分の歌詞が集まると Google DeepMind の **Lyria** を使って楽曲を自動生成する機能。

## コンセプト

```
「見知らぬ人との出会いが、一つの音楽を生み出す」
```

- 一人では作れない曲が、偶然の出会いによって誕生する
- Brand New "Hello World" の究極の形

---

## ユーザーフロー

```
┌─────────────────────────────────────────────────────────────┐
│ 1. すれ違い成立                                             │
│    ↓                                                        │
│ 2. 歌詞入力UI表示（任意）                                   │
│    └─ スキップ可能                                          │
│    ↓                                                        │
│ 3. 歌詞送信 → LyricChain に追加                             │
│    └─ 新規Chain作成 or 既存Chainに追加                      │
│    ↓                                                        │
│ 4. Chain参加者数が閾値到達（4〜8人）                        │
│    ↓                                                        │
│ 5. Lyria生成ジョブをキューに追加                            │
│    ↓                                                        │
│ 6. Workerが非同期で楽曲生成                                 │
│    └─ Gemini でムード分析 → Lyria で楽曲生成                │
│    ↓                                                        │
│ 7. 生成完了 → 参加者全員にプッシュ通知                      │
│    ↓                                                        │
│ 8. 生成曲の再生・共有                                       │
└─────────────────────────────────────────────────────────────┘
```

---

## データモデル

### エンティティ関連図

```
┌─────────────────┐      ┌─────────────────┐
│      User       │      │   LyricChain    │
├─────────────────┤      ├─────────────────┤
│ id              │      │ id              │
│ display_name    │      │ status          │
│ ...             │      │ participant_cnt │
│                 │      │ threshold       │
└────────┬────────┘      │ created_at      │
         │               │ completed_at    │
         │               └────────┬────────┘
         │                        │
         │    ┌───────────────────┘
         │    │
         ▼    ▼
┌─────────────────┐      ┌─────────────────┐
│   LyricEntry    │      │  GeneratedSong  │
├─────────────────┤      ├─────────────────┤
│ id              │      │ id              │
│ chain_id (FK)   │◄─────│ chain_id (FK)   │
│ user_id (FK)    │      │ title           │
│ content         │      │ audio_url       │
│ sequence_num    │      │ duration_sec    │
│ encounter_id    │      │ mood            │
│ created_at      │      │ generated_at    │
└─────────────────┘      │ status          │
                         └─────────────────┘
```

### LyricChain（歌詞チェーン）

| カラム | 型 | 説明 |
|--------|-----|------|
| id | UUID | 主キー |
| status | ENUM | pending / generating / completed / failed |
| participant_count | INT | 現在の参加者数 |
| threshold | INT | 生成トリガー閾値（4〜8、デフォルト4） |
| created_at | TIMESTAMP | 作成日時 |
| completed_at | TIMESTAMP | 楽曲生成完了日時（nullable） |

### LyricEntry（歌詞エントリ）

| カラム | 型 | 説明 |
|--------|-----|------|
| id | UUID | 主キー |
| chain_id | UUID | FK → LyricChain |
| user_id | UUID | FK → User |
| content | TEXT | 歌詞内容（最大100文字） |
| sequence_num | INT | チェーン内の順番（1〜8） |
| encounter_id | UUID | FK → Encounter（すれ違いに紐付け） |
| created_at | TIMESTAMP | 投稿日時 |

### GeneratedSong（生成楽曲）

| カラム | 型 | 説明 |
|--------|-----|------|
| id | UUID | 主キー |
| chain_id | UUID | FK → LyricChain（1対1） |
| title | VARCHAR(100) | 曲タイトル（Geminiで自動生成） |
| audio_url | TEXT | Cloud Storage URL |
| duration_sec | INT | 楽曲の長さ（秒） |
| mood | VARCHAR(50) | ムード（melancholic, upbeat, etc.） |
| genre | VARCHAR(50) | ジャンル |
| generated_at | TIMESTAMP | 生成完了日時 |
| status | ENUM | processing / completed / failed |

---

## API設計

### POST /api/v1/lyrics

すれ違い成立時に歌詞を投稿する。

**Request:**
```json
{
  "encounter_id": "uuid",
  "content": "今日も空は青かった"
}
```

**Response (201 Created):**
```json
{
  "lyric_entry": {
    "id": "uuid",
    "chain_id": "uuid",
    "sequence_num": 3,
    "content": "今日も空は青かった",
    "created_at": "2025-03-15T10:00:00Z"
  },
  "chain": {
    "id": "uuid",
    "participant_count": 3,
    "threshold": 4,
    "status": "pending"
  }
}
```

**ビジネスロジック:**
1. 「pending」状態の空きがあるChainを検索
2. 空きがなければ新規Chain作成
3. LyricEntryを追加
4. participant_count >= threshold なら status を「generating」に変更し、生成ジョブをキュー

### GET /api/v1/lyrics/chains/{chain_id}

チェーンの詳細と参加者の歌詞一覧を取得。

**Response:**
```json
{
  "chain": {
    "id": "uuid",
    "status": "completed",
    "participant_count": 4,
    "threshold": 4,
    "created_at": "2025-03-15T09:00:00Z",
    "completed_at": "2025-03-15T10:05:00Z"
  },
  "entries": [
    {
      "sequence_num": 1,
      "content": "夜明け前の静けさの中",
      "user": { "display_name": "ユーザーA", "avatar_url": "..." }
    },
    ...
  ],
  "song": {
    "id": "uuid",
    "title": "夜明けの詩",
    "audio_url": "https://storage.googleapis.com/...",
    "duration_sec": 45,
    "mood": "melancholic"
  }
}
```

### GET /api/v1/songs/me

自分が参加した生成楽曲一覧。

**Response:**
```json
{
  "songs": [
    {
      "id": "uuid",
      "title": "夜明けの詩",
      "audio_url": "...",
      "participant_count": 4,
      "my_lyric": "今日も空は青かった",
      "generated_at": "2025-03-15T10:05:00Z"
    }
  ]
}
```

---

## Chainマッチングロジック

### 新規歌詞投稿時のChain選択

```go
func (uc *LyricUseCase) SubmitLyric(ctx context.Context, userID, encounterID uuid.UUID, content string) (*LyricEntry, error) {
    var entry *LyricEntry

    // 1. Chain選択からEntry作成、カウント更新までを同一トランザクションで実行
    err := uc.txManager.RunInTx(ctx, func(tx TxContext) error {
        // 2. 利用可能なpending Chainを SELECT FOR UPDATE で検索して排他ロック
        chain, err := uc.chainRepo.FindAvailableChain(tx, userID)
        if err != nil {
            return err
        }

        // 3. 空きChainがなければ同一トランザクション内で新規作成
        if chain == nil {
            chain = &LyricChain{
                ID:        uuid.New(),
                Status:    ChainStatusPending,
                Threshold: 4, // デフォルト閾値
            }
            if err := uc.chainRepo.Create(tx, chain); err != nil {
                return err
            }
        }

        // 4. ロック済みのParticipantCountから連番を計算してEntryを作成
        entry = &LyricEntry{
            ID:          uuid.New(),
            ChainID:     chain.ID,
            UserID:      userID,
            Content:     content,
            SequenceNum: chain.ParticipantCount + 1,
            EncounterID: encounterID,
        }

        if err := uc.entryRepo.Create(tx, entry); err != nil {
            return err
        }
        chain.ParticipantCount++

        // 5. 閾値到達チェック
        if chain.ParticipantCount >= chain.Threshold {
            chain.Status = ChainStatusGenerating
            // 生成ジョブをOutboxに追加
            if err := uc.outboxRepo.Enqueue(tx, OutboxTypeLyriaGeneration, chain.ID); err != nil {
                return err
            }
        }

        return uc.chainRepo.Update(tx, chain)
    })

    return entry, err
}
```

### Chain選択の条件

| 条件 | 説明 |
|------|------|
| status = 'pending' | 生成待ちのChainのみ |
| participant_count < threshold | 空きがあるChain |
| user未参加 | 同一ユーザーの重複参加防止 |
| created_at > NOW() - 24h | 古すぎるChainは除外 |

- `FindAvailableChain` はトランザクション内で実行し、候補 `LyricChain` を `SELECT ... FOR UPDATE` で取得する
- これにより Chain 選択、必要時の新規作成、`SequenceNum` 計算、`LyricEntry` 作成、`ParticipantCount` 更新、Outbox 追加を Cloud SQL 上でアトミックに確定する

---

## 生成ジョブ処理

### Worker処理フロー

```go
func (w *LyriaWorker) ProcessGenerationJob(ctx context.Context, chainID uuid.UUID) error {
    // 1. Chainと全歌詞を取得
    chain, entries, err := w.chainRepo.GetWithEntries(ctx, chainID)
    if err != nil {
        return err
    }

    // 2. 歌詞を連結
    combinedLyrics := w.combineLyrics(entries)

    // 3. Geminiでムード・ジャンル分析
    analysis, err := w.geminiClient.AnalyzeLyrics(ctx, combinedLyrics)
    if err != nil {
        return w.handleFailure(ctx, chain, err)
    }

    // 4. Lyriaで楽曲生成
    audio, err := w.lyriaClient.GenerateSong(ctx, &LyriaRequest{
        Lyrics:      combinedLyrics,
        Mood:        analysis.Mood,
        Genre:       analysis.Genre,
        Tempo:       analysis.Tempo,
        DurationSec: 45, // 45秒
    })
    if err != nil {
        return w.handleFailure(ctx, chain, err)
    }

    // 5. Cloud Storageにアップロード
    audioURL, err := w.storageClient.Upload(ctx, audio)
    if err != nil {
        return w.handleFailure(ctx, chain, err)
    }

    // 6. GeneratedSongレコード作成
    song := &GeneratedSong{
        ID:          uuid.New(),
        ChainID:     chain.ID,
        Title:       analysis.SuggestedTitle,
        AudioURL:    audioURL,
        DurationSec: 45,
        Mood:        analysis.Mood,
        Genre:       analysis.Genre,
        Status:      SongStatusCompleted,
    }

    // 7. トランザクションで保存 + 通知Outbox追加
    return w.txManager.RunInTx(ctx, func(tx TxContext) error {
        if err := w.songRepo.Create(tx, song); err != nil {
            return err
        }
        chain.Status = ChainStatusCompleted
        chain.CompletedAt = time.Now()
        if err := w.chainRepo.Update(tx, chain); err != nil {
            return err
        }

        // 参加者全員への通知をOutboxに追加
        for _, entry := range entries {
            if err := w.outboxRepo.Enqueue(tx, OutboxTypeSongNotification, &SongNotificationPayload{
                UserID: entry.UserID,
                SongID: song.ID,
            }); err != nil {
                return err
            }
        }
        return nil
    })
}
```

---

## エラーハンドリング

### リトライ戦略

| エラー種別 | 対応 |
|-----------|------|
| Lyria API一時障害 | 最大3回リトライ（指数バックオフ） |
| Lyria API永続障害 | status = 'failed'、参加者に謝罪通知 |
| コンテンツポリシー違反 | 該当歌詞を除外して再生成 or 中止 |
| Storage障害 | リトライ後、失敗時は手動対応 |

### 失敗時の通知

```json
{
  "title": "楽曲生成に失敗しました",
  "body": "申し訳ありません。技術的な問題により楽曲を生成できませんでした。",
  "data": {
    "type": "song_generation_failed",
    "chain_id": "uuid"
  }
}
```

---

## コンテンツモデレーション

### Geminiによる歌詞チェック

歌詞投稿時に Gemini で不適切コンテンツをチェック。

```go
func (uc *LyricUseCase) ValidateContent(ctx context.Context, content string) error {
    result, err := uc.geminiClient.ModerateContent(ctx, content)
    if err != nil {
        return err
    }

    if result.IsHarmful {
        return domain.ErrInappropriateContent
    }

    return nil
}
```

### チェック項目

| カテゴリ | 対応 |
|---------|------|
| ヘイトスピーチ | 投稿拒否 |
| 暴力的表現 | 投稿拒否 |
| 成人向けコンテンツ | 投稿拒否 |
| 著作権侵害の疑い | 警告表示、ユーザー確認 |

---

## 設定値

| 項目 | デフォルト値 | 説明 |
|------|-------------|------|
| CHAIN_THRESHOLD_MIN | 4 | 最小参加者数 |
| CHAIN_THRESHOLD_MAX | 8 | 最大参加者数 |
| CHAIN_EXPIRY_HOURS | 24 | Chainの有効期限 |
| LYRIC_MAX_LENGTH | 100 | 歌詞の最大文字数 |
| SONG_DURATION_SEC | 45 | 生成楽曲の長さ |
| GENERATION_TIMEOUT_MIN | 5 | Lyria生成タイムアウト |

---

## 実装優先度

| 優先度 | タスク |
|--------|--------|
| P0 | LyricChain / LyricEntry エンティティ・リポジトリ |
| P0 | POST /api/v1/lyrics API |
| P0 | Lyria生成ジョブ（Worker） |
| P1 | Geminiムード分析 |
| P1 | コンテンツモデレーション |
| P1 | 生成完了通知 |
| P2 | GET /api/v1/songs/me API |
| P2 | Chain詳細API |
