package com.example.demopg.controllers;

import java.util.Optional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import com.example.demopg.models.Tweet;
import com.example.demopg.models.TweetComment;
import com.example.demopg.models.TweetReaction;
import com.example.demopg.repository.TweetRepository;
import com.example.demopg.repository.TweetCommentRepository;
import com.example.demopg.repository.TweetReactionRepository;
import com.example.demopg.security.services.UserDetailsImpl;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/tweets")
public class TweetController {

    @Autowired
    private TweetRepository tweetRepository;

    @Autowired
    private TweetCommentRepository tweetCommentRepository;

    @Autowired
    private TweetReactionRepository tweetReactionRepository;

    @GetMapping("")
    public java.util.List<Tweet> getTweet() {
        return tweetRepository.findAll();
    }

    // Solo ADMIN (Ana) o MODERATOR (Carlos) pueden publicar un avistamiento
    @PostMapping("")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MODERATOR')")
    public Tweet createTweet(
        @RequestParam("title") String title,
        @RequestParam("tweet") String tweet,
        @RequestParam("file") org.springframework.web.multipart.MultipartFile file) {

        Tweet myTweet = new Tweet();
        myTweet.setTitle(title);
        myTweet.setTweet(tweet);

        // Inicializar contadores de reacciones en 0 para evitar nulos
        myTweet.setMeGusta(0);
        myTweet.setMeEncanta(0);
        myTweet.setTriste(0);
        myTweet.setRisa(0);

        if (file != null && !file.isEmpty()) {
            try {
                String uploadDir = System.getProperty("user.dir") + "/uploads/";
                java.io.File directory = new java.io.File(uploadDir);
                if (!directory.exists()) {
                    directory.mkdirs();
                }

                String originalFileName = file.getOriginalFilename();
                String uniqueFileName = System.currentTimeMillis() + "_" + originalFileName;
                java.nio.file.Path path = java.nio.file.Paths.get(uploadDir + uniqueFileName);
                
                java.nio.file.Files.write(path, file.getBytes());

                String fileUrl = ServletUriComponentsBuilder.fromCurrentContextPath()
                    .path("/uploads/")
                    .path(uniqueFileName)
                    .toUriString();
                myTweet.setImageUrl(fileUrl);

            } catch (java.io.IOException e) {
                System.out.println("Error al guardar la imagen: " + e.getMessage());
            }
        }

        return tweetRepository.save(myTweet);
    }

    // Solo ADMIN (Ana) o MODERATOR (Carlos) pueden borrar avistamientos de la bitácora
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MODERATOR')")
    public void deleteTweet(@PathVariable Long id) {
        tweetCommentRepository.deleteByTweetId(id);
        tweetRepository.deleteById(id);
    }

    // Lógica avanzada de Reacciones Únicas estilo Facebook para cualquier usuario
    @PostMapping("/{id}/react")
    @Transactional
    public Tweet reactToTweet(@PathVariable Long id, @RequestParam("type") String reactionType) {
        // 1. Validar que el tweet exista
        Tweet tweet = tweetRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Error: Publicación no encontrada."));

        // 2. Obtener de forma segura el ID del usuario logueado mediante el Token JWT
        UserDetailsImpl userDetails = (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        Long userId = userDetails.getId();

        // 3. Buscar si este usuario ya había reaccionado antes a este tweet en específico
        Optional<TweetReaction> existingReaction = tweetReactionRepository.findByUserIdAndTweetId(userId, id);

        if (existingReaction.isPresent()) {
            TweetReaction oldReaction = existingReaction.get();

            if (oldReaction.getReactionType().equalsIgnoreCase(reactionType)) {
                // CASO A: Es el mismo emoji -> Se remueve la reacción por completo (segundo clic)
                decreaseReactionCount(tweet, reactionType);
                tweetReactionRepository.delete(oldReaction);
            } else {
                // CASO B: Es un emoji diferente -> Restamos el viejo y sumamos el nuevo
                decreaseReactionCount(tweet, oldReaction.getReactionType());
                oldReaction.setReactionType(reactionType.toUpperCase());
                tweetReactionRepository.save(oldReaction);
                increaseReactionCount(tweet, reactionType);
            }
        } else {
            // CASO C: No había reaccionado antes -> Se crea un nuevo registro único y se suma
            TweetReaction newReaction = new TweetReaction(userId, id, reactionType.toUpperCase());
            tweetReactionRepository.save(newReaction);
            increaseReactionCount(tweet, reactionType);
        }

        // 4. Guardamos los contadores modificados en el Tweet y lo devolvemos actualizado a Flutter
        return tweetRepository.save(tweet);
    }

    // Métodos auxiliares internos para manipular los contadores de forma limpia
    private void increaseReactionCount(Tweet tweet, String type) {
        switch (type.toUpperCase()) {
            case "LIKE" -> tweet.setMeGusta(tweet.getMeGusta() + 1);
            case "LOVE" -> tweet.setMeEncanta(tweet.getMeEncanta() + 1);
            case "SAD"  -> tweet.setTriste(tweet.getTriste() + 1);
            case "LAUGH"-> tweet.setRisa(tweet.getRisa() + 1);
        }
    }

    private void decreaseReactionCount(Tweet tweet, String type) {
        switch (type.toUpperCase()) {
            case "LIKE" -> tweet.setMeGusta(Math.max(0, tweet.getMeGusta() - 1));
            case "LOVE" -> tweet.setMeEncanta(Math.max(0, tweet.getMeEncanta() - 1));
            case "SAD"  -> tweet.setTriste(Math.max(0, tweet.getTriste() - 1));
            case "LAUGH"-> tweet.setRisa(Math.max(0, tweet.getRisa() - 1));
        }
    }

    @GetMapping("/{id}/comments")
    public java.util.List<TweetComment> getComments(@PathVariable Long id) {
        return tweetCommentRepository.findByTweetIdOrderByCreatedAtAsc(id);
    }

    @PostMapping("/{id}/comments")
    @Transactional
    public TweetComment addComment(
            @PathVariable Long id,
            @RequestParam("content") String content) {

        Tweet tweet = tweetRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Error: Publicación no encontrada."));

        UserDetailsImpl userDetails = (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

        TweetComment comment = new TweetComment();
        comment.setTweetId(tweet.getId());
        comment.setUserId(userDetails.getId());
        comment.setUsername(userDetails.getUsername());
        comment.setContent(content.trim());

        return tweetCommentRepository.save(comment);
    }
}
