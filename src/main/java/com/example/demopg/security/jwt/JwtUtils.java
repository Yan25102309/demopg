package com.example.demopg.security.jwt;

import java.security.Key;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;
    
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Component;

import com.example.demopg.security.services.UserDetailsImpl;
import io.jsonwebtoken.*;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;

@Component
public class JwtUtils {
    private static final Logger logger = LoggerFactory.getLogger(JwtUtils.class);

    @Value("${demopg.app.jwtSecret}")
    private String jwtSecret;

    @Value("${demopg.app.jwtExpirationMs}")
    private long jwtExpirationMs;

    // Generar el token JWT para el usuario que inicia sesión
    public String generateJwtToken(Authentication authentication) {
        UserDetailsImpl userPrincipal = (UserDetailsImpl) authentication.getPrincipal();

        // 🔥 EXTRAER LOS ROLES DEL USUARIO AUTENTICADO
        List<String> roles = userPrincipal.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.toList());

        return Jwts.builder()
                .setSubject((userPrincipal.getUsername()))
                .claim("roles", roles) // 👈 INYECTAMOS LOS ROLES DENTRO DEL TOKEN
                .setIssuedAt(new Date())
                .setExpiration(new Date((new Date()).getTime() + jwtExpirationMs)) // Tus 20 años configurados
                .signWith(key(), SignatureAlgorithm.HS256)
                .compact();
    }
  
    private Key key() {
        return Keys.hmacShaKeyFor(Decoders.BASE64.decode(jwtSecret));
    }

    // Obtener el nombre de usuario desde el token JWT
    public String getUserNameFromJwtToken(String token) {
        return Jwts.parserBuilder().setSigningKey(key()).build()
               .parseClaimsJws(token).getBody().getSubject();
    }

    // Validar si el token es auténtico y no está alterado
    // Validar si el token es auténtico y no está alterado
    public boolean validateJwtToken(String authToken) {
        try {
            // 🔥 CAMBIAMOS .parse() POR .parseClaimsJws() PARA QUE LEA LOS CLAIMS ASOCIADOS A LOS ROLES
            Jwts.parserBuilder().setSigningKey(key()).build().parseClaimsJws(authToken);
            return true;
        } catch (MalformedJwtException e) {
            logger.error("Token JWT inválido: {}", e.getMessage());
        } catch (ExpiredJwtException e) {
            logger.error("El token JWT ha expirado: {}", e.getMessage());
        } catch (UnsupportedJwtException e) {
            logger.error("Token JWT no soportado: {}", e.getMessage());
        } catch (IllegalArgumentException e) {
            logger.error("La cadena claims de JWT está vacía: {}", e.getMessage());
        }
        return false;
    }
}
