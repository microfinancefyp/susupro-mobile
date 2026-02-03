import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:susu_micro/extensions/spacing.dart';
import 'package:susu_micro/models/customer_model.dart';
import 'package:susu_micro/providers/staff_provider.dart';
import 'package:susu_micro/utils/appAssets.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/helpers.dart';
import 'package:susu_micro/utils/screen_measurement.dart';
import 'package:susu_micro/utils/text.dart';

class StakingPage extends StatefulWidget {
  final String customerName;
  final CustomerModel customer;

  const StakingPage({
    super.key,
    required this.customerName,
    required this.customer,
  });

  @override
  State<StakingPage> createState() => _StakingPageState();
}

class _StakingPageState extends State<StakingPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();

  String? _selectedAccountId;
  String? _selectedAccountType;
  String? _selectedAccountBalance;
  String? _selectedAccountNumber;
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingAccounts = true;
  bool _isLoadingTransactions = true;
  bool _isStaking = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _fetchAccounts();
    _fetchTransactions();
    _animationController.forward();
  }

  Future<void> _fetchAccounts() async {
    try {
      final response = await http.get(
        Uri.parse("https://susu-pro-backend.onrender.com/api/accounts/customer/${widget.customer.uid}"),
      );
      if (response.statusCode == 200) {
        logs.d('Accounts');
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded['data'];
        logs.d("Accounts: $data");
        setState(() {
          _accounts = List<Map<String, dynamic>>.from(data);
          _isLoadingAccounts = false;
        });
      } 
    } catch (e) {
      setState(() => _isLoadingAccounts = false);
    }
  }

  Future<void> _fetchTransactions() async {
    try {
      logs.d(widget.customer.uid);
      final response = await http.get(
        Uri.parse("https://susu-pro-backend.onrender.com/api/transactions/customer/${widget.customer.uid}"),
      );
      logs.d(response.body);

      if (response.statusCode == 200) {
        logs.d(true);
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> data = decoded["data"];

        setState(() {
          _transactions = List<Map<String, dynamic>>.from(data);
          _isLoadingTransactions = false;
        });

        logs.d("Transactions: $_transactions");
      } else {
        setState(() => _isLoadingTransactions = false);
      }
    } catch (e, st) {
      logs.e("Error fetching transactions, $e, $st");
      setState(() => _isLoadingTransactions = false);
    }
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
            "body": "An amount of GHC${_amountController.text.trim()}.00 has been deposited for ${widget.customerName}.",
            "data": {}
          }),
      );
      logs.d("Response: ${response.body}");
    } catch (e) {
      logs.d(e);
    }
  }


  Future<void> _submitStake() async {
    final staff = Provider.of<StaffProvider>(context, listen: false);
    if (_formKey.currentState!.validate() && _selectedAccountId != null) {
      setState(() => _isStaking = true);
      
      // Add haptic feedback
      HapticFeedback.lightImpact();

      logs.d("Staff id: ${staff.staffId}");
      
      final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
      final data = {
        "account_id": _selectedAccountId,
        "amount": amount,
        "transaction_type": "deposit",
        "staked_by": staff.id,
        "company_id": staff.companyId,
        "staff_id": staff.id
      };
      logs.d(data);
      
      try {
        final response = await http.post(
          Uri.parse("https://susu-pro-backend.onrender.com/api/transactions/stake"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(data),
        );
        
        if (response.statusCode == 200) {
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  12.0.hSpace,
                  Expanded(
                    child: Text("Successfully staked GHS $amount for ${widget.customerName}"),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          sendMessageToOffice();
          
          await _fetchAccounts();
          final selectedAccount = _accounts.firstWhere(
            (acc) => acc['id'] == _selectedAccountId,
            orElse: () => {},
          );
          final balance = selectedAccount['balance'] ?? 0.0;
          _fetchTransactions();
          final String message = "You have successfully credited your ${selectedAccount['account_type']} account with GHS${_amountController.text}.00. Your new balance is GHS$balance";
          _amountController.clear();
          sendCustomerSmS(widget.customer.phoneNumber!, staff.companyName!, generateUniqueCode(widget.customer.phoneNumber!), 
            message
          );
          setState(() => _selectedAccountId = null);
        } else {
          _showErrorSnackBar("Failed to stake. Please try again.");
        }
      } catch (e) {
        _showErrorSnackBar("Error connecting to server");
      }
      
      setState(() => _isStaking = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            12.0.hSpace,
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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

  @override
  void dispose() {
    _amountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar
          SliverAppBar(
            expandedHeight: 280.0,
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
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      60.0.vSpace, // Account for status bar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 46,
                            child: Center(child: Text(widget.customerName.isNotEmpty ? widget.customerName[0].toUpperCase() : "U", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ),
                      16.0.vSpace,
                      Text(
                        widget.customerName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      8.0.vSpace,
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: SelectableText(
                          widget.customer.phoneNumber ?? "No phone available",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            title: const Text(
              "Staking",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  20.0.vSpace,
                  
                  // Staking Form Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: AppColors().primaryColor,
                                size: 28,
                              ),
                              12.0.hSpace,
                              const Text(
                                "Make a Stake",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          24.0.vSpace,
                          
                          const Text(
                            "Select Account",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          12.0.vSpace,
                          
                          _isLoadingAccounts
                              ? Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 255, 255, 255),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(child: CircularProgressIndicator()),
                                )
                              : DropdownButtonFormField<String>(
                                  dropdownColor: Colors.white,
                                  value: _selectedAccountId,
                                  items: _accounts.map((acc) {
                                    return DropdownMenuItem<String>(
                                      value: acc["id"] as String,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: AppColors().primaryColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Icon(
                                                Icons.account_balance,
                                                color: AppColors().primaryColor,
                                                size: 16,
                                              ),
                                            ),
                                            Flexible(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      5.0.hSpace,
                                                      Text(
                                                        acc["account_type"] ?? "Account",
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 14,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      7.0.hSpace,
                                                      Text(
                                                        "Balance: GHS ${(acc["balance"] ?? 0)}",
                                                        style: TextStyle(
                                                          color: Colors.grey[600],
                                                          fontSize: 12,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                   Text(
                                                        "AC NO: ${(acc["account_number"] ?? "N/A")}",
                                                        style: TextStyle(
                                                          color: Colors.grey[600],
                                                          fontSize: 12,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  selectedItemBuilder: (BuildContext context) {
                                    return _accounts.map((acc) {
                                      return Text(
                                        "${acc["account_type"]} - AC NO: ${(acc["account_number"] ?? "N/A")}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    }).toList();
                                  },
                                  onChanged: (val) => setState(() {
                                    _selectedAccountId = val;
                                    _selectedAccountType = _accounts.firstWhere((acc) => acc['id'] == val, orElse: () => {})['account_type'];
                                    _selectedAccountBalance = _accounts.firstWhere((acc) => acc['id'] == val, orElse: () => {})['balance'].toString();
                                    _selectedAccountNumber = _accounts.firstWhere((acc) => acc['id'] == val, orElse: () => {})['account_number'].toString();
                                  }),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    hintText: "Choose an account",
                                    hintStyle: TextStyle(color: Colors.grey[500]),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: Colors.grey[200]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: Colors.grey[200]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: AppColors().primaryColor),
                                    ),
                                  ),
                                  validator: (val) => val == null ? "Please select an account" : null,
                                ),
                          
                          24.0.vSpace,
                         _selectedAccountId != null ?  Text(
                            "Selected Account: $_selectedAccountType\nAccount Number: $_selectedAccountNumber\nCurrent Balance: GHS $_selectedAccountBalance",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ) : Container(),
                          _selectedAccountId != null ? 24.0.vSpace : Container(),
                          const Text(
                            "Amount to Stake",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          12.0.vSpace,
                          
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              hintText: "0.00",
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 16, top: 20),
                                child: Text(
                                  "GHS",
                                  style: TextStyle(
                                    color: AppColors().primaryColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey[200]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey[200]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppColors().primaryColor),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return "Please enter an amount";
                              if (double.tryParse(val) == null) return "Please enter a valid number";
                              if (double.parse(val) <= 0) return "Amount must be greater than 0";
                              return null;
                            },
                          ),
                          
                          32.0.vSpace,
                          
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isStaking ? null : _submitStake,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors().primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                disabledBackgroundColor: Colors.grey[300],
                              ),
                              child: _isStaking
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text("Processing..."),
                                      ],
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.rocket_launch, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          "Stake Now",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  32.0.vSpace,
                  
                  // Recent Transactions Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.history,
                              color: AppColors().primaryColor,
                              size: 24,
                            ),
                            12.0.hSpace,
                            const Text(
                              "Recent Transactions",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        16.0.vSpace,
                        
                        _isLoadingTransactions
                            ? Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(child: CircularProgressIndicator()),
                              )
                            : _transactions.isEmpty
                                ? Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(40),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.receipt_long_outlined,
                                          size: 64,
                                          color: Colors.grey[300],
                                        ),
                                        16.0.vSpace,
                                        Text(
                                          "No transactions yet",
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        8.0.vSpace,
                                        Text(
                                          "Your transaction history will appear here",
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _transactions.length > 10 ? 10 : _transactions.length,
                                    separatorBuilder: (context, index) => 12.0.vSpace,
                                    itemBuilder: (context, index) {
                                      final tx = _transactions[index];
                                      final amount = tx["amount"] ?? 0;
                                      final status = tx["status"]?.toString() ?? "unknown";
                                      final type = tx["type"]?.toString() ?? "transaction";
                                      final date = tx["created_at"] ?? tx["transaction_date"];
                                      
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
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: AppColors().primaryColor.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(
                                                    _getTransactionIcon(type),
                                                    color: getIconColor(type),
                                                    size: 24,
                                                  ),
                                                ),
                                                16.0.hSpace,
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        "GHS $amount",
                                                        style: const TextStyle(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      4.0.vSpace,
                                                      Text(
                                                        type.toUpperCase(),
                                                        style: TextStyle(
                                                          color: Colors.grey[600],
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: getStatusColor(status).withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: Text(
                                                        status.toUpperCase(),
                                                        style: TextStyle(
                                                          color: getStatusColor(status),
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    8.0.vSpace,
                                                    Text(
                                                      formatDate(date),
                                                      style: TextStyle(
                                                        color: Colors.grey[500],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            
                                            // Additional transaction details
                                            if (tx["reference"] != null || tx["description"] != null) ...[
                                              16.0.vSpace,
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[50],
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  children: [
                                                    if (tx["reference"] != null) ...[
                                                      Row(
                                                        children: [
                                                          Icon(Icons.receipt, size: 16, color: Colors.grey[600]),
                                                          8.0.hSpace,
                                                          Text(
                                                            "Reference: ",
                                                            style: TextStyle(
                                                              color: Colors.grey[600],
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              tx["reference"].toString(),
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.w400,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                    if (tx["description"] != null && tx["reference"] != null) 4.0.vSpace,
                                                    if (tx["description"] != null) ...[
                                                      Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                                                          8.0.hSpace,
                                                          Expanded(
                                                            child: Text(
                                                              tx["description"].toString(),
                                                              style: TextStyle(
                                                                color: Colors.grey[700],
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
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
        ],
      ),
    );
  }
}