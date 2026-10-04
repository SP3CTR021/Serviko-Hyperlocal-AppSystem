import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/mysql_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/booking_completion_modal.dart';

class ConversationScreen extends StatefulWidget {
  final BookingModel? booking;
  final String otherUserName;
  final String? serviceTitle;
  final int? otherUserId;

  const ConversationScreen({
    super.key,
    this.booking,
    required this.otherUserName,
    this.serviceTitle,
    this.otherUserId,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

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
    _messageController.clear();

    final currentUserId = AuthService().currentUser?.id ?? 1;
    final otherUserId = widget.otherUserId ??
        (widget.booking != null
            ? (currentUserId == widget.booking!.customerId ? widget.booking!.workerId : widget.booking!.customerId)
            : 0);

    UserModel? receiverUser;
    if (widget.booking != null) {
      receiverUser = currentUserId == widget.booking!.customerId
          ? widget.booking!.worker
          : widget.booking!.customer;
    }
    if (receiverUser == null && otherUserId != 0) {
      receiverUser = UserModel(
        id: otherUserId,
        name: widget.otherUserName,
        fullName: widget.otherUserName,
        email: '',
        role: 'user',
      );
    }

    final newMsg = MessageModel(
      messageId: DateTime.now().millisecondsSinceEpoch % 1000000,
      bookingId: widget.booking?.bookingId,
      senderId: currentUserId,
      receiverId: otherUserId,
      content: text,
      isRead: false,
      sentAt: now,
      sender: AuthService().currentUser,
      receiver: receiverUser,
    );

    await FirestoreService().sendMessage(newMsg);
    await MySqlService().sendMessage(newMsg);

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
                  InkWell(
                    onTap: widget.booking == null
                        ? null
                        : () {
                            if (widget.booking!.isCompleted) {
                              showBookingReceiptDialog(
                                context: context,
                                booking: widget.booking!,
                                isCustomer: AuthService().currentUser?.isCustomer ?? true,
                              );
                            } else {
                              showBookingCompletionModal(
                                context: context,
                                booking: widget.booking!,
                                isCustomer: AuthService().currentUser?.isCustomer ?? true,
                                onCompleted: () {
                                  if (mounted) setState(() {});
                                },
                              );
                            }
                          },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD4E7DC)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.booking?.isCompleted == true
                                ? Icons.receipt_long_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 13,
                            color: AppTheme.sbGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.booking?.isCompleted == true
                                ? 'RECEIPT'
                                : (widget.booking != null ? 'COMPLETE' : 'ACTIVE'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.sbGreen,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Messages View
          Expanded(
            child: Builder(
              builder: (context) {
                final currentUserId = AuthService().currentUser?.id ?? 1;
                final otherUserId = widget.otherUserId ??
                    (widget.booking != null
                        ? (currentUserId == widget.booking!.customerId ? widget.booking!.workerId : widget.booking!.customerId)
                        : 0);

                return StreamBuilder<List<MessageModel>>(
                  stream: FirestoreService().getConversationStream(
                    bookingId: widget.booking?.bookingId,
                    currentUserId: currentUserId,
                    otherUserId: otherUserId,
                  ),
                  builder: (context, snapshot) {
                    final allMsgs = snapshot.data ??
                        MySqlService().messages.where((m) {
                          if (widget.booking != null && m.bookingId == widget.booking!.bookingId) return true;
                          if (otherUserId != 0) {
                            return (m.senderId == currentUserId && m.receiverId == otherUserId) ||
                                   (m.senderId == otherUserId && m.receiverId == currentUserId);
                          }
                          return false;
                        }).toList();

                    if (allMsgs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color: AppTheme.sbInk4.withOpacity(0.5),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No messages yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.sbInk,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Send a message to ${widget.otherUserName} to begin coordinates!',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: AppTheme.sbInk4),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      itemCount: allMsgs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final msg = allMsgs[idx];
                        final isMe = msg.senderId == currentUserId;
                        final timeStr = msg.sentAt != null
                            ? '${msg.sentAt!.hour.toString().padLeft(2, '0')}:${msg.sentAt!.minute.toString().padLeft(2, '0')}'
                            : '';
                        return _buildMessageBubble(
                          isMe: isMe,
                          text: msg.content ?? '',
                          time: timeStr,
                        );
                      },
                    );
                  },
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
