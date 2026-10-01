import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../models/message_model.dart';
import '../../services/auth_service.dart';
import '../../services/mysql_service.dart';
import '../../theme/app_theme.dart';

class ConversationScreen extends StatefulWidget {
  final BookingModel? booking;
  final String otherUserName;
  final String? serviceTitle;

  const ConversationScreen({
    super.key,
    this.booking,
    required this.otherUserName,
    this.serviceTitle,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _localMessages = [];

  @override
  void initState() {
    super.initState();
    _seedInitialMessages();
  }

  void _seedInitialMessages() {
    // If there are existing messages in MySqlService for this booking, we don't need dummy seeds
    if (widget.booking != null) {
      final existing = MySqlService()
          .messages
          .where((m) => m.bookingId == widget.booking!.bookingId)
          .toList();
      if (existing.isNotEmpty) return;
    }

    // Default conversational starter
    _localMessages.addAll([
      {
        'isMe': false,
        'text': 'Good day! How are you? I am ready for the scheduled service.',
        'time': '10:14 AM',
      },
      {
        'isMe': true,
        'text': 'Good day! Thank you. Yes, the place is ready.',
        'time': '10:16 AM',
      },
    ]);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _localMessages.add({
        'isMe': true,
        'text': text,
        'time': timeStr,
      });
    });

    _messageController.clear();

    if (widget.booking != null) {
      final currentUserId = AuthService().currentUser?.id ?? 1;
      final otherUserId = currentUserId == widget.booking!.customerId
          ? widget.booking!.workerId
          : widget.booking!.customerId;

      final newMsg = MessageModel(
        messageId: DateTime.now().millisecondsSinceEpoch % 100000,
        bookingId: widget.booking!.bookingId,
        senderId: currentUserId,
        receiverId: otherUserId,
        content: text,
        isRead: false,
        sentAt: now,
        sender: AuthService().currentUser,
      );

      await MySqlService().sendMessage(newMsg);
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.sbBg,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.sbInk, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.gBlue,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppTheme.sbGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.sbInk,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.sbGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.serviceTitle ?? 'Online now',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.sbGreen,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: AppTheme.sbInkSoft, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling ${widget.otherUserName}...'),
                  backgroundColor: AppTheme.sbInk,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.sbInkSoft, size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // Service Banner info card if service/booking is present
          if (widget.serviceTitle != null || widget.booking != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F7F4),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFD4E7DC)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.sbGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.handyman_rounded,
                      size: 16,
                      color: AppTheme.sbGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.serviceTitle ?? widget.booking?.serviceName ?? 'Service',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.sbInk,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.booking != null)
                          Text(
                            'Booking #${widget.booking!.bookingId} • ${widget.booking!.formattedDate}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.sbInkSoft,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD4E7DC)),
                    ),
                    child: Text(
                      widget.booking?.status.toUpperCase() ?? 'ACTIVE',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.sbGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Messages View
          Expanded(
            child: ListenableBuilder(
              listenable: MySqlService(),
              builder: (context, _) {
                final currentUserId = AuthService().currentUser?.id ?? 1;
                final dbMsgs = widget.booking != null
                    ? MySqlService()
                        .messages
                        .where((m) => m.bookingId == widget.booking!.bookingId)
                        .toList()
                    : <MessageModel>[];

                final totalCount = dbMsgs.length + _localMessages.length;

                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  children: [
                    // Date Divider
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.sbLine),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.sbInkSoft,
                          ),
                        ),
                      ),
                    ),

                    // Render db messages if any
                    for (final msg in dbMsgs) ...[
                      _buildMessageBubble(
                        isMe: msg.senderId == currentUserId,
                        text: msg.content ?? '',
                        time: msg.sentAt != null
                            ? '${msg.sentAt!.hour.toString().padLeft(2, '0')}:${msg.sentAt!.minute.toString().padLeft(2, '0')}'
                            : '',
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Render local messages
                    for (final loc in _localMessages) ...[
                      _buildMessageBubble(
                        isMe: loc['isMe'] as bool,
                        text: loc['text'] as String,
                        time: loc['time'] as String,
                      ),
                      const SizedBox(height: 10),
                    ],

                    if (totalCount == 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 40,
                                color: AppTheme.sbInkFaint.withOpacity(0.5),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'No messages yet.\nStart the conversation!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.sbInkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Composer Bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppTheme.sbLine),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.sbInkSoft, size: 24),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Photo and location attachments...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.sbField,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.sbLine),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(fontSize: 14, color: AppTheme.sbInk),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(fontSize: 13, color: AppTheme.sbInkFaint),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _handleSendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _handleSendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppTheme.gBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B9457).withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required bool isMe,
    required String text,
    required String time,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            gradient: isMe ? AppTheme.gBlue : null,
            color: isMe ? null : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
            ),
            border: isMe ? null : Border.all(color: AppTheme.sbLine),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : AppTheme.sbInk,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      color: isMe ? Colors.white.withOpacity(0.7) : AppTheme.sbInkFaint,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.done_all_rounded,
                      size: 13,
                      color: Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
