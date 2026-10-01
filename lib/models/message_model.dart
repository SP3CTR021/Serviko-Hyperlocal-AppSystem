import 'user_model.dart';

class MessageModel {
  final int messageId;
  final int? bookingId;
  final int senderId;
  final int receiverId;
  final String? content;
  final bool isRead;
  final DateTime? sentAt;
  final UserModel? sender;
  final UserModel? receiver;

  MessageModel({
    required this.messageId,
    this.bookingId,
    required this.senderId,
    required this.receiverId,
    this.content,
    this.isRead = false,
    this.sentAt,
    this.sender,
    this.receiver,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, {UserModel? sender, UserModel? receiver}) {
    return MessageModel(
      messageId: map['message_id'] is int ? map['message_id'] : int.tryParse(map['message_id'].toString()) ?? 0,
      bookingId: map['booking_id'] != null ? int.tryParse(map['booking_id'].toString()) : null,
      senderId: map['sender_id'] is int ? map['sender_id'] : int.tryParse(map['sender_id'].toString()) ?? 0,
      receiverId: map['receiver_id'] is int ? map['receiver_id'] : int.tryParse(map['receiver_id'].toString()) ?? 0,
      content: map['content']?.toString(),
      isRead: map['is_read'] == 1 || map['is_read'] == true,
      sentAt: map['sent_at'] != null ? DateTime.tryParse(map['sent_at'].toString()) : null,
      sender: sender,
      receiver: receiver,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message_id': messageId,
      'booking_id': bookingId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'is_read': isRead ? 1 : 0,
      'sent_at': sentAt?.toIso8601String(),
    };
  }
}
