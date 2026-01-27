// Mock models for demonstration
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:susu_micro/views/chat_screen.dart';

enum MessageType { text, announcement, system, file }
enum ChatRoomType { company, department, direct, group }

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final String status;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.timestamp,
    required this.type,
    required this.status,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      status: data['status'] ?? 'delivered',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type.name,
      'status': status,
    };
  }
}

class ChatRoom {
  final String id;
  final String name;
  final String? description;
  final ChatRoomType type;
  final List<String> participants;
  final int memberCount;
  final bool isPinned;
  final bool isMuted;
  final Message? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final List<Message> messages;
  final String? createdBy;
  final DateTime? createdAt;

  ChatRoom({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.participants,
    required this.memberCount,
    this.isPinned = false,
    this.isMuted = false,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.messages = const [],
    this.createdBy,
    this.createdAt,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc, {List<Message>? messages}) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      type: ChatRoomType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ChatRoomType.group,
      ),
      participants: List<String>.from(data['participants'] ?? []),
      memberCount: data['memberCount'] ?? 0,
      isPinned: data['isPinned'] ?? false,
      isMuted: data['isMuted'] ?? false,
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      unreadCount: data['unreadCount'] ?? 0,
      messages: messages ?? [],
      createdBy: data['createdBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.name,
      'participants': participants,
      'memberCount': memberCount,
      'isPinned': isPinned,
      'isMuted': isMuted,
      'lastMessage': lastMessage?.content,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': unreadCount,
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}