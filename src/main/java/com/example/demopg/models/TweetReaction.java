package com.example.demopg.models;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;

@Entity
@Table(name = "tweet_reactions", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"user_id", "tweet_id"})
})
public class TweetReaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "tweet_id", nullable = false)
    private Long tweetId;

    @NotBlank
    private String reactionType; // "LIKE", "LOVE", "SAD", "LAUGH"

    public TweetReaction() {}

    public TweetReaction(Long userId, Long tweetId, String reactionType) {
        this.userId = userId;
        this.tweetId = tweetId;
        this.reactionType = reactionType;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public Long getTweetId() {
        return tweetId;
    }

    public void setTweetId(Long tweetId) {
        this.tweetId = tweetId;
    }

    public String getReactionType() {
        return reactionType;
    }

    public void setReactionType(String reactionType) {
        this.reactionType = reactionType;
    }
}
