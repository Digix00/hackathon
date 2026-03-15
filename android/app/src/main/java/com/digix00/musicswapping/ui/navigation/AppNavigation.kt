package com.digix00.musicswapping.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.digix00.musicswapping.ui.auth.AuthScreen
import com.digix00.musicswapping.ui.auth.AuthViewModel
import com.digix00.musicswapping.ui.encounter.EncounterDetailScreen
import com.digix00.musicswapping.ui.home.HomeScreen
import com.digix00.musicswapping.ui.home.HomeViewModel
import com.digix00.musicswapping.ui.onboarding.OnboardingScreen
import com.digix00.musicswapping.ui.profile.ProfileScreen
import com.digix00.musicswapping.ui.search.SearchScreen
import com.digix00.musicswapping.ui.settings.SettingsScreen

@Composable
fun AppNavigation() {
    val navController = rememberNavController()
    val authViewModel: AuthViewModel = hiltViewModel()
    val isLoggedIn by authViewModel.isLoggedIn.collectAsStateWithLifecycle()

    val startDestination = if (isLoggedIn) Screen.Home.route else Screen.Auth.route

    NavHost(navController = navController, startDestination = startDestination) {
        composable(Screen.Auth.route) {
            AuthScreen(
                onLoginSuccess = {
                    navController.navigate(Screen.Onboarding.route) {
                        popUpTo(Screen.Auth.route) { inclusive = true }
                    }
                }
            )
        }
        composable(Screen.Onboarding.route) {
            OnboardingScreen(
                onComplete = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Onboarding.route) { inclusive = true }
                    }
                }
            )
        }
        composable(Screen.Home.route) {
            val vm: HomeViewModel = hiltViewModel()
            HomeScreen(
                viewModel = vm,
                onEncounterClick = { id -> navController.navigate(Screen.EncounterDetail.createRoute(id)) },
                onSettingsClick = { navController.navigate(Screen.Settings.route) },
                onChangeSongClick = { navController.navigate(Screen.Search.route) }
            )
        }
        composable(Screen.EncounterDetail.route) { backStack ->
            val encounterId = backStack.arguments?.getString("encounterId") ?: return@composable
            EncounterDetailScreen(
                encounterId = encounterId,
                onBack = { navController.popBackStack() }
            )
        }
        composable(Screen.Search.route) {
            SearchScreen(onBack = { navController.popBackStack() })
        }
        composable(Screen.Profile.route) {
            ProfileScreen(onBack = { navController.popBackStack() })
        }
        composable(Screen.Settings.route) {
            SettingsScreen(
                onBack = { navController.popBackStack() },
                onLogout = {
                    navController.navigate(Screen.Auth.route) {
                        popUpTo(0) { inclusive = true }
                    }
                },
                onEditProfile = { navController.navigate(Screen.Profile.route) },
                onChangeSong = { navController.navigate(Screen.Search.route) }
            )
        }
    }
}
