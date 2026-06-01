package com.example.demopg.repository;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import com.example.demopg.models.TweetReaction;

@Repository
public interface TweetReactionRepository extends JpaRepository<TweetReaction, Long> {
    
    // Busca si un usuario específico ya reaccionó a un tweet específico
    Optional<TweetReaction> findByUserIdAndTweetId(Long userId, Long tweetId);
    
    // Borra la reacción si el usuario decide quitarla
    void deleteByUserIdAndTweetId(Long userId, Long tweetId);
}