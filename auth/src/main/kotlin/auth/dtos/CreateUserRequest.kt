package auth.dtos

data class CreateUserRequest(
    val email: String,
    val password: String,
    val name: String,
    val nickname: String? = null,
    val blocked: Boolean = false,
)
