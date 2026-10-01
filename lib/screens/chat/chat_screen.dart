import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'conversation_screen.dart';

class ChatListScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const ChatListScreen({
    super.key,
    this.onOpenDrawer,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  // ---------------------------------------------------------------------------
  // SAMPLE CHAT THREADS (COMMENTED OUT FOR CLEAN SLATE TESTING)
  // ---------------------------------------------------------------------------
  // static final List<Map<String, dynamic>> _sampleThreads = [
  //   {
  //     'n': 'Nena Santos',
  //     'i': 'NS',
  //     'c': const Color(0xFF10794A),
  //     't': '10:24 AM',
  //     'p': 'Sure! I will arrive at 9:00 AM tomorrow.',
  //     'b': 2,
  //     's': 'House Cleaner · Available now',
  //   },
  //   {
  //     'n': 'Toto Recio',
  //     'i': 'TR',
  //     'c': const Color(0xFFB85C00),
  //     't': 'Yesterday',
  //     'p': 'All set! Confirmed for July 14.',
  //     'b': 1,
  //     's': 'Aircon Tech · Available',
  //   },
  //   {
  //     'n': 'Eddie Morales',
  //     'i': 'EM',
  //     'c': const Color(0xFF6B4BD8),
  //     't': 'Monday',
  //     'p': 'What is your budget for this pipe repair?',
  //     'b': 0,
  //     's': 'Plumber · Davao City',
  //   },
  //   {
  //     'n': 'Romy dela Cruz',
  //     'i': 'RD',
  //     'c': const Color(0xFF1B9457),
  //     't': 'Jul 2',
  //     'p': 'Thank you for trusting my service!',
  //     'b': 0,
  //     's': 'Electrician · Toril',
  //   },
  // ];
  final List<Map<String, dynamic>> _threads = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final list = _threads.where((t) {
      if (query.isEmpty) return true;
      return (t['n'] as String).toLowerCase().contains(query) ||
          (t['p'] as String).toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.sbSurface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.90),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppTheme.sbInk,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.sbInk),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message notifications')),
              );
            },
          ),
          if (widget.onOpenDrawer != null)
            GestureDetector(
              onTap: widget.onOpenDrawer,
              child: Container(
                margin: const EdgeInsets.only(right: 14),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.sbInk,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.sbLine2, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.sbLine),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppTheme.sbInk4, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: 'Search messages',
                        hintStyle: TextStyle(color: AppTheme.sbInk4, fontWeight: FontWeight.w500),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Message list
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppTheme.sbInk4),
                          SizedBox(height: 12),
                          Text('No conversations yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.sbInk)),
                          SizedBox(height: 6),
                          Text(
                            'When you chat with a client or worker, messages will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppTheme.sbInk4, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.sbLine2),
              itemBuilder: (context, idx) {
                final item = list[idx];
                final hasUnread = (item['b'] as int) > 0;

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConversationScreen(
                          otherUserName: item['n'] as String,
                          serviceTitle: item['s'] as String,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: item['c'] as Color,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              item['i'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item['n'] as String,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.sbInk,
                                    ),
                                  ),
                                  Text(
                                    item['t'] as String,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppTheme.sbInk4,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item['p'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                                  color: hasUnread ? AppTheme.sbInk : AppTheme.sbInk3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              gradient: AppTheme.gBlue,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${item['b']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
