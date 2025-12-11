// views/chat_room_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:susu_micro/models/chat_message.dart';
import 'package:susu_micro/models/staff.dart';
import 'package:susu_micro/providers/staff_provider.dart';
import 'package:susu_micro/services/chat_services.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/helpers.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final String companyId;
  final String currentUserId;

  const ChatRoomScreen({
    super.key,
    required this.chatRoom,
    required this.companyId,
    required this.currentUserId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  final ChatService _chatService = ChatService();
  List<Message> _messages = [];
  StreamSubscription<List<Message>>? _messagesSubscription;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initializeMessages();
  }

  void _initializeMessages() {
    // Subscribe to messages stream
    _messagesSubscription = _getMessagesStream().listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        
        // Auto-scroll to bottom when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  Stream<List<Message>> _getMessagesStream() {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('chatrooms')
        .doc(widget.chatRoom.id)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }

  void sendMessageToOffice() async {
    final staff = Provider.of<StaffProvider>(context, listen: false);
    try {
      final response = await http.post(
        Uri.parse("https://susu-pro-backend.onrender.com/api/messages/send-web-notification"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
            "companyId": staff.companyId,
            "staffId": staff.id,
            "title": staff.fullName,
            "body": _messageController.text.trim(),
            "data": {}
          }),
      );
      logs.d("Response: ${response.body}");
    } catch (e) {
      logs.d(e);
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      // Get current user info (you might want to get this from a provider or service)
      final currentUser = await _getCurrentUserInfo();
      
      final message = Message(
        id: '', // Firestore will generate this
        senderId: widget.currentUserId,
        senderName: currentUser['name'] ?? 'User',
        senderRole: currentUser['role'] ?? 'Member',
        content: messageText,
        timestamp: DateTime.now(),
        type: MessageType.text,
        status: 'sending',
      );

      await _chatService.sendMessage(widget.companyId, widget.chatRoom.id, message);
      sendMessageToOffice();
      _messageController.clear();
      HapticFeedback.lightImpact();
      
    } catch (error) {
      print('Error sending message: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<Map<String, String>> _getCurrentUserInfo() async {
    // Try to get company info first
    if (widget.currentUserId == widget.companyId) {
      final company = await _chatService.getCompany(widget.companyId);
      return {
        'name': company?.name ?? 'Company',
        'role': 'Owner',
      };
    } else {
      // Get staff info
      final staffList = await _chatService.getStaffList(widget.companyId);
      final staff = staffList.firstWhere(
        (s) => s.id == widget.currentUserId,
        orElse: () => Staff(id: '', name: 'User', role: 'Member'),
      );
      return {
        'name': staff.name,
        'role': staff.role,
      };
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
      ),
      title: Row(
        children: [
          Hero(
            tag: 'chat_${widget.chatRoom.id}',
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getRoomTypeColor(widget.chatRoom.type),
                    _getRoomTypeColor(widget.chatRoom.type).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: widget.chatRoom.type == ChatRoomType.direct
                  ? Center(
                      child: Text(
                        widget.chatRoom.name.split(' ').map((word) => word.isNotEmpty ? word[0] : '').take(2).join().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : Icon(
                      _getRoomTypeIcon(widget.chatRoom.type),
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatRoom.name,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.chatRoom.description != null)
                  Text(
                    widget.chatRoom.description!,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _showChatOptions();
          },
          icon: const Icon(Icons.more_vert_rounded, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation!',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == widget.currentUserId;
        final showAvatar = index == 0 || 
            _messages[index - 1].senderId != message.senderId;
        final showTime = index == _messages.length - 1 ||
            _messages[index + 1].senderId != message.senderId ||
            _messages[index + 1].timestamp.difference(message.timestamp).inMinutes > 5;

        return _buildMessageBubble(message, isMe, showAvatar, showTime);
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe, bool showAvatar, bool showTime) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _getRoomTypeColor(widget.chatRoom.type),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else if (!isMe)
            const SizedBox(width: 40),
          
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && showAvatar && message.senderName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors().primaryColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe || !showAvatar ? 18 : 4),
                      bottomRight: Radius.circular(!isMe || !showAvatar ? 18 : 4),
                    ),
                    border: !isMe ? Border.all(color: const Color(0xFFE5E7EB)) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.type == MessageType.announcement)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ANNOUNCEMENT',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (showTime)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatMessageTime(message.timestamp),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.status == 'delivered' ? Icons.done_all : Icons.done,
                            size: 14,
                            color: message.status == 'delivered' 
                                ? AppColors().primaryColor 
                                : Colors.grey.shade400,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: const TextStyle(
                      color: Colors.black38,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        // Add attachment functionality
                      },
                      icon: Icon(
                        Icons.attach_file_rounded,
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _messageController.text.trim().isNotEmpty && !_isSending
                      ? AppColors().primaryColor
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: _messageController.text.trim().isNotEmpty
                            ? Colors.white
                            : Colors.grey.shade500,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.info_outline, color: AppColors().primaryColor),
              title: const Text('Chat Info'),
              onTap: () {
                Navigator.pop(context);
                _showChatInfo();
              },
            ),
            ListTile(
              leading: Icon(Icons.volume_off_outlined, color: Colors.grey.shade600),
              title: Text(widget.chatRoom.isMuted ? 'Unmute' : 'Mute'),
              onTap: () {
                Navigator.pop(context);
                // Implement mute/unmute functionality
              },
            ),
            if (widget.chatRoom.type != ChatRoomType.direct)
              ListTile(
                leading: Icon(Icons.exit_to_app, color: Colors.red.shade600),
                title: const Text('Leave Chat'),
                onTap: () {
                  Navigator.pop(context);
                  _showLeaveConfirmation();
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showChatInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getRoomTypeColor(widget.chatRoom.type),
                          _getRoomTypeColor(widget.chatRoom.type).withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: widget.chatRoom.type == ChatRoomType.direct
                        ? Center(
                            child: Text(
                              widget.chatRoom.name.split(' ').map((word) => word.isNotEmpty ? word[0] : '').take(2).join().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : Icon(
                            _getRoomTypeIcon(widget.chatRoom.type),
                            color: Colors.white,
                            size: 36,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.chatRoom.name,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.chatRoom.description != null)
                    Text(
                      widget.chatRoom.description!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.chatRoom.memberCount} members',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Chat'),
        content: const Text('Are you sure you want to leave this chat? You won\'t receive any more messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to chat list
              // Implement leave chat functionality
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Color _getRoomTypeColor(ChatRoomType type) {
    switch (type) {
      case ChatRoomType.company:
        return Colors.red.shade600;
      case ChatRoomType.department:
        return AppColors().primaryColor;
      case ChatRoomType.direct:
        return Colors.green.shade600;
      case ChatRoomType.group:
        return Colors.purple.shade600;
    }
  }

  IconData _getRoomTypeIcon(ChatRoomType type) {
    switch (type) {
      case ChatRoomType.company:
        return Icons.business_rounded;
      case ChatRoomType.department:
        return Icons.groups_rounded;
      case ChatRoomType.direct:
        return Icons.person_rounded;
      case ChatRoomType.group:
        return Icons.group_work_rounded;
    }
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) return 'Yesterday';
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}