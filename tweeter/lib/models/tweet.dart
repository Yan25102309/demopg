  class Tweet {
    final int id;
    final String title;       // Título real ingresado por el usuario
    final String tweet;       // Descripción real
    final String? imageUrl;   // URL de la imagen del servidor
    
    // Contadores dinámicos que se manejarán en la interfaz
    int meGusta;
    int meEncanta;
    int triste;
    int risa;

    Tweet({
      required this.id, 
      required this.title, 
      required this.tweet, 
      this.imageUrl,
      this.meGusta = 0,
      this.meEncanta = 0,
      this.triste = 0,
      this.risa = 0,
    });

    factory Tweet.fromJson(Map<String, dynamic> json) {
      return Tweet(
        id: json['id'] as int,
        // Si tu backend aún no guarda el título separado, usamos un valor por defecto o dividimos el texto
        title: json['title'] as String? ?? "Criatura Marina",
        tweet: json['tweet'] as String? ?? "",
        imageUrl: json['imageUrl'] as String?,
        meGusta: json['meGusta'] as int? ?? 0,
        meEncanta: json['meEncanta'] as int? ?? 0,
        triste: json['triste'] as int? ?? 0,
        risa: json['risa'] as int? ?? 0,
      );
    }
  }
