package auth.controllers

import auth.dtos.CreateUserRequest
import auth.dtos.UpdateUserRequest
import auth.dtos.UserResponse
import auth.services.Auth0ManagementService
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.Authentication
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/users")
class UserController(
    private val auth0ManagementService: Auth0ManagementService,
) {

    // Crear usuario (CREATE) - Generalmente una acción de admin o M2M,
    // pero la dejamos como en tu original.
    @PostMapping
    fun createUser(
        @RequestBody request: CreateUserRequest,
    ): ResponseEntity<UserResponse> {
        val user = auth0ManagementService.createUser(request)
        return ResponseEntity.status(HttpStatus.CREATED).body(user)
    }

    // OBTENER TODOS (GET /users) - Esto es peligroso.
    // Lo deshabilitamos por defecto.
    @GetMapping
    fun getAllUsers(): ResponseEntity<Any> {
        // Política ABAC: Nadie puede listar todos los usuarios.
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
            .body("La lista de todos los usuarios no está permitida.")
    }

    // OBTENER UNO (GET /users/{userId})
    @GetMapping("/{userId}")
    fun getUser(
        @PathVariable userId: String,
        auth: Authentication
    ): ResponseEntity<UserResponse> {

        // Política ABAC: "Un usuario solo puede ver su propio perfil"
        val jwt = auth.principal as Jwt
        val subjectId = jwt.subject // ID del que hace la petición

        if (subjectId != userId) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }

        val user = auth0ManagementService.getUser(userId)
        return ResponseEntity.ok(user)
    }

    // ACTUALIZAR (PATCH /users/{userId})
    @PatchMapping("/{userId}")
    fun updateUser(
        @PathVariable userId: String,
        @RequestBody request: UpdateUserRequest,
        auth: Authentication
    ): ResponseEntity<UserResponse> {

        // Política ABAC: "Un usuario solo puede actualizar su propio perfil"
        val jwt = auth.principal as Jwt
        val subjectId = jwt.subject

        if (subjectId != userId) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }

        val user = auth0ManagementService.updateUser(userId, request)
        return ResponseEntity.ok(user)
    }

    // BORRAR (DELETE /users/{userId})
    @DeleteMapping("/{userId}")
    fun deleteUser(
        @PathVariable userId: String,
        auth: Authentication
    ): ResponseEntity<Void> {

        // Política ABAC: "Un usuario solo puede borrar su propia cuenta"
        val jwt = auth.principal as Jwt
        val subjectId = jwt.subject

        if (subjectId != userId) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }

        auth0ManagementService.deleteUser(userId)
        return ResponseEntity.noContent().build()
    }
}