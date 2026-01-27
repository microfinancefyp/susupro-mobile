import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:susu_micro/extensions/spacing.dart';
import 'package:susu_micro/models/customer_model.dart';
import 'package:susu_micro/providers/customer_provider.dart';
import 'package:susu_micro/providers/staff_provider.dart';
import 'package:susu_micro/services/customer_services.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/helpers.dart';
import 'package:susu_micro/views/chat_screen.dart';
import 'package:susu_micro/views/customer_detail.dart';
import 'package:susu_micro/views/staff_transaction.dart';
import 'package:susu_micro/views/staking_page.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late AnimationController _fadeController;
  late AnimationController _headerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _headerAnimation;
  
  List<CustomerModel> _allCustomers = [];
  bool _isSearchFocused = false;
  bool _hasNotifications = true; // Mock notification state
  int _unreadNotifications = 5; // Mock unread count

  late List<String> _locations = locations;
  List<String> get locations {
    final locs = _allCustomers.map((c) => c.location ?? '').toSet().toList();
    locs.sort();
    return ['All', ...locs];
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.elasticOut),
    );
    
    _fetchCustomers();
    _fadeController.forward();
    _headerController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _headerController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

Future<void> _fetchCustomers() async {
  final provider = Provider.of<CustomerProvider>(context, listen: false);
  provider.setLoading(true);
  final staff = Provider.of<StaffProvider>(context, listen: false);

  try {
    final customers = await CustomerService.fetchCustomers(staff.id ?? '');
    _allCustomers = customers;
    _locations = locations;
    logs.d('_allCustomers: $_allCustomers');
    provider.setCustomers(customers);
    provider.setError(null);
  } catch (e) {
    String errorMessage;

    if (e is SocketException) {
      errorMessage = "No internet connection. Please check your network.";
    } else if (e is TimeoutException) {
      errorMessage = "The server is taking too long to respond. Try again later.";
    } else if (e is HttpException) {
      errorMessage = "Server error occurred. Please try again.";
    } else {
      errorMessage = "Something went wrong. Please try again.";
    }

    provider.setError(errorMessage);
  } finally {
    provider.setLoading(false);
  }
}

  void _navigateToNotifications() {
    final staff = Provider.of<StaffProvider>(context, listen: false);
    HapticFeedback.mediumImpact();
     Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(companyId: staff.companyId ?? '', currentUserId: staff.id ?? '',)));
     }

  void _navigateToChat() {
    final staff = Provider.of<StaffProvider>(context, listen: false);
    HapticFeedback.mediumImpact();
   Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(companyId: staff.companyId ?? '', currentUserId: staff.id ?? '',)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(_headerAnimation),
          child: const Text(
            'Customers',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          ScaleTransition(
            scale: _headerAnimation,
            child: _buildNotificationButton(),
          ),
          ScaleTransition(
            scale: _headerAnimation,
            child: _buildChatButton(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return _buildLoadingState();
          }

          if (provider.errorMessage != null) {
            return _buildErrorState(provider.errorMessage!);
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                16.0.hSpace,
                _buildStatsSection(),
                _buildSearchAndFilters(provider),
                Expanded(
                  child: provider.customers.isEmpty
                      ? _buildEmptyState()
                      : _buildCustomersList(provider.customers),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _navigateToNotifications,
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black87,
                  size: 20,
                ),
              ),
            ),
          ),
          if (_hasNotifications)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    _unreadNotifications > 9 ? '9+' : _unreadNotifications.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatButton() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _navigateToChat,
          child: const Icon(
            Icons.chat_bubble_outline,
            color: Colors.green,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        children: [
          Row(
            children: [
              // Total Customers Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors().primaryColor.withOpacity(0.1),
                        AppColors().primaryColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors().primaryColor.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors().primaryColor.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FittedBox(
                        child: Text(
                          '${_allCustomers.length}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              // color: AppColors().primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.people_outline,
                              color: AppColors().primaryColor,
                              size: 24,
                            ),
                          ),
                           const SizedBox(width: 2),
                      
                        ],
                      ),
                     
                      const SizedBox(height: 4),
                      const Text(
                        'Customers',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Locations Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFF0FDF4),
                        Color(0xFFF7FEF9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FittedBox(
                        child: Text(
                          '${_locations.length - 1}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              // color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              color: Colors.green,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Locations',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Staff Transactions Card
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    final staff = Provider.of<StaffProvider>(context, listen: false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StaffTransactionsPage(
                          staffId: staff.id ?? '',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFEF3C7),
                          Color(0xFFFEF9E7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                // color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.receipt_long_outlined,
                                color: Colors.amber,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        // const FittedBox(
                        //   child: Text(
                        //     'TODAY',
                        //     style: TextStyle(
                        //       color: Colors.black,
                        //       fontSize: 16,
                        //       fontWeight: FontWeight.w800,
                        //       height: 1,
                        //       letterSpacing: 0.8,
                        //     ),
                        //   ),
                        // ),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Statements',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(width: 1),
                            Icon(
                              Icons.arrow_forward_ios_outlined,
                              color: Colors.black54,
                              size: 16,
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(CustomerProvider provider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          // Search Bar with improved design
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: _isSearchFocused 
                    ? AppColors().primaryColor.withOpacity(0.4) 
                    : const Color(0xFFE5E7EB),
                width: 2,
              ),
              boxShadow: _isSearchFocused ? [
                BoxShadow(
                  color: AppColors().primaryColor.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                provider.search(value);
                HapticFeedback.selectionClick();
                setState(() {});
              },
              onTap: () {
                setState(() => _isSearchFocused = true);
                HapticFeedback.lightImpact();
              },
              onEditingComplete: () {
                setState(() => _isSearchFocused = false);
                FocusScope.of(context).unfocus();
              },
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: "Search customers by name or location...",
                hintStyle: const TextStyle(
                  color: Colors.black38,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.search_rounded,
                    color: _isSearchFocused ? AppColors().primaryColor : Colors.black.withOpacity(0.4),
                    size: 22,
                  ),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          provider.search('');
                          HapticFeedback.lightImpact();
                          setState(() {});
                        },
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: Colors.black38,
                          size: 20,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Enhanced Location Chips with better styling
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _locations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final loc = _locations[index];
                final isSelected = provider.selectedLocation == loc;

                return GestureDetector(
                  onTap: () {
                    provider.filterByLocation(loc);
                    HapticFeedback.mediumImpact();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors().primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected 
                            ? AppColors().primaryColor 
                            : const Color(0xFFE5E7EB),
                        width: 2,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors().primaryColor.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ] : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (loc == 'All')
                          Icon(
                            Icons.grid_view_rounded,
                            size: 16,
                            color: isSelected ? Colors.white : Colors.black54,
                          )
                        else
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: isSelected ? Colors.white : Colors.black54,
                          ),
                        const SizedBox(width: 6),
                        Text(
                          loc,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
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

  Widget _buildCustomersList(List<CustomerModel> customers) {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 80)),
          tween: Tween<double>(begin: 0, end: 1),
          curve: Curves.easeOutBack,
          builder: (context, animation, child) {
            final clampedAnimation = animation.clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(30 * (1 - clampedAnimation), 0),
              child: Opacity(
                opacity: clampedAnimation,
                child: _buildModernCustomerCard(customers[index]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernCustomerCard(CustomerModel customer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StakingPage(
                  customerName: customer.fullName ?? "Unnamed",
                  customer: customer,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerDetailsPage(customer: customer),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'customer_${customer.uid}',
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors().primaryColor,
                            AppColors().primaryColor.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors().primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          customer.fullName!.isNotEmpty
                              ? customer.fullName![0].toUpperCase()
                              : "?",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.fullName ?? "Unnamed",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "₵${customer.dailyRate}/day",
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                       Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                                Expanded(
                                  child: Text(
                                    customer.location ?? 'Unknown',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.black54,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors().primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors().primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading customers...',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we fetch your data',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _fetchCustomers,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors().primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color: Colors.black38,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No customers found',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters\nto find what you\'re looking for',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                final provider = Provider.of<CustomerProvider>(context, listen: false);
                provider.search('');
                provider.filterByLocation('All');
                setState(() {});
              },
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors().primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}