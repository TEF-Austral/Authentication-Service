package auth.controllers

import auth.dtos.CreateUserRequest
import auth.dtos.UpdateUserRequest
import auth.dtos.UserResponse
import auth.services.Auth0ManagementService
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/users")
class UserController(
    private val auth0ManagementService: Auth0ManagementService,
) {

    @PostMapping
    fun createUser(
        @RequestBody request: CreateUserRequest,
    ): ResponseEntity<UserResponse> {
        val user = auth0ManagementService.createUser(request)
        return ResponseEntity.status(HttpStatus.CREATED).body(user)
    }

    @GetMapping
    fun getAllUsers(): ResponseEntity<List<UserResponse>> {
        val users = auth0ManagementService.getAllUsers()
        return ResponseEntity.ok(users)
    }

    @GetMapping("/{userId}")
    fun getUser(
        @PathVariable userId: String,
    ): ResponseEntity<UserResponse> {
        val user = auth0ManagementService.getUser(userId)
        return ResponseEntity.ok(user)
    }

    @PatchMapping("/{userId}")
    fun updateUser(
        @PathVariable userId: String,
        @RequestBody request: UpdateUserRequest,
    ): ResponseEntity<UserResponse> {
        val user = auth0ManagementService.updateUser(userId, request)
        return ResponseEntity.ok(user)
    }

    @DeleteMapping("/{userId}")
    fun deleteUser(
        @PathVariable userId: String,
    ): ResponseEntity<Void> {
        auth0ManagementService.deleteUser(userId)
        return ResponseEntity.noContent().build()
    }
}
