//go:build integration

package rdb

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"hackathon/internal/domain/repository"
	"hackathon/internal/infra/rdb/model"
)

func setupLyriaTestData(t *testing.T) (chainID string, jobID string) {
	t.Helper()
	db := sharedTestDB

	// ユーザー4人
	users := []model.User{
		{ID: "lu-a", AuthProvider: "firebase", ProviderUserID: "luid-a"},
		{ID: "lu-b", AuthProvider: "firebase", ProviderUserID: "luid-b"},
		{ID: "lu-c", AuthProvider: "firebase", ProviderUserID: "luid-c"},
		{ID: "lu-d", AuthProvider: "firebase", ProviderUserID: "luid-d"},
	}
	for _, u := range users {
		db.Where("id = ?", u.ID).FirstOrCreate(&u)
	}

	// エンカウント
	enc := model.Encounter{
		ID:            uuid.NewString(),
		UserID1:       "lu-a",
		UserID2:       "lu-b",
		EncounteredAt: time.Now().UTC(),
		EncounterType: "ble",
	}
	if err := db.Create(&enc).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	chainID = uuid.NewString()
	jobID = uuid.NewString()

	// 歌詞チェーン
	chain := model.LyricChain{
		ID:               chainID,
		Status:           "generating",
		ParticipantCount: 4,
		Threshold:        4,
	}
	if err := db.Create(&chain).Error; err != nil {
		t.Fatalf("create chain: %v", err)
	}

	// 歌詞エントリ
	entries := []model.LyricEntry{
		{ID: uuid.NewString(), ChainID: chainID, UserID: "lu-a", EncounterID: enc.ID, Content: "夕焼けの空", SequenceNum: 1},
		{ID: uuid.NewString(), ChainID: chainID, UserID: "lu-b", EncounterID: enc.ID, Content: "言葉にできない", SequenceNum: 2},
		{ID: uuid.NewString(), ChainID: chainID, UserID: "lu-c", EncounterID: enc.ID, Content: "忘れられない", SequenceNum: 3},
		{ID: uuid.NewString(), ChainID: chainID, UserID: "lu-d", EncounterID: enc.ID, Content: "また会う日まで", SequenceNum: 4},
	}
	for _, e := range entries {
		if err := db.Create(&e).Error; err != nil {
			t.Fatalf("create entry: %v", err)
		}
	}

	// OutboxLyriaJob (pending)
	job := model.OutboxLyriaJob{
		ID:      jobID,
		ChainID: chainID,
		Status:  "pending",
	}
	if err := db.Create(&job).Error; err != nil {
		t.Fatalf("create job: %v", err)
	}

	t.Cleanup(func() {
		db.Where("chain_id = ?", chainID).Delete(&model.OutboxLyriaJob{})
		db.Where("chain_id = ?", chainID).Delete(&model.GeneratedSong{})
		db.Where("chain_id = ?", chainID).Delete(&model.LyricEntry{})
		db.Delete(&model.LyricChain{}, "id = ?", chainID)
		db.Delete(&model.Encounter{}, "id = ?", enc.ID)
		for _, u := range users {
			db.Delete(&model.User{}, "id = ?", u.ID)
		}
	})

	return chainID, jobID
}

func TestLyriaJobRepository_ClaimPendingJobs(t *testing.T) {
	if sharedTestDB == nil {
		t.Skip("postgres not available")
	}

	chainID, jobID := setupLyriaTestData(t)
	repo := NewLyriaJobRepository(sharedTestDB)

	jobs, err := repo.ClaimPendingJobs(context.Background(), 5)
	if err != nil {
		t.Fatalf("ClaimPendingJobs: %v", err)
	}
	if len(jobs) == 0 {
		t.Fatal("expected at least 1 job, got 0")
	}

	var found *repository.OutboxLyriaJobDetail
	for i := range jobs {
		if jobs[i].JobID == jobID {
			found = &jobs[i]
			break
		}
	}
	if found == nil {
		t.Fatalf("expected job %s in results, got %v", jobID, jobs)
	}
	if found.ChainID != chainID {
		t.Errorf("expected chainID=%s, got %s", chainID, found.ChainID)
	}
	if len(found.Lyrics) != 4 {
		t.Errorf("expected 4 lyrics, got %d: %v", len(found.Lyrics), found.Lyrics)
	}
	if found.Lyrics[0] != "夕焼けの空" {
		t.Errorf("expected first lyric '夕焼けの空', got %q", found.Lyrics[0])
	}

	// ステータスが processing になっていること
	var job model.OutboxLyriaJob
	sharedTestDB.First(&job, "id = ?", jobID)
	if job.Status != "processing" {
		t.Errorf("expected status=processing, got %s", job.Status)
	}
}

