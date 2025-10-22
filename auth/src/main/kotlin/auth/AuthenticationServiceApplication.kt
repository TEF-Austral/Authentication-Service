package auth

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@SpringBootApplication
class AuthenticationServiceApplication {

    @GetMapping("/")
    fun index(): String = "I'm Alive!"

    @GetMapping("/jwt")
    fun jwt(
        @AuthenticationPrincipal jwt: Jwt,
    ): String = jwt.tokenValue
}

fun main(args: Array<String>) {
    runApplication<AuthenticationServiceApplication>(*args)
}