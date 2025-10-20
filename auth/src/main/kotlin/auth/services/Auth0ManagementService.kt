package auth.services

import auth.dtos.CreateUserRequest
import auth.dtos.UpdateUserRequest
import auth.dtos.UserResponse
import com.fasterxml.jackson.databind.JsonNode
import com.fasterxml.jackson.databind.ObjectMapper
import org.springframework.beans.factory.annotation.Value
import org.springframework.http.HttpEntity
import org.springframework.http.HttpHeaders
import org.springframework.http.HttpMethod
import org.springframework.http.MediaType
import org.springframework.stereotype.Service
import org.springframework.web.client.RestTemplate

@Service
class Auth0ManagementService(
    @param:Value("\${auth0.domain}") private val domain: String,
    @param:Value("\${auth0.management.client-id}") private val clientId: String,
    @param:Value("\${auth0.management.client-secret}") private val clientSecret: String,
    private val restTemplate: RestTemplate,
    private val objectMapper: ObjectMapper,
) {

    private var accessToken: String? = null
    private var tokenExpiry: Long = 0

    private fun getManagementToken(): String {
        if (accessToken != null && System.currentTimeMillis() < tokenExpiry) {
            return accessToken!!
        }

        val tokenRequest =
            mapOf(
                "grant_type" to "client_credentials",
                "client_id" to clientId,
                "client_secret" to clientSecret,
                "audience" to "https://$domain/api/v2/",
            )

        val headers =
            HttpHeaders().apply {
                contentType = MediaType.APPLICATION_JSON
            }

        val response =
            restTemplate.postForEntity(
                "https://$domain/oauth/token",
                HttpEntity(tokenRequest, headers),
                String::class.java,
            )

        val jsonResponse = objectMapper.readTree(response.body)
        accessToken = jsonResponse.get("access_token").asText()
        val expiresIn = jsonResponse.get("expires_in").asLong()
        tokenExpiry = System.currentTimeMillis() + (expiresIn * 1000)

        return accessToken!!
    }

    private fun createHeaders(): HttpHeaders =
        HttpHeaders().apply {
            contentType = MediaType.APPLICATION_JSON
            setBearerAuth(getManagementToken())
        }

    fun createUser(request: CreateUserRequest): UserResponse {
        val userPayload =
            mapOf(
                "email" to request.email,
                "password" to request.password,
                "name" to request.name,
                "nickname" to (request.nickname ?: request.name),
                "blocked" to request.blocked,
                "connection" to "Username-Password-Authentication",
            )

        val response =
            restTemplate.postForEntity(
                "https://$domain/api/v2/users",
                HttpEntity(userPayload, createHeaders()),
                String::class.java,
            )

        return parseUserResponse(objectMapper.readTree(response.body))
    }

    fun getUser(userId: String): UserResponse {
        val response =
            restTemplate.exchange(
                "https://$domain/api/v2/users/$userId",
                HttpMethod.GET,
                HttpEntity<String>(createHeaders()),
                String::class.java,
            )

        return parseUserResponse(objectMapper.readTree(response.body))
    }

    fun getAllUsers(): List<UserResponse> {
        val response =
            restTemplate.exchange(
                "https://$domain/api/v2/users",
                HttpMethod.GET,
                HttpEntity<String>(createHeaders()),
                String::class.java,
            )

        val users = objectMapper.readTree(response.body)
        return users.map { parseUserResponse(it) }
    }

    fun updateUser(
        userId: String,
        request: UpdateUserRequest,
    ): UserResponse {
        val updatePayload = mutableMapOf<String, Any?>()
        request.email?.let { updatePayload["email"] = it }
        request.name?.let { updatePayload["name"] = it }
        request.nickname?.let { updatePayload["nickname"] = it }
        request.blocked?.let { updatePayload["blocked"] = it }

        val response =
            restTemplate.exchange(
                "https://$domain/api/v2/users/$userId",
                HttpMethod.PATCH,
                HttpEntity(updatePayload, createHeaders()),
                String::class.java,
            )

        return parseUserResponse(objectMapper.readTree(response.body))
    }

    fun deleteUser(userId: String) {
        restTemplate.exchange(
            "https://$domain/api/v2/users/$userId",
            HttpMethod.DELETE,
            HttpEntity<String>(createHeaders()),
            Void::class.java,
        )
    }

    private fun parseUserResponse(node: JsonNode): UserResponse =
        UserResponse(
            userId = node.get("user_id").asText(),
            email = node.get("email").asText(),
            name = node.get("name").asText(),
            nickname = node.get("nickname")?.asText(),
            blocked = node.get("blocked").asBoolean(),
            emailVerified = node.get("email_verified").asBoolean(),
            createdAt = node.get("created_at").asText(),
            updatedAt = node.get("updated_at").asText(),
        )
}
