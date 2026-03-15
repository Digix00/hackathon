package com.digix00.musicswapping.ui.encounter

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil3.compose.AsyncImage

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EncounterDetailScreen(encounterId: String, onBack: () -> Unit, viewModel: EncounterDetailViewModel = hiltViewModel()) {
    val encounter by viewModel.encounter.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("すれ違い詳細") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "戻る")
                    }
                }
            )
        }
    ) { padding ->
        if (encounter == null) {
            CircularProgressIndicator(modifier = Modifier.padding(padding))
            return@Scaffold
        }
        val enc = encounter!!

        Column(
            modifier = Modifier.fillMaxSize().padding(padding).padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            AsyncImage(
                model = enc.sharedTrack.albumArtUrl,
                contentDescription = enc.sharedTrack.title,
                modifier = Modifier.size(120.dp)
            )
            Spacer(Modifier.height(16.dp))
            Text(enc.sharedTrack.title, style = MaterialTheme.typography.titleLarge)
            Text(enc.sharedTrack.artist, style = MaterialTheme.typography.bodyLarge)
            Spacer(Modifier.height(24.dp))
            Row(
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                FilledTonalButton(onClick = { /* TODO: Spotify Open */ }, modifier = Modifier.weight(1f)) {
                    Text("▶ 再生")
                }
                FilledTonalButton(onClick = { viewModel.toggleLike(enc.id) }, modifier = Modifier.weight(1f)) {
                    Icon(
                        if (enc.isLiked) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                        contentDescription = "いいね"
                    )
                    Text(if (enc.isLiked) "いいね済み" else "いいね")
                }
            }
            Spacer(Modifier.height(24.dp))
            Text(
                "👤 ${enc.partnerUser.nickname}さん",
                style = MaterialTheme.typography.bodyLarge
            )
        }
    }
}
