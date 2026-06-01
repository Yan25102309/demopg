package com.example.demopg.repository;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demopg.models.ERole;
import com.example.demopg.models.Role;

@Repository
public interface RoleRepository extends JpaRepository<Role, Integer> {
    // Método especializado para buscar un rol por su nombre del enum
    Optional<Role> findByName(ERole name);
}
