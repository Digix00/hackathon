package com.digix00.musicswapping.ui.navigation

sealed class Screen(val route: String) {
    data object Splash : Screen("splash")
    data object Auth : Screen("auth")
    data object Onboarding : Screen("onboarding")
    data object Home : Screen("home")
    data object EncounterDetail : Screen("encounter/{encounterId}") {
        fun createRoute(id: String) = "encounter/$id"
    }
    data object Search : Screen("search")
    data object Profile : Screen("profile")
    data object Settings : Screen("settings")
}
