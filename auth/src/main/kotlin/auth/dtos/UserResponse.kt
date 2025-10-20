package auth.dtos

data class UserResponse(
    val userId: String,
    val email: String,
    val name: String,
    val nickname: String?,
    val blocked: Boolean,
    val emailVerified: Boolean,
    val createdAt: String,
    val updatedAt: String,
)
