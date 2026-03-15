package com.digix00.musicswapping.data.repository

import com.digix00.musicswapping.data.remote.ApiService
import com.digix00.musicswapping.data.remote.dto.UserDto
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

class UserRepositoryImplTest {

    private lateinit var api: ApiService
    private lateinit var repository: UserRepositoryImpl

    @Before
    fun setUp() {
        api = mockk()
        repository = UserRepositoryImpl(api)
    }

    @Test
    fun `getMe maps response to domain User`() = runTest {
        // Given
        coEvery { api.getMe() } returns UserDto.Response(
            id = "id1",
            firebaseUid = "uid1",
            nickname = "TestUser",
            avatarUrl = null
        )

        // When
        val user = repository.getMe()

        // Then
        assertEquals("id1", user.id)
        assertEquals("TestUser", user.nickname)
    }

    @Test
    fun `createUser sends correct request and maps response`() = runTest {
        // Given
        val request = UserDto.CreateRequest(nickname = "Alice")
        coEvery { api.createUser(request) } returns UserDto.Response(
            id = "new1",
            firebaseUid = "fuid1",
            nickname = "Alice"
        )

        // When
        val user = repository.createUser("Alice", null)

        // Then
        assertEquals("new1", user.id)
        assertEquals("Alice", user.nickname)
    }
}
