package auth

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RestController

@RestController
@SpringBootApplication(scanBasePackages = ["auth"])
class AuthenticationServiceApplication {

    @GetMapping("/")
    fun index(): String = "I'm Alive!"

    @GetMapping("/jwt")
    fun jwt(
        @AuthenticationPrincipal jwt: Jwt,
    ): String = jwt.tokenValue

    @GetMapping("/snippets")
    fun getAllMessages(): String = "secret message"

    @GetMapping("/snippets/{id}")
    fun getSingleMessage(
        @PathVariable id: String,
    ): String = "secret message $id"

    @PostMapping("/snippets")
    fun createMessage(
        @RequestBody message: String?,
    ): String = String.format("Message was created. Content: %s", message)
}

fun main(args: Array<String>) {
    runApplication<AuthenticationServiceApplication>(*args)
}