func TestLyriaJobRepository_CompleteJob(t *testing.T) {
	if sharedTestDB == nil {
		t.Skip("postgres not available")
	}

	chainID, jobID := setupLyriaTestData(t)
	repo := NewLyriaJobRepository(sharedTestDB)

	// まず claim して processing にする
	_, err := repo.ClaimPendingJobs(context.Background(), 5)
	if err != nil {
		t.Fatalf("ClaimPendingJobs: %v", err)
	}

	songInput := repository.SaveSongInput{
		ID:          uuid.NewString(),
		Title:       "テスト楽曲",
		AudioURL:    "https://storage.googleapis.com/bucket/songs/" + chainID + "/original.wav",
		DurationSec: 45,
		Mood:        "upbeat",
		Genre:       "j-pop",
	}

	if err := repo.CompleteJob(context.Background(), jobID, chainID, songInput); err != nil {
		t.Fatalf("CompleteJob: %v", err)
	}

	// OutboxLyriaJob が completed になっていること
	var job model.OutboxLyriaJob
	sharedTestDB.First(&job, "id = ?", jobID)
	if job.Status != "completed" {
		t.Errorf("job status: expected completed, got %s", job.Status)
	}
	if job.ProcessedAt == nil {
		t.Error("job processed_at should be set")
	}

	// LyricChain が completed になっていること
	var chain model.LyricChain
	sharedTestDB.First(&chain, "id = ?", chainID)
	if chain.Status != "completed" {
		t.Errorf("chain status: expected completed, got %s", chain.Status)
	}
	if chain.CompletedAt == nil {
		t.Error("chain completed_at should be set")
	}

	// GeneratedSong が作成されていること
	var song model.GeneratedSong
	sharedTestDB.First(&song, "chain_id = ?", chainID)
	if song.ID == "" {
		t.Fatal("generated_song not created")
	}
	if song.Title == nil || *song.Title != "テスト楽曲" {
		t.Errorf("song title: expected 'テスト楽曲', got %v", song.Title)
	}
	if song.Mood == nil || *song.Mood != "upbeat" {
		t.Errorf("song mood: expected 'upbeat', got %v", song.Mood)
	}
	if song.Status != "completed" {
		t.Errorf("song status: expected completed, got %s", song.Status)
	}
}

func TestLyriaJobRepository_FailJob_Retry(t *testing.T) {
	if sharedTestDB == nil {
		t.Skip("postgres not available")
	}

	_, jobID := setupLyriaTestData(t)
	repo := NewLyriaJobRepository(sharedTestDB)

	// claim
	if _, err := repo.ClaimPendingJobs(context.Background(), 5); err != nil {
		t.Fatalf("ClaimPendingJobs: %v", err)
	}

	// 1回失敗 → pending に戻るはず
	if err := repo.FailJob(context.Background(), jobID, "test error", false); err != nil {
		t.Fatalf("FailJob: %v", err)
	}

	var job model.OutboxLyriaJob
	sharedTestDB.First(&job, "id = ?", jobID)
	if job.Status != "pending" {
		t.Errorf("after 1st fail: expected pending, got %s", job.Status)
	}
	if job.RetryCount != 1 {
		t.Errorf("retry_count: expected 1, got %d", job.RetryCount)
	}
	if job.ErrorMessage == nil || *job.ErrorMessage != "test error" {
		t.Errorf("error_message not set correctly: %v", job.ErrorMessage)
	}
}

func TestLyriaJobRepository_FailJob_MaxRetry(t *testing.T) {
	if sharedTestDB == nil {
		t.Skip("postgres not available")
	}

	_, jobID := setupLyriaTestData(t)
	repo := NewLyriaJobRepository(sharedTestDB)

	// retry_count を maxRetryCount-1 に設定してから失敗させる
	sharedTestDB.Model(&model.OutboxLyriaJob{}).Where("id = ?", jobID).
		Updates(map[string]any{"retry_count": maxRetryCount - 1, "status": "processing"})

	if err := repo.FailJob(context.Background(), jobID, "final error", false); err != nil {
		t.Fatalf("FailJob: %v", err)
	}

	var job model.OutboxLyriaJob
	sharedTestDB.First(&job, "id = ?", jobID)
	if job.Status != "failed" {
		t.Errorf("after max retry: expected failed, got %s", job.Status)
	}

	// LyricChain も failed に更新されているはず
	var chain model.LyricChain
	sharedTestDB.First(&chain, "id = ?", job.ChainID)
	if chain.Status != "failed" {
		t.Errorf("chain status after max retry: expected failed, got %s", chain.Status)
	}
}

func TestLyriaJobRepository_FailJob_Permanent(t *testing.T) {
	if sharedTestDB == nil {
		t.Skip("postgres not available")
	}

	chainID, jobID := setupLyriaTestData(t)
	repo := NewLyriaJobRepository(sharedTestDB)

	// claim して processing にする
	if _, err := repo.ClaimPendingJobs(context.Background(), 5); err != nil {
		t.Fatalf("ClaimPendingJobs: %v", err)
	}

	// permanent=true で即座に failed になるはず (リトライ回数に関係なく)
	if err := repo.FailJob(context.Background(), jobID, "harmful content", true); err != nil {
		t.Fatalf("FailJob permanent: %v", err)
	}

	var job model.OutboxLyriaJob
	sharedTestDB.First(&job, "id = ?", jobID)
	if job.Status != "failed" {
		t.Errorf("permanent fail: expected failed, got %s", job.Status)
	}

	// LyricChain も failed に更新されているはず
	var chain model.LyricChain
	sharedTestDB.First(&chain, "id = ?", chainID)
	if chain.Status != "failed" {
		t.Errorf("chain status on permanent fail: expected failed, got %s", chain.Status)
	}
}
