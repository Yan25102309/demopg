import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; 
import 'services/tweet_service.dart';
import 'models/tweet.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006064)),
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

  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _tweetService = TweetService();
    _loadTweets();
  }

  void _loadTweets() {
    setState(() {
      _tweetsFuture = _tweetService.fetchTweets();
    });
  }

  Future<void> _pickImage(StateSetter setModalState) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
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
      await _tweetService.createTweetWithImage(title, description, _selectedFileName!, _selectedFileBytes!);
      
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
      _showErrorDialog('No tienes permisos de Administrador o Mediador para borrar publicaciones.');
    }
  }

  // ENVÍA LA REACCIÓN AL BACKEND Y ACTUALIZA EL ESTADO EN TIEMPO REAL
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aviso'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))],
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
                top: 20, left: 16, right: 16,
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
                        onPressed: _isLoading ? null : () => _createPost(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006064),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Publicar', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.black12),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                      avatar: const Icon(Icons.image, size: 16, color: Color(0xFF006064)),
                      label: Text(_selectedFileName!, style: const TextStyle(fontSize: 12, color: Color(0xFF006064))),
                      onDeleted: () => setModalState(() {
                        _selectedFileBytes = null;
                        _selectedFileName = null;
                      }),
                    ),
                  ],
                  const SizedBox(height: 15),
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF006064), size: 28),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF006064),
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.blueGrey),
            onPressed: () async {
              await _authService.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openComposeModal,
        backgroundColor: const Color(0xFF006064),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: FutureBuilder<List<Tweet>>(
        future: _tweetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Bitácora vacía. Sé el primero en publicar.', style: TextStyle(color: Colors.grey)));
          } else {
            final posts = snapshot.data!;
            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) => _buildTweetStyleCard(posts[index]),
            );
          }
        },
      ),
    );
  }

  Widget _buildTweetStyleCard(Tweet post) {
    String displayTitle = post.title;
    String displayBody = post.tweet;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      padding: const EdgeInsets.all(14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFE0F7FA),
            child: Icon(Icons.anchor, color: Color(0xFF006064), size: 18),
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
                          text: displayTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
                          children: [
                            TextSpan(text: '  #ID${post.id}', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.normal, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey[400], size: 18),
                      onPressed: () => _deleteTweet(post.id),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(displayBody, style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.3)),
                
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 380), 
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color(0xFFF5F5F5),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Image.network(
                      post.imageUrl!,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      errorBuilder: (c, e, s) => Container(
                        height: 120, 
                        color: Colors.grey[50], 
                        child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.blueGrey, size: 30))
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInteractiveReaction("👍", post.meGusta, () => _handleReaction(post, "LIKE")),
                    _buildInteractiveReaction("❤️", post.meEncanta, () => _handleReaction(post, "LOVE")),
                    _buildInteractiveReaction("😢", post.triste, () => _handleReaction(post, "SAD")),
                    _buildInteractiveReaction("😂", post.risa, () => _handleReaction(post, "LAUGH")),
                    const SizedBox(width: 10),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInteractiveReaction(String emoji, int count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: TextStyle(fontSize: 12, color: count > 0 ? Colors.black87 : Colors.grey[400], fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}