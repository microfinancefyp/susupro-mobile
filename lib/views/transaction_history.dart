import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:susu_micro/extensions/spacing.dart';
import 'package:susu_micro/models/customer_model.dart';
import 'package:susu_micro/models/transaction_model.dart';
import 'package:susu_micro/providers/staff_provider.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TransactionHistoryPage extends StatefulWidget {
  final CustomerModel customer;

  const TransactionHistoryPage({
    super.key,
    required this.customer,
  });

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  final List<FilterOption> _filterOptions = [
    FilterOption('all', 'All Time', Icons.history),
    FilterOption('today', 'Today', Icons.today),
    FilterOption('yesterday', 'Yesterday', Icons.calendar_today),
    FilterOption('week', 'This Week', Icons.date_range),
    FilterOption('month', 'This Month', Icons.calendar_month),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchTransactions();
    _searchController.addListener(_onSearchChanged);
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    
    try {
      final staff = Provider.of<StaffProvider>(context, listen: false);
      final response = await http.get(
        Uri.parse('https://susu-pro-backend.onrender.com/api/transactions/customer/${widget.customer.uid}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success') {
          final transactionList = data['data'] as List;
          _transactions = transactionList
              .map((json) => Transaction.fromJson(json))
              .toList();
          
          // Sort by transaction date (newest first)
          _transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
          
          _filteredTransactions = List.from(_transactions);
          _animationController.forward();
        } else {
          _showErrorSnackBar('Failed to load transactions');
        }
      } else {
        _showErrorSnackBar('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar("Failed to fetch transactions: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    _applyFilters();
  }

  void _applyFilters() {
    List<Transaction> filtered = List.from(_transactions);

    // Apply date filter
    if (_selectedFilter != 'all') {
      final now = DateTime.now();
      filtered = filtered.where((transaction) {
        switch (_selectedFilter) {
          case 'today':
            return _isSameDay(transaction.transactionDate, now);
          case 'yesterday':
            return _isSameDay(transaction.transactionDate, now.subtract(const Duration(days: 1)));
          case 'week':
            return transaction.transactionDate.isAfter(now.subtract(const Duration(days: 7)));
          case 'month':
            return transaction.transactionDate.month == now.month && 
                   transaction.transactionDate.year == now.year;
          default:
            return true;
        }
      }).toList();
    }

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((transaction) {
        return (transaction.description?.toLowerCase().contains(searchTerm) ?? false) ||
               transaction.type.toLowerCase().contains(searchTerm) ||
               transaction.amount.toString().contains(searchTerm) ||
               transaction.status.toLowerCase().contains(searchTerm) ||
               (transaction.uniqueCode?.toLowerCase().contains(searchTerm) ?? false);
      }).toList();
    }

    setState(() => _filteredTransactions = filtered);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            8.0.hSpace,
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors();
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(colors),
          if (_isLoading)
            _buildLoadingSliver()
          else ...[
            _buildStatsCard(colors),
            _buildFilterSection(colors),
            _buildTransactionsList(colors),
          ],
        ],
      ),
      floatingActionButton: !_isLoading ? FloatingActionButton(
        onPressed: _fetchTransactions,
        backgroundColor: colors.primaryColor,
        child: const Icon(Icons.refresh, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildSliverAppBar(AppColors colors) {
    return SliverAppBar(
      expandedHeight: 120,
      iconTheme: IconThemeData(color: Colors.white),
      pinned: true,
      backgroundColor: colors.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primaryColor,
                colors.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          widget.customer.fullName?.substring(0, 2).toUpperCase() ?? 'NA',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      16.0.hSpace,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.customer.fullName ?? 'Unknown Customer',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            4.0.vSpace,
                            Text(
                              'Transaction History',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
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
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(AppColors colors) {
    final totalDeposits = _transactions
        .where((t) => t.type.toLowerCase() == 'deposit' && t.status.toLowerCase() == 'completed')
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalWithdrawals = _transactions
        .where((t) => t.type.toLowerCase() == 'withdrawal' && t.status.toLowerCase() == 'approved')
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final balance = totalDeposits - totalWithdrawals;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem('Balance', '₵${balance.toStringAsFixed(2)}', Colors.blue, Icons.account_balance_wallet),
              ),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              Expanded(
                child: _buildStatItem('Deposits', '₵${totalDeposits.toStringAsFixed(2)}', Colors.green, Icons.arrow_upward),
              ),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              Expanded(
                child: _buildStatItem('Withdrawals', '₵${totalWithdrawals.toStringAsFixed(2)}', Colors.red, Icons.arrow_downward),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        4.0.vSpace,
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        4.0.vSpace,
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(AppColors colors) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildSearchBar(colors),
          20.0.vSpace,
          _buildFilterChips(colors),
          16.0.vSpace,
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search transactions...',
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilterChips(AppColors colors) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final isSelected = _selectedFilter == option.value;
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    option.icon,
                    size: 16,
                    color: isSelected ? Colors.white : colors.primaryColor,
                  ),
                  8.0.hSpace,
                  Text(option.label),
                ],
              ),
              onSelected: (_) => _onFilterChanged(option.value),
              backgroundColor: Colors.white,
              selectedColor: colors.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : colors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(color: colors.primaryColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionsList(AppColors colors) {
    if (_filteredTransactions.isEmpty) {
      return _buildEmptyState(colors);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  index == 0 ? 8 : 4,
                  24,
                  index == _filteredTransactions.length - 1 ? 100 : 4,
                ),
                child: _buildTransactionCard(_filteredTransactions[index], colors),
              ),
            ),
          );
        },
        childCount: _filteredTransactions.length,
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction, AppColors colors) {
    final isDeposit = transaction.type.toLowerCase() == 'deposit';
    final statusColor = _getStatusColor(transaction.status);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDeposit ? Colors.green : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDeposit ? Icons.add : Icons.remove,
                color: isDeposit ? Colors.green : Colors.red,
                size: 24,
              ),
            ),
            16.0.hSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text( 
                    '${transaction.type[0].toUpperCase()}${transaction.type.substring(1).toLowerCase()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  4.0.vSpace,
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      4.0.hSpace,
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.transactionDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (transaction.uniqueCode != null) ...[
                    4.0.vSpace,
                    Text(
                      'Code: ${transaction.uniqueCode}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isDeposit ? '+' : '-'}₵${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDeposit ? Colors.green : Colors.red,
                  ),
                ),
                4.0.vSpace,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    transaction.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSliver() {
    return SliverFillRemaining(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors().primaryColor),
          20.0.vSpace,
          const Text(
            'Loading transactions...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return SliverFillRemaining(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey[400],
          ),
          20.0.vSpace,
          const Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          8.0.vSpace,
          Text(
            _searchController.text.isNotEmpty || _selectedFilter != 'all'
                ? 'Try adjusting your filters'
                : 'No transaction history available',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          24.0.vSpace,
          if (_searchController.text.isNotEmpty || _selectedFilter != 'all')
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _onFilterChanged('all');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Clear Filters',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

