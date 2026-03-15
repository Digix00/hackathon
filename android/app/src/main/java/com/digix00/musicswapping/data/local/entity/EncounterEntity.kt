package com.digix00.musicswapping.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey

/** BLE 経由で検出したすれ違いレコードをオフライン保持するテーブル */
@Entity(tableName = "encounters")
data class EncounterEntity(
    @PrimaryKey val id: String,
    @ColumnInfo(name = "partner_user_id") val partnerUserId: String,
    @ColumnInfo(name = "partner_nickname") val partnerNickname: String,
    @ColumnInfo(name = "track_title") val trackTitle: String,
    @ColumnInfo(name = "track_artist") val trackArtist: String,
    @ColumnInfo(name = "album_art_url") val albumArtUrl: String?,
    @ColumnInfo(name = "encountered_at_ms") val encounteredAtMs: Long,
    @ColumnInfo(name = "is_liked") val isLiked: Boolean = false,
    /** サーバー送信済みかどうか（オフライン → 復帰時に再送） */
    @ColumnInfo(name = "synced") val synced: Boolean = false
)
