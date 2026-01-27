// Updated chat_screen.dart with Firebase integration
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:susu_micro/models/chat_message.dart';
import 'package:susu_micro/models/company.dart';
import 'package:susu_micro/models/staff.dart';
import 'package:susu_micro/services/chat_services.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/views/chat_room_screen.dart';

class ChatScreen extends StatefulWidget {
  final String companyId;
  final String currentUserId;
  
  const ChatScreen({
    super.key,
    required this.companyId,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = true;
  
  final ChatService _chatService = ChatService();
  List<ChatRoom> _chatRooms = [];
  List<Staff> _staff = [];
  Company? _company;
  StreamSubscription<List<ChatRoom>>? _chatRoomsSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeChats();
  }

  Future<void> _initializeChats() async {
    try {
      setState(() => _isLoading = true);
      
      // 1. Fetch company data
      _company = await _chatService.getCompany(widget.companyId);
      
      // 2. Fetch staff data
      _staff = await _chatService.getStaffList(widget.companyId);
      
      // 3. Create default chat rooms if needed
      if (_company != null) {
        await _chatService.createDefaultChatRooms(widget.companyId, _company!, _staff);
      }
      
      // 4. Subscribe to chat rooms stream
      _chatRoomsSubscription = _chatService
          .getChatRoomsStream(widget.companyId, widget.currentUserId)
          .listen((chatRooms) {
        if (mounted) {
          setState(() {
            _chatRooms = _processChartRooms(chatRooms);
            _isLoading = false;
          });
        }
      });
      
    } catch (error) {
      print('Error initializing chats: $error');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<ChatRoom> _processChartRooms(List<ChatRoom> rooms) {
    return rooms.map((room) {
      if (room.type == ChatRoomType.direct) {
        // Find the other participant for direct chats
        final otherParticipantId = room.participants
            .firstWhere((p) => p != widget.currentUserId, orElse: () => '');
        
        if (otherParticipantId == widget.companyId) {
          // Chat with company
          return ChatRoom(
            id: room.id,
            name: _company?.name ?? 'Company',
            description: 'Company Owner',
            type: room.type,
            participants: room.participants,
            memberCount: room.memberCount,
            isPinned: room.isPinned,
            isMuted: room.isMuted,
            lastMessage: room.lastMessage,
            lastMessageTime: room.lastMessageTime,
            unreadCount: room.unreadCount,
            messages: room.messages,
            createdBy: room.createdBy,
            createdAt: room.createdAt,
          );
        } else {
          // Chat with staff member
          final staff = _staff.firstWhere(
            (s) => s.id == otherParticipantId,
            orElse: () => Staff(id: '', name: 'Unknown', role: ''),
          );
          
          return ChatRoom(
            id: room.id,
            name: staff.name,
            description: staff.role,
            type: room.type,
            participants: room.participants,
            memberCount: room.memberCount,
            isPinned: room.isPinned,
            isMuted: room.isMuted,
            lastMessage: room.lastMessage,
            lastMessageTime: room.lastMessageTime,
            unreadCount: room.unreadCount,
            messages: room.messages,
            createdBy: room.createdBy,
            createdAt: room.createdAt,
          );
        }
      }
      return room;
    }).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _chatRoomsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatList(_chatRooms),
                _buildChatList(_chatRooms.where((room) => 
                    room.type == ChatRoomType.company || 
                    room.type == ChatRoomType.department).toList()),
                _buildChatList(_chatRooms.where((room) => 
                    room.type == ChatRoomType.direct).toList()),
                _buildChatList(_chatRooms.where((room) => 
                    room.type == ChatRoomType.group).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... (keep all your existing UI methods like _buildAppBar, _buildSearchBar, etc.)
  // Just update the _buildChatList method to handle the filtered data:

  Widget _buildChatList(List<ChatRoom> chatRooms) {
    final filteredRooms = _searchController.text.isEmpty
        ? chatRooms
        : chatRooms.where((room) =>
            room.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            (room.lastMessage?.content.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false)
          ).toList();

    if (filteredRooms.isEmpty) {
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
              'No chats found',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredRooms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween<double>(begin: 0, end: 1),
          curve: Curves.easeOutBack,
          builder: (context, animation, child) {
            final clampedAnimation = animation.clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(30 * (1 - clampedAnimation), 0),
              child: Opacity(
                opacity: clampedAnimation,
                child: _buildChatRoomCard(filteredRooms[index]),
              ),
            );
          },
        );
      },
    );
  }

  // Update the message display in _buildChatRoomCard:
  Widget _buildChatRoomCard(ChatRoom room) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: room.isPinned ? AppColors().primaryColor.withOpacity(0.3) : const Color(0xFFE5E7EB),
          width: room.isPinned ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatRoomScreen(
                  chatRoom: room,
                  companyId: widget.companyId,
                  currentUserId: widget.currentUserId,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildRoomAvatar(room),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (room.isPinned)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                Icons.push_pin,
                                size: 14,
                                color: AppColors().primaryColor,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              room.name,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (room.isMuted)
                            Icon(
                              Icons.volume_off_rounded,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            _formatTime(room.lastMessageTime ?? DateTime.now()),
                            style: TextStyle(
                              color: room.unreadCount > 0 ? AppColors().primaryColor : Colors.grey.shade500,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (room.lastMessage != null)
                        Row(
                          children: [
                            if (room.lastMessage!.type == MessageType.announcement)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ANNOUNCEMENT',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                room.lastMessage!.senderName.isNotEmpty 
                                    ? '${room.lastMessage!.senderName}: ${room.lastMessage!.content}'
                                    : room.lastMessage!.content,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getRoomTypeColor(room.type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getRoomTypeIcon(room.type),
                                  size: 10,
                                  color: _getRoomTypeColor(room.type),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${room.memberCount} ${room.memberCount == 1 ? 'member' : 'members'}',
                                  style: TextStyle(
                                    color: _getRoomTypeColor(room.type),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (room.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors().primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                room.unreadCount > 99 ? '99+' : room.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
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
        ),
      ),
    );
  }

  // ... (keep all your existing helper methods like _buildRoomAvatar, _getRoomTypeColor, etc.)

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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
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
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Messages',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Stay connected with your team',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            // Show online status or settings
          },
          icon: Stack(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.black87,
                  size: 18,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isSearching 
                ? AppColors().primaryColor.withOpacity(0.3) 
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {});
          },
          onTap: () {
            setState(() => _isSearching = true);
            HapticFeedback.lightImpact();
          },
          onEditingComplete: () {
            setState(() => _isSearching = false);
            FocusScope.of(context).unfocus();
          },
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: "Search messages or people...",
            hintStyle: const TextStyle(
              color: Colors.black38,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.search_rounded,
                color: _isSearching ? AppColors().primaryColor : Colors.black.withOpacity(0.4),
                size: 20,
              ),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.clear_rounded,
                      color: Colors.black38,
                      size: 18,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors().primaryColor,
        unselectedLabelColor: Colors.black54,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        indicatorColor: AppColors().primaryColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('All'),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors().primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_chatRooms.length}',
                    style: TextStyle(
                      color: AppColors().primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Tab(text: 'Teams'),
          const Tab(text: 'Direct'),
          const Tab(text: 'Groups'),
        ],
      ),
    );
  }

  Widget _buildRoomAvatar(ChatRoom room) {
    return Hero(
      tag: 'chat_${room.id}',
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getRoomTypeColor(room.type),
              _getRoomTypeColor(room.type).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _getRoomTypeColor(room.type).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: room.type == ChatRoomType.direct
            ? Center(
                child: Text(
                  room.name.split(' ').map((word) => word.isNotEmpty ? word[0] : '').take(2).join().toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : Icon(
                _getRoomTypeIcon(room.type),
                color: Colors.white,
                size: 24,
              ),
      ),
    );
  }
}

// Example usage in your main app:
/*
// In your main.dart or wherever you navigate to the chat screen:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ChatScreen(
      companyId: 'your_company_id',
      currentUserId: 'current_user_id', // This could be company ID or staff ID
    ),
  ),
);
*/

// Don't forget to add these to your pubspec.yaml:
/*
dependencies:
  firebase_core: ^2.24.2
  cloud_firestore: ^4.13.6
  provider: ^6.1.1
  # ... your other dependencies
*/

// Initialize Firebase in your main.dart:
/*
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
*/