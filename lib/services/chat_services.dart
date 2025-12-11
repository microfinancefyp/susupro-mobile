
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:susu_micro/models/chat_message.dart';
import 'package:susu_micro/models/company.dart';
import 'package:susu_micro/models/staff.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Create default chat rooms
  Future<void> createDefaultChatRooms(String companyId, Company company, List<Staff> staffList) async {
    try {
      final chatRoomsRef = _db.collection('companies').doc(companyId).collection('chatrooms');
      
      // 1. Create "All Staff" group chat
      final allStaffChatId = '${companyId}_all_staff';
      final allStaffChatRef = chatRoomsRef.doc(allStaffChatId);
      final allStaffChatDoc = await allStaffChatRef.get();
      
      if (!allStaffChatDoc.exists) {
        final allParticipants = [companyId, ...staffList.map((s) => s.id)];
        await allStaffChatRef.set({
          'type': 'group',
          'name': 'All Staff',
          'participants': allParticipants,
          'createdBy': companyId,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': 'Chat created',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'memberCount': allParticipants.length,
        });
        
        // Add welcome message
        await allStaffChatRef.collection('messages').add({
          'senderId': 'system',
          'senderName': 'System',
          'senderRole': 'System',
          'content': 'Welcome to the All Staff group chat!',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'system',
          'status': 'delivered',
        });
      }

      // 2. Create direct chats between company and each staff member
      for (final staffMember in staffList) {
        final directChatId = '${companyId}_${staffMember.id}';
        final directChatRef = chatRoomsRef.doc(directChatId);
        final directChatDoc = await directChatRef.get();
        
        if (!directChatDoc.exists) {
          await directChatRef.set({
            'type': 'direct',
            'name': staffMember.name,
            'participants': [companyId, staffMember.id],
            'createdAt': FieldValue.serverTimestamp(),
            'lastMessage': 'Chat created, start a conversation!',
            'lastMessageTime': FieldValue.serverTimestamp(),
            'memberCount': 2,
          });
          
          // Add welcome message
          await directChatRef.collection('messages').add({
            'senderId': 'system',
            'senderName': 'System',
            'senderRole': 'System',
            'content': 'Direct chat created. Start your conversation!',
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'system',
            'status': 'delivered',
          });
        }
      }
    } catch (error) {
      print('Error creating default chat rooms: $error');
      rethrow;
    }
  }

  Stream<List<ChatRoom>> getChatRoomsStream(String companyId, String currentUserId) {
    return _db
        .collection('companies')
        .doc(companyId)
        .collection('chatrooms')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<ChatRoom> chatRooms = [];
      
      for (final doc in snapshot.docs) {
        final roomData = doc.data();
        
        // Fetch recent messages
        final messagesSnapshot = await doc.reference
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .get();
        
        final messages = messagesSnapshot.docs
            .map((msgDoc) => Message.fromFirestore(msgDoc))
            .toList()
            .reversed
            .toList();
        
        final chatRoom = ChatRoom.fromFirestore(doc, messages: messages);
        
        // Set last message from messages if available
        if (messages.isNotEmpty) {
          final lastMsg = messages.last;
          final updatedRoom = ChatRoom(
            id: chatRoom.id,
            name: chatRoom.name,
            description: chatRoom.description,
            type: chatRoom.type,
            participants: chatRoom.participants,
            memberCount: chatRoom.memberCount,
            isPinned: chatRoom.isPinned,
            isMuted: chatRoom.isMuted,
            lastMessage: lastMsg,
            lastMessageTime: lastMsg.timestamp,
            unreadCount: chatRoom.unreadCount,
            messages: messages,
            createdBy: chatRoom.createdBy,
            createdAt: chatRoom.createdAt,
          );
          chatRooms.add(updatedRoom);
        } else {
          chatRooms.add(chatRoom);
        }
      }
      
      return chatRooms;
    });
  }

  // Get staff list
  Future<List<Staff>> getStaffList(String companyId) async {
    final snapshot = await _db
        .collection('companies')
        .doc(companyId)
        .collection('staff')
        .get();
    
    return snapshot.docs.map((doc) => Staff.fromFirestore(doc)).toList();
  }

  // Get company details
  Future<Company?> getCompany(String companyId) async {
    final doc = await _db.collection('companies').doc(companyId).get();
    if (doc.exists) {
      return Company.fromFirestore(doc);
    }
    return null;
  }

  // Send message
  Future<void> sendMessage(String companyId, String chatRoomId, Message message) async {
    final chatRoomRef = _db
        .collection('companies')
        .doc(companyId)
        .collection('chatrooms')
        .doc(chatRoomId);
    
    // Add message to messages subcollection
    await chatRoomRef.collection('messages').add(message.toFirestore());
    
    // Update chat room's last message info
    await chatRoomRef.update({
      'lastMessage': message.content,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }
}