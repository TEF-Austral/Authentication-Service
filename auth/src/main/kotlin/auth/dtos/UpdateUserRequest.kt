package auth.dtos

data class UpdateUserRequest(
    val email: String? = null,
    val name: String? = null,
    val nickname: String? = null,
    val blocked: Boolean? = null,
)
