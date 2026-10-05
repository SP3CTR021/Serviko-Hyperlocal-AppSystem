import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../models/worker_profile_model.dart';
import '../../models/job_post_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/mysql_service.dart';
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String? _resolveUserPhoto(
    int userId, {
    UserModel? directUser,
    List<WorkerProfileModel>? workers,
    List<BookingModel>? bookings,
    List<JobPostModel>? jobPosts,
    List<MessageModel>? messages,
    List<UserModel>? users,
  }) {
    if (directUser?.profilePhotoUrl != null && directUser!.profilePhotoUrl!.isNotEmpty) {
      return directUser.profilePhotoUrl;
    }
    if (users != null) {
      final u = users.where((u) => u.id == userId).firstOrNull;
      if (u?.profilePhotoUrl != null && u!.profilePhotoUrl!.isNotEmpty) {
        return u.profilePhotoUrl;
      }
    }
    if (workers != null) {
      final wp = workers.where((w) => w.userId == userId).firstOrNull;
      if (wp?.photoUrl != null && wp!.photoUrl!.isNotEmpty) return wp.photoUrl;
      if (wp?.profilePhotoUrl != null && wp!.profilePhotoUrl!.isNotEmpty) return wp.profilePhotoUrl;
      if (wp?.user?.profilePhotoUrl != null && wp!.user!.profilePhotoUrl!.isNotEmpty) return wp.user!.profilePhotoUrl;
    }
    if (bookings != null) {
      for (final b in bookings) {
        if (b.customerId == userId && b.customer?.profilePhotoUrl != null && b.customer!.profilePhotoUrl!.isNotEmpty) {
          return b.customer!.profilePhotoUrl;
        }
        if (b.workerId == userId && b.worker?.profilePhotoUrl != null && b.worker!.profilePhotoUrl!.isNotEmpty) {
          return b.worker!.profilePhotoUrl;
        }
      }
    }
    if (jobPosts != null) {
      for (final jp in jobPosts) {
        if (jp.customerId == userId && jp.customer?.profilePhotoUrl != null && jp.customer!.profilePhotoUrl!.isNotEmpty) {
          return jp.customer!.profilePhotoUrl;
        }
        for (final bid in jp.bids) {
          if (bid.workerId == userId && bid.worker?.profilePhotoUrl != null && bid.worker!.profilePhotoUrl!.isNotEmpty) {
            return bid.worker!.profilePhotoUrl;
          }
        }
      }
    }
    if (messages != null) {
      for (final m in messages) {
        if (m.senderId == userId && m.sender?.profilePhotoUrl != null && m.sender!.profilePhotoUrl!.isNotEmpty) {
          return m.sender!.profilePhotoUrl;
        }
        if (m.receiverId == userId && m.receiver?.profilePhotoUrl != null && m.receiver!.profilePhotoUrl!.isNotEmpty) {
          return m.receiver!.profilePhotoUrl;
        }
      }
    }
    return null;
  }

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0 && dt.day == now.day) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $ampm';
    } else if (diff.inDays < 2 && dt.day == now.day - 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    final currentUserId = currentUser?.id ?? 0;

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
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.sbInk),
            tooltip: 'Refresh conversations',
            onPressed: () => MySqlService().refreshData(),
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

          // Message list builder
          Expanded(
            child: ListenableBuilder(
              listenable: MySqlService(),
              builder: (context, _) {
                return StreamBuilder<List<MessageModel>>(
                  stream: FirestoreService().getAllMessagesStream(),
                  builder: (context, snapshot) {
                    final allMessages = snapshot.data ?? MySqlService().messages;
                    final allBookings = MySqlService().bookings;
                    final allWorkers = MySqlService().workerProfiles;
                    final allJobPosts = MySqlService().jobPosts;
                    final allUsers = MySqlService().users;

                    final Map<int, Map<String, dynamic>> threadMap = {};

                    // 1. Add active/past bookings involving the logged-in user
                    for (final b in allBookings) {
                      final isCustomer = currentUserId != 0 && (b.customerId == currentUserId || b.customer?.id == currentUserId);
                      final isWorker = currentUserId != 0 && (b.workerId == currentUserId || b.worker?.id == currentUserId);
                      if (!isCustomer && !isWorker) continue;

                      final otherId = isCustomer ? b.workerId : b.customerId;
                      if (otherId == 0 || otherId == currentUserId) continue;

                      final otherUser = isCustomer ? b.worker : b.customer;
                      String otherName = otherUser?.fullName.isNotEmpty == true
                          ? otherUser!.fullName
                          : (otherUser?.name.isNotEmpty == true ? otherUser!.name : '');

                      if (otherName.isEmpty && isCustomer) {
                        final wp = allWorkers.where((w) => w.userId == otherId).firstOrNull;
                        if (wp?.user != null) {
                          otherName = wp!.user!.fullName.isNotEmpty ? wp.user!.fullName : wp.user!.name;
                        }
                      }

                      if (otherName.isEmpty) {
                        otherName = isCustomer ? 'Worker #$otherId' : 'Client #$otherId';
                      }

                      final serviceTitle = b.serviceName ?? b.categoryName ?? 'Service Booking';
                      final date = b.createdAt ?? DateTime(2000);
                      final photo = _resolveUserPhoto(
                        otherId,
                        directUser: otherUser,
                        workers: allWorkers,
                        bookings: allBookings,
                        jobPosts: allJobPosts,
                        messages: allMessages,
                        users: allUsers,
                      );

                      threadMap[otherId] = {
                        'id': otherId,
                        'n': otherName,
                        's': serviceTitle,
                        'p': 'Booking #${b.bookingId} (${b.status.toUpperCase()})',
                        't': _formatTimestamp(date),
                        'b': 0,
                        'latestDate': date,
                        'booking': b,
                        'photo': photo,
                      };
                    }

                    // 2. Add or update threads from messages
                    for (final m in allMessages) {
                      final isSender = (m.senderId == currentUserId);
                      final isReceiver = (m.receiverId == currentUserId);
                      if (!isSender && !isReceiver) continue;

                      final otherId = isSender ? m.receiverId : m.senderId;
                      if (otherId == 0 || otherId == currentUserId) continue;

                      final otherUser = isSender ? m.receiver : m.sender;
                      final msgDate = m.sentAt ?? DateTime(2000);
                      final photo = _resolveUserPhoto(
                        otherId,
                        directUser: otherUser,
                        workers: allWorkers,
                        bookings: allBookings,
                        jobPosts: allJobPosts,
                        messages: allMessages,
                        users: allUsers,
                      );

                      if (!threadMap.containsKey(otherId)) {
                        String? resolvedName;
                        if (otherUser != null) {
                          resolvedName = otherUser.fullName.isNotEmpty ? otherUser.fullName : otherUser.name;
                        }
                        if (resolvedName == null || resolvedName.isEmpty) {
                          final wp = allWorkers.where((w) => w.userId == otherId).firstOrNull;
                          if (wp?.user != null) {
                            resolvedName = wp!.user!.fullName.isNotEmpty ? wp.user!.fullName : wp.user!.name;
                          }
                        }

                        threadMap[otherId] = {
                          'id': otherId,
                          'n': resolvedName?.isNotEmpty == true ? resolvedName! : 'User #$otherId',
                          's': 'Direct Chat',
                          'p': m.content ?? '',
                          't': _formatTimestamp(msgDate),
                          'b': 0,
                          'latestDate': msgDate,
                          'booking': null,
                          'photo': photo,
                        };
                      } else {
                        final existingDate = threadMap[otherId]!['latestDate'] as DateTime;
                        if (msgDate.isAfter(existingDate) || msgDate.isAtSameMomentAs(existingDate)) {
                          threadMap[otherId]!['p'] = m.content ?? '';
                          threadMap[otherId]!['t'] = _formatTimestamp(msgDate);
                          threadMap[otherId]!['latestDate'] = msgDate;
                        }

                        if (otherUser != null && (otherUser.fullName.isNotEmpty || otherUser.name.isNotEmpty)) {
                          final currentName = threadMap[otherId]!['n'] as String;
                          if (currentName.startsWith('User #') ||
                              currentName.startsWith('Worker #') ||
                              currentName.startsWith('Client #')) {
                            threadMap[otherId]!['n'] = otherUser.fullName.isNotEmpty
                                ? otherUser.fullName
                                : otherUser.name;
                          }
                        }

                        if ((threadMap[otherId]!['photo'] == null || (threadMap[otherId]!['photo'] as String).isEmpty) &&
                            photo != null && photo.isNotEmpty) {
                          threadMap[otherId]!['photo'] = photo;
                        }
                      }

                      if (isReceiver && !m.isRead) {
                        threadMap[otherId]!['b'] = (threadMap[otherId]!['b'] as int) + 1;
                      }
                    }

                    // 3. Post-processing threads: sort & compute initials/colors/photos
                    final allThreads = threadMap.values.toList();
                    allThreads.sort((a, b) =>
                        (b['latestDate'] as DateTime).compareTo(a['latestDate'] as DateTime));

                    for (final t in allThreads) {
                      final id = t['id'] as int;
                      if (t['photo'] == null || (t['photo'] as String).isEmpty) {
                        t['photo'] = _resolveUserPhoto(
                          id,
                          workers: allWorkers,
                          bookings: allBookings,
                          jobPosts: allJobPosts,
                          messages: allMessages,
                          users: allUsers,
                        );
                      }

                      final name = (t['n'] as String).trim();
                      final parts = name.split(' ');
                      String initials = '';
                      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
                        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
                      } else if (name.isNotEmpty) {
                        initials = name.substring(0, 1).toUpperCase();
                      } else {
                        initials = 'U';
                      }
                      t['i'] = initials;

                      const colors = [
                        Color(0xFF10794A),
                        Color(0xFF0284C7),
                        Color(0xFF6B4BD8),
                        Color(0xFFB85C00),
                        Color(0xFFE11D48),
                        Color(0xFF0D9488),
                      ];
                      t['c'] = colors[id.abs() % colors.length];
                    }

                    // 4. Search filtering
                    final query = _searchCtrl.text.trim().toLowerCase();
                    final list = allThreads.where((t) {
                      if (query.isEmpty) return true;
                      final name = (t['n'] as String).toLowerCase();
                      final preview = (t['p'] as String).toLowerCase();
                      final service = ((t['s'] as String?) ?? '').toLowerCase();
                      return name.contains(query) || preview.contains(query) || service.contains(query);
                    }).toList();

                    return RefreshIndicator(
                      onRefresh: () => MySqlService().refreshData(),
                      child: list.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 120),
                                Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(40),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.chat_bubble_outline_rounded,
                                            size: 48, color: AppTheme.sbInk4),
                                        SizedBox(height: 12),
                                        Text('No conversations yet',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: AppTheme.sbInk)),
                                        SizedBox(height: 6),
                                        Text(
                                          'When you chat with a client or worker, messages will appear here in real-time.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.sbInk4,
                                              height: 1.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                   const Divider(height: 1, color: AppTheme.sbLine2),
                              itemBuilder: (context, idx) {
                                final item = list[idx];
                                final hasUnread = (item['b'] as int) > 0;

                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ConversationScreen(
                                          otherUserId: item['id'] as int,
                                          otherUserName: item['n'] as String,
                                          serviceTitle: item['s'] as String?,
                                          booking: item['booking'] as BookingModel?,
                                          otherUserPhoto: item['photo'] as String?,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: item['c'] as Color,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: (item['photo'] != null && (item['photo'] as String).isNotEmpty)
                                                ? Image.network(
                                                    item['photo'] as String,
                                                    width: 50,
                                                    height: 50,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => Center(
                                                      child: Text(
                                                        item['i'] as String,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : Center(
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
                                        ),
                                        const SizedBox(width: 13),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item['n'] as String,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 14.5,
                                                        fontWeight: FontWeight.w800,
                                                        color: AppTheme.sbInk,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
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
                                                  fontWeight: hasUnread
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  color: hasUnread
                                                      ? AppTheme.sbInk
                                                      : AppTheme.sbInk3,
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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
