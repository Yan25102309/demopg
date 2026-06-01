package com.example.demopg.models;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Entity
@Table(name = "tweets")
public class Tweet {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    @Size(max = 140)
    private String tweet; // Actúa como la descripción del avistamiento

    private String title; // Título de la criatura marina

    @Column(length = 500) // Mayor longitud por si la URL del servidor es larga
    private String imageUrl;

    // Nuevas columnas para los contadores de reacciones estilo Facebook
    private int meGusta = 0;
    private int meEncanta = 0;
    private int triste = 0;
    private int risa = 0;

    // Constructor vacío obligatorio para JPA
    public Tweet() {}

    // Constructor original para no romper código existente
    public Tweet(String tweet) {
        this.tweet = tweet;
    }

    // Nuevo constructor con todos los parámetros útiles
    public Tweet(String title, String tweet, String imageUrl) {
        this.title = title;
        this.tweet = tweet;
        this.imageUrl = imageUrl;
    }

    // Getters y Setters existentes y nuevos
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTweet() {
        return tweet;
    }

    public void setTweet(String tweet) {
        this.tweet = tweet;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public int getMeGusta() {
        return meGusta;
    }

    public void setMeGusta(int meGusta) {
        this.meGusta = meGusta;
    }

    public int getMeEncanta() {
        return meEncanta;
    }

    public void setMeEncanta(int meEncanta) {
        this.meEncanta = meEncanta;
    }

    public int getTriste() {
        return triste;
    }

    public void setTriste(int triste) {
        this.triste = triste;
    }

    public int getRisa() {
        return risa;
    }

    public void setRisa(int risa) {
        this.risa = risa;
    }
}