import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'services/tweet_service.dart';
import 'models/tweet.dart';
import 'models/tweet_comment.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OceanXplorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B7285)),
        scaffoldBackgroundColor: const Color(0xFFE8F7FB),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MyHomePage(title: 'OceanXplorer'),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late TweetService _tweetService;
  late Future<List<Tweet>> _tweetsFuture;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String _currentRole = 'ROLE_USER'; 

  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _tweetService = TweetService();
    _loadTweetsAndRole(); 
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tweetService.dispose();
    super.dispose();
  }

  void _loadTweetsAndRole() async {
    setState(() {
      _tweetsFuture = _tweetService.fetchTweets();
    });
    try {
      final role = await _authService.getUserRole();
      setState(() {
        _currentRole = role;
      });
    } catch (e) {
      print("Error recuperando rol: $e");
    }
  }

  void _loadTweets() {
    setState(() {
      _tweetsFuture = _tweetService.fetchTweets();
    });
  }

  Future<void> _pickImage(StateSetter setModalState) async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.first.bytes != null) {
      setModalState(() {
        _selectedFileBytes = result.files.first.bytes;
        _selectedFileName = result.files.first.name;
      });
    }
  }

  Future<void> _createPost(BuildContext modalContext) async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      _showErrorDialog('Por favor, ingresa un título y una descripción.');
      return;
    }
    if (_selectedFileBytes == null) {
      _showErrorDialog('Es obligatorio adjuntar una foto de la criatura.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _tweetService.createTweetWithImage(
          title, description, _selectedFileName!, _selectedFileBytes!);

      _titleController.clear();
      _descriptionController.clear();
      _selectedFileBytes = null;
      _selectedFileName = null;

      if (mounted) Navigator.pop(modalContext);
      _loadTweets();
    } catch (e) {
      _showErrorDialog('Error al publicar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTweet(int id) async {
    try {
      await _tweetService.deleteTweet(id);
      _loadTweets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avistamiento eliminado con éxito')),
        );
      }
    } catch (e) {
      _showErrorDialog(
          'No tienes permisos de Administrador o Mediador para borrar publicaciones.');
    }
  }

  Future<void> _handleReaction(Tweet post, String type) async {
    try {
      Tweet updatedTweet = await _tweetService.reactToTweet(post.id, type);
      setState(() {
        post.meGusta = updatedTweet.meGusta;
        post.meEncanta = updatedTweet.meEncanta;
        post.triste = updatedTweet.triste;
        post.risa = updatedTweet.risa;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al reaccionar: $e')),
      );
    }
  }

  Widget _buildRoleBadge() {
    String label = 'Explorador';
    Color badgeColor = const Color(0xFF00838F); 

    if (_currentRole == 'ROLE_ADMIN') {
      label = 'Admin';
      badgeColor = const Color(0xFFD32F2F); 
    } else if (_currentRole == 'ROLE_MODERATOR') {
      label = 'Moderador';
      badgeColor = const Color(0xFF2E7D32); 
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Future<void> _openCommentsSheet(Tweet post) async {
    final TextEditingController commentController = TextEditingController();
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<List<TweetComment>> commentsFuture =
                _tweetService.fetchComments(post.id);

            Future<void> submitComment() async {
              final content = commentController.text.trim();
              if (content.isEmpty) return;

              setSheetState(() => isSending = true);
              try {
                await _tweetService.addComment(post.id, content);
                commentController.clear();
                setSheetState(() {});
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al comentar: $e')),
                  );
                }
              } finally {
                if (mounted) setSheetState(() => isSending = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 18,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.waves, color: Color(0xFF0B7285)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: const TextStyle(fontSize: 16, color: Colors.black),
                              children: [
                                const TextSpan(text: 'Comentarios de '),
                                TextSpan(
                                  text: post.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0B7285)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD5EEF2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.anchor, size: 16, color: Color(0xFF0B7285)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Bitácora original: "${post.tweet}"',
                              style: TextStyle(color: Colors.blueGrey[800], fontSize: 13, fontStyle: FontStyle.italic),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: FutureBuilder<List<TweetComment>>(
                        future: commentsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          }

                          final comments = snapshot.data ?? [];
                          if (comments.isEmpty) {
                            return Center(
                              child: Text(
                                'Aún no hay comentarios. Sé el primero en dejar una huella marina.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.blueGrey[500]),
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: comments.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                  border: Border.all(
                                      color: const Color(0xFFE6F4F6)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 13,
                                          backgroundColor: const Color(0xFF0B7285).withOpacity(0.12),
                                          child: Text(
                                            comment.username.isNotEmpty ? comment.username[0].toUpperCase() : 'A',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0B7285)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          comment.username,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF263238)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      comment.content,
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText:
                            'Escribe un comentario para este avistamiento...',
                        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0xFFD5EEF2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0xFF0B7285), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: isSending ? null : submitComment,
                        icon: isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send, size: 16),
                        label: const Text('Publicar comentario', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B7285),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aviso'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'))
        ],
      ),
    );
  }

  void _openComposeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black87),
                        onPressed: () => Navigator.pop(context),
                      ),
                      ElevatedButton(
                        onPressed:
                            _isLoading ? null : () => _createPost(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006064),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Publicar',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.black12),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                    decoration: const InputDecoration(
                      hintText: '¿Qué criatura marina es?',
                      border: InputBorder.none,
                    ),
                  ),
                  TextField(
                    controller: _descriptionController,
                    maxLines: null,
                    style: const TextStyle(fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'Añade los detalles de tu avistamiento...',
                      border: InputBorder.none,
                    ),
                  ),
                  if (_selectedFileName != null) ...[
                    const SizedBox(height: 10),
                    Chip(
                      backgroundColor: const Color(0xFFE0F7FA),
                      avatar: const Icon(Icons.image,
                          size: 16, color: Color(0xFF006064)),
                      label: Text(_selectedFileName!,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF006064))),
                      onDeleted: () => setModalState(() {
                        _selectedFileBytes = null;
                        _selectedFileName = null;
                      }),
                    ),
                  ],
                  const SizedBox(height: 15),
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_outlined,
                        color: Color(0xFF006064), size: 28),
                    onPressed: () => _pickImage(setModalState),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F9), 
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0B7285),
        elevation: 0.5,
        title: Text(widget.title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: Text(
                "Explorador Activo", 
                style: TextStyle(
                    color: Colors.blueGrey[700],
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
          _buildRoleBadge(), 
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF0B7285)),
            onPressed: () async {
              await _authService.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openComposeModal,
        backgroundColor: const Color(0xFF0B7285),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          child: FutureBuilder<List<Tweet>>(
            future: _tweetsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('Bitácora vacía. Sé el primero en publicar.',
                        style: TextStyle(color: Colors.blueGrey)));
              } else {
                final posts = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) =>
                      _buildTweetStyleCard(posts[index]),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTweetStyleCard(Tweet post) {
    final bool canDelete = _currentRole == 'ROLE_ADMIN' || _currentRole == 'ROLE_MODERATOR';

    return Container(
      margin: const EdgeInsets.only(bottom: 16), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: const Color(0xFFE1EFF2), width: 0.8),
      ),
      padding: const EdgeInsets.all(14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFD6F4FA),
            child: Icon(Icons.water, color: Color(0xFF0B7285), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          text: post.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF263238),
                              fontSize: 16),
                          children: [
                            TextSpan(
                                text: '  #ID${post.id}',
                                style: TextStyle(
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    if (canDelete)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Color(0xFFD32F2F), size: 20), 
                        onPressed: () => _deleteTweet(post.id),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(post.tweet,
                    style: const TextStyle(
                        fontSize: 14.5, color: Color(0xFF455A64), height: 1.25)),
                
                if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      post.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 0.5, color: Color(0xFFECEFF1)),
                const SizedBox(height: 10),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInteractiveReaction("👍", post.meGusta,
                        () => _handleReaction(post, "LIKE")),
                    _buildInteractiveReaction("❤️", post.meEncanta,
                        () => _handleReaction(post, "LOVE")),
                    _buildInteractiveReaction(
                        "😢", post.triste, () => _handleReaction(post, "SAD")),
                    _buildInteractiveReaction(
                        "😂", post.risa, () => _handleReaction(post, "LAUGH")),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInteractiveReaction(
      String emoji, int count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), 
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                  fontSize: 11,
                  color: count > 0 ? const Color(0xFF37474F) : Colors.grey[400],
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}