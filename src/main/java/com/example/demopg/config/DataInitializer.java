package com.example.demopg.config;

import java.util.HashSet;
import java.util.Set;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import com.example.demopg.models.ERole;
import com.example.demopg.models.Role;
import com.example.demopg.models.User;
import com.example.demopg.repository.RoleRepository;
import com.example.demopg.repository.UserRepository;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    UserRepository userRepository;

    @Autowired
    RoleRepository roleRepository;

    @Autowired
    PasswordEncoder encoder;

    @Override
    public void run(String... args) throws Exception {
        
        // 1. Inicializar o recuperar los Roles de la Base de Datos
        Role userRole = roleRepository.findByName(ERole.ROLE_USER)
                .orElseGet(() -> roleRepository.save(new Role(ERole.ROLE_USER)));
                
        Role moderatorRole = roleRepository.findByName(ERole.ROLE_MODERATOR)
                .orElseGet(() -> roleRepository.save(new Role(ERole.ROLE_MODERATOR)));
                
        Role adminRole = roleRepository.findByName(ERole.ROLE_ADMIN)
                .orElseGet(() -> roleRepository.save(new Role(ERole.ROLE_ADMIN)));

        // 2. Forzar actualización o creación de la cuenta de Administrador (ana_reyes)
        User admin = userRepository.findByUsername("ana_reyes").orElse(null);
        if (admin == null) {
            admin = new User("ana_reyes", "ana.reyes@example.com", encoder.encode("password123"));
        } else {
            // Si ya existía de antes, le actualizamos la contraseña para asegurar la correcta
            admin.setPassword(encoder.encode("password123"));
        }
        Set<Role> adminRoles = new HashSet<>();
        adminRoles.add(adminRole);
        admin.setRoles(adminRoles); // Forzamos que sea ROLE_ADMIN obligatoriamente
        userRepository.save(admin);
        System.out.println("--> [OK] ROL_ADMIN asignado con éxito a ana_reyes.");

        // 3. Forzar actualización o creación de la cuenta del Mediador (Carlos_Vidal)
        User moderator = userRepository.findByUsername("Carlos_Vidal").orElse(null);
        if (moderator == null) {
            moderator = new User("Carlos_Vidal", "carlos.vidal@example.com", encoder.encode("AnaTeAmo"));
        } else {
            moderator.setPassword(encoder.encode("AnaTeAmo"));
        }
        Set<Role> modRoles = new HashSet<>();
        modRoles.add(moderatorRole);
        moderator.setRoles(modRoles); // Forzamos que sea ROLE_MODERATOR obligatoriamente
        userRepository.save(moderator);
        System.out.println("--> [OK] ROL_MODERATOR asignado con éxito a Carlos_Vidal.");
    }
}
