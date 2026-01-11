import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/selected_topic_provider.dart';
import '../widgets/custom_drawer.dart';
import '../../../../core/network/ai_api_service.dart';
import '../../../quiz/presentation/pages/quiz_screen.dart';
import '../../../vocabulary/presentation/pages/vocabulary_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final TextEditingController _chatController = TextEditingController();
  final FocusNode _chatFocusNode = FocusNode();
  final _aiService = AiApiService.instance;

  // Her kategori için ayrı mesaj saklama
  final Map<String, List<Map<String, String>>> _conversationsByTopic = {};
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  String? _currentTopicKey;

  @override
  void dispose() {
    _chatController.dispose();
    _chatFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // İlk yüklemede "Genel Almanca Sohbet" kategorisi için mesaj listesi
    _currentTopicKey = 'Genel Almanca Sohbet';
    _messages = [];
  }

  void _onTopicChanged(String? newTopicKey) {
    if (_currentTopicKey != newTopicKey) {
      // Mevcut konunun mesajlarını kaydet
      final currentKey = _currentTopicKey;
      if (currentKey != null) {
        _conversationsByTopic[currentKey] = List.from(_messages);
      }

      // Yeni konunun mesajlarını yükle veya boş liste oluştur
      setState(() {
        _currentTopicKey = newTopicKey;
        _messages = newTopicKey != null
            ? List.from(_conversationsByTopic[newTopicKey] ?? [])
            : [];
      });

      // AI conversation history'yi resetle
      _aiService.resetConversation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTopic = ref.watch(selectedTopicProvider);

    // Kategori değiştiğinde mesajları yönet
    final topicKey = selectedTopic?.topicTitle ?? 'general';
    if (_currentTopicKey != topicKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onTopicChanged(topicKey);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Almanca AI',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VocabularyScreen(),
                ),
              );
            },
            icon: const Icon(Icons.book_outlined),
            tooltip: 'Kelime Havuzum',
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          if (selectedTopic != null)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizScreen(
                      levelName: selectedTopic.level,
                      topicName: selectedTopic.topicTitle,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.assignment_outlined),
              tooltip: 'Test Çöz',
              color: Theme.of(context).colorScheme.onPrimary,
            ),
        ],
      ),
      drawer: const CustomDrawer(),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildPersistentChatBar(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final selectedTopic = ref.watch(selectedTopicProvider);

    return Column(
      children: [
        // Konu seçiliyse başlık göster
        if (selectedTopic != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.school,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedTopic.topicTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Almanca öğrenmeye başlayın!\n\nSol menüden bir konu seçebilir veya\ndirekt soru sorabilirsiniz.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isUser = message['role'] == 'user';
                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SelectableText(
                          message['content'] ?? '',
                          style: TextStyle(
                            color: isUser
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'AI düşünüyor...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPersistentChatBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: const Color(0xFFEC008C), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: TextField(
                      controller: _chatController,
                      focusNode: _chatFocusNode,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Bir soru sorun...',
                        hintStyle: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => _sendMessage(_chatController.text),
                    icon: const Icon(Icons.send_rounded),
                    color: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || _isLoading) {
      return;
    }

    final selectedTopic = ref.read(selectedTopicProvider);

    setState(() {
      _messages.add({'role': 'user', 'content': message});
      _isLoading = true;
    });

    _chatController.clear();
    _chatFocusNode.unfocus();

    try {
      // Kategori seçilmediyse genel seviye kullan
      final userLevel = selectedTopic?.level ?? 'A1.1';
      final topic = selectedTopic?.topicTitle ?? 'Genel Almanca';

      // Her mesajda güncel kategori bilgisini kullan
      _aiService.startConversationWithoutMessage(
        userLevel: userLevel,
        topic: topic,
      );

      // Kullanıcının mesajını direkt gönder
      final response = await _aiService.sendMessage(
        message,
        userLevel: userLevel,
        topic: topic,
      );
      final formattedResponse = _formatAIResponse(response);

      setState(() {
        _messages.add({'role': 'assistant', 'content': formattedResponse});
        _isLoading = false;
      });
    } catch (e) {
      // Hata durumunda kullanıcı mesajını kaldır
      setState(() {
        if (_messages.isNotEmpty && _messages.last['role'] == 'user') {
          _messages.removeLast();
        }
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı hatası. Lütfen tekrar deneyin.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Kapat',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  String _formatAIResponse(String response) {
    try {
      // JSON parse etmeyi dene
      final decoded = jsonDecode(response);

      if (decoded is Map<String, dynamic>) {
        final buffer = StringBuffer();

        // Soru
        if (decoded.containsKey('soru')) {
          buffer.writeln('📝 Soru: ${decoded['soru']}\n');
        }

        // Seçenekler
        if (decoded.containsKey('secsenekler') &&
            decoded['secsenekler'] is List) {
          buffer.writeln('Seçenekler:');
          for (var secenek in decoded['secsenekler']) {
            buffer.writeln('• $secenek');
          }
          buffer.writeln();
        }

        // Doğru cevap
        if (decoded.containsKey('dogru_cevap')) {
          buffer.writeln('✅ Doğru Cevap: ${decoded['dogru_cevap']}');
        }

        return buffer.toString().trim();
      }
    } catch (e) {
      // JSON değilse olduğu gibi dön
    }

    return response;
  }
}
