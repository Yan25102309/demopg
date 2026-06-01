package com.example.demopg.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demopg.models.TweetComment;

@Repository
public interface TweetCommentRepository extends JpaRepository<TweetComment, Long> {
    List<TweetComment> findByTweetIdOrderByCreatedAtAsc(Long tweetId);

    void deleteByTweetId(Long tweetId);
}