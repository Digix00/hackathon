package com.digix00.musicswapping.data.remote

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.ktx.auth
import com.google.firebase.ktx.Firebase

object FirebaseAuthTokenCache {
    @Volatile
    private var token: String? = null

    @Volatile
    private var started = false

    private val idTokenListener = FirebaseAuth.IdTokenListener { auth ->
        val user = auth.currentUser
        if (user == null) {
            token = null
            return@IdTokenListener
        }
        user.getIdToken(false)
            .addOnSuccessListener { result -> token = result.token }
            .addOnFailureListener { token = null }
    }

    @Synchronized
    fun start() {
        if (started) return
        started = true
        Firebase.auth.addIdTokenListener(idTokenListener)
        idTokenListener.onIdTokenChanged(Firebase.auth)
    }

    fun currentToken(): String? = token
}
