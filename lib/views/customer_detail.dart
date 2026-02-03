import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:susu_micro/extensions/spacing.dart';
import 'package:susu_micro/models/customer_model.dart';
import 'package:susu_micro/providers/staff_provider.dart';
import 'package:susu_micro/route_transitions/route_transition_fade.dart';
import 'package:susu_micro/utils/appAssets.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/helpers.dart';
import 'package:susu_micro/utils/text.dart';
import 'package:susu_micro/views/customer_profile.dart';
import 'package:susu_micro/views/staking_page.dart';
import 'package:susu_micro/views/transaction_history.dart';
import 'package:susu_micro/views/withdrawal_page.dart';
import 'package:susu_micro/widgets/addCustomer_popUp.dart';

class CustomerDetailsPage extends StatefulWidget {
  final CustomerModel? customer;
   
  const CustomerDetailsPage({super.key, this.customer});

  @override
  State<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingAccounts = true;
  bool _isLoadingTransactions = true;
  
  late AnimationController _animationController;
  late AnimationController _balanceAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _balanceCountAnimation;
  
  double _totalBalance = 0.0;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _balanceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _balanceCountAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _balanceAnimationController, curve: Curves.easeOut),
    );
    
    _fetchCustomerData();
    _animationController.forward();
  }

  Future<void> _fetchCustomerData() async {
    if (widget.customer?.uid != null) {
      await Future.wait([
        _fetchAccounts(),
        _fetchTransactions(),
      ]);
    }
  }

  Future<void> _fetchAccounts() async {
    try {
      final response = await http.get(
        Uri.parse("https://susu-pro-backend.onrender.com/api/accounts/customer/${widget.customer!.uid}"),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded['data'];
        
        setState(() {
          _accounts = List<Map<String, dynamic>>.from(data);
          _totalBalance = _accounts.fold(0.0, (sum, account) {
          final balance = double.tryParse(account['balance'].toString()) ?? 0.0;
          return sum + balance;
        });
        _isLoadingAccounts = false;
        });
        
        // Start balance animation
        _balanceAnimationController.forward();
      }
    } catch (e) {
      setState(() => _isLoadingAccounts = false);
      logs.e("Error fetching accounts: $e");
    }
  }

  Future<void> _fetchTransactions() async {
    try {
      final response = await http.get(
        Uri.parse("https://susu-pro-backend.onrender.com/api/transactions/customer/${widget.customer!.uid}"),
      );
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> data = decoded["data"];
        
        setState(() {
          _transactions = List<Map<String, dynamic>>.from(data);
          _isLoadingTransactions = false;
        });
      } else {
        setState(() => _isLoadingTransactions = false);
      }
    } catch (e) {
      setState(() => _isLoadingTransactions = false);
      logs.e("Error fetching transactions: $e");
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTransactionIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'deposit':
      case 'stake':
        return Icons.trending_up;
      case 'withdrawal':
        return Icons.trending_down;
      case 'transfer':
        return Icons.swap_horiz;
      default:
        return Icons.monetization_on;
    }
  }

  void _navigateToStaking() {
    if (widget.customer != null) {
      Navigator.push(
        context,
        FadeRoute(
          page: StakingPage(
            customerName: widget.customer!.fullName ?? "Customer",
            customer: widget.customer!,
          ),
        ),
      );
    }
  }
  void _navigateToWithdrawalPage() {
    if (widget.customer != null) {
      Navigator.push(
        context,
        FadeRoute(
          page: WithdrawPage(
            customerName: widget.customer!.fullName ?? "Customer",
            customer: widget.customer!,
            accounts: _accounts,
          ),
        ),
      );
    }
  }
  void _navigateToTransactionHistory() {
    if (widget.customer != null) {
      Navigator.push(
        context,
        FadeRoute(
          page: TransactionHistoryPage(customer: widget.customer!,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _balanceAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staff = Provider.of<StaffProvider>(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar with Hero Header
          SliverAppBar(
            iconTheme: IconThemeData(color: Colors.white),
            expandedHeight: 350.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors().primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors().primaryColor,
                        AppColors().primaryColor.withOpacity(0.8),
                        AppColors().primaryColor.withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          40.0.vSpace, 
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 32,
                                    child: Center(child: Text(widget.customer?.fullName?.substring(0, 1)[0] ?? "C")),
                                  ),
                                ),
                              ),
                              16.0.hSpace,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.customer?.fullName ?? "Customer Name",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    2.0.vSpace,
                                     Text(
                                          widget.customer?.account_number ?? "No account",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    Text(
                                      widget.customer?.phoneNumber ?? "No phone",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white, size: 16),
                                    6.0.hSpace,
                                    const Text(
                                      "Active",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          24.0.vSpace,
                          
                          // Balance Card
                          AnimatedBuilder(
                            animation: _balanceCountAnimation,
                            builder: (context, child) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 20),
                                        8.0.hSpace,
                                        const Text(
                                          "Total Balance",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                         2.0.vSpace,
                                    Text(
                                      " (across ${_accounts.length} account${_accounts.length != 1 ? 's' : ''})",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                      ],
                                    ),
                                    5.0.vSpace,
                                    Text(
                                      "GHS ${(_totalBalance * _balanceCountAnimation.value).toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 255, 255, 255),
                                      ),
                                    ),
                                   
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(FadeRoute(page: CustomerProfile(customer: widget.customer)));
                },
                icon: const Icon(Icons.info_outline, color: Colors.white),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'stake':
                      _navigateToStaking();
                      break;
                    case 'edit':
                      // Navigate to edit customer
                      break;
                    case 'statements':
                      // Generate statements
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'stake',
                    child: Row(
                      children: [
                        Icon(Icons.trending_up, size: 20),
                        SizedBox(width: 12),
                        Text('Make Stake'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('Edit Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'statements',
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long, size: 20),
                        SizedBox(width: 12),
                        Text('Statements'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Main Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(_animationController),
                child: Column(
                  children: [
                    20.0.vSpace,
                    
                    // Quick Actions
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Quick Actions",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          16.0.vSpace,
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickActionCard(
                                  icon: Icons.trending_up,
                                  title: "Make Stake",
                                  subtitle: "Add money",
                                  color: Colors.green,
                                  onTap: _navigateToStaking,
                                ),
                              ),
                              12.0.hSpace,
                              Expanded(
                                child: _buildQuickActionCard(
                                  icon: Icons.trending_down,
                                  title: "Withdraw",
                                  subtitle: "Request funds",
                                  color: Colors.orange,
                                  onTap: _navigateToWithdrawalPage,
                                ),
                              ),
                              12.0.hSpace,
                              Expanded(
                                child: _buildQuickActionCard(
                                  icon: Icons.receipt_long,
                                  title: "Statement",
                                  subtitle: "View history",
                                  color: Colors.blue,
                                  onTap: () {
                                    _navigateToTransactionHistory();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    32.0.vSpace,
                    
                    // Accounts Section
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance, size: 24),
                              12.0.hSpace,
                              const Text(
                                "Accounts",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "${_accounts.length} account${_accounts.length != 1 ? 's' : ''}",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          16.0.vSpace,
                          
                          _isLoadingAccounts
                              ? const Center(child: CircularProgressIndicator())
                              : _accounts.isEmpty
                                  ? _buildEmptyState(
                                      icon: Icons.account_balance_outlined,
                                      title: "No Accounts",
                                      subtitle: "No accounts found for this customer",
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _accounts.length,
                                      separatorBuilder: (context, index) => 12.0.vSpace,
                                      itemBuilder: (context, index) {
                                        final account = _accounts[index];
                                        return _buildAccountCard(account);
                                      },
                                    ),
                                      20.0.vSpace,
                                    GestureDetector(
                                      onTap: () => AddAccountPopup.show(context, widget.customer?.uid ?? '', staff.id ?? '', staff.companyId ?? '', (){ _fetchAccounts(); }),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.add),
                                              const SizedBox(width: 8),
                                              const Text("Add Account"),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),

                              32.0.vSpace,
                    
                    // Transactions Section
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history, size: 24),
                              12.0.hSpace,
                              const Text(
                                "Recent Transactions",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  // View all transactions
                                },
                                child: const Text("View All"),
                              ),
                            ],
                          ),
                          16.0.vSpace,
                          
                          _isLoadingTransactions
                              ? const Center(child: CircularProgressIndicator())
                              : _transactions.isEmpty
                                  ? _buildEmptyState(
                                      icon: Icons.receipt_long_outlined,
                                      title: "No Transactions",
                                      subtitle: "No transactions found for this customer",
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _transactions.length > 5 ? 5 : _transactions.length,
                                      separatorBuilder: (context, index) => 12.0.vSpace,
                                      itemBuilder: (context, index) {
                                        final transaction = _transactions[index];
                                        return _buildTransactionCard(transaction);
                                      },
                                    ),
                        ],
                      ),
                    ),
                    
                    40.0.vSpace, // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            12.0.vSpace,
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            4.0.vSpace,
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account) {
    final balance = account['balance'] ?? 0.0;
    final accountType = account['account_type'] ?? 'Account';
    final accountNumber = account['account_number'] ?? account['id'] ?? 'Unknown';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors().primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: AppColors().primaryColor,
              size: 24,
            ),
          ),
          16.0.hSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accountType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                4.0.vSpace,
                Text(
                  "AC: $accountNumber",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "GHS $balance",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              4.0.vSpace,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Active",
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final amount = transaction["amount"] ?? 0;
    final status = transaction["status"]?.toString() ?? "unknown";
    final type = transaction["type"]?.toString() ?? "transaction";
    final date = transaction["created_at"] ?? transaction["transaction_date"];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors().primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getTransactionIcon(type),
              color: getIconColor(type),
              size: 20,
            ),
          ),
          12.0.hSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "GHS $amount",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                4.0.vSpace,
                Text(
                  type.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              6.0.vSpace,
              Text(
                formatDate(date),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[300],
          ),
          16.0.vSpace,
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          8.0.vSpace,
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }}