package com.example.demopg.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demopg.models.Tweet;

@Repository
public interface TweetRepository extends JpaRepository<Tweet, Long> {

}