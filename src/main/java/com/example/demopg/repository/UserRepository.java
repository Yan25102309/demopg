package com.example.demopg.repository;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demopg.models.User;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    // Para buscar al usuario por su username al iniciar sesión
    Optional<User> findByUsername(String username);

    // Para verificar si el nombre de usuario ya está tomado al registrarse
    Boolean existsByUsername(String username);

    // Para verificar si el correo electrónico ya está registrado
    Boolean existsByEmail(String email);
}
