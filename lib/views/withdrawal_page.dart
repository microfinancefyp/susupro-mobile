import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:susu_micro/models/customer_model.dart';
import 'package:susu_micro/providers/staff_provider.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/helpers.dart';

class WithdrawPage extends StatefulWidget {
  final CustomerModel customer;
  final String customerName;
  final List<Map<String, dynamic>> accounts;
  
  const WithdrawPage({
    Key? key,
    required this.customer,
    required this.customerName,
    required this.accounts,
  }) : super(key: key);

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  String? _selectedAccountId;
  bool _isSubmitting = false;
  double _balance = 0.0;
  Map<String, dynamic>? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideController.forward();
    _fadeController.forward();

    logs.d('${widget.customer.phoneNumber}');
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(locale: "en_GH", symbol: "₵");
    return formatter.format(value);
  }






Future<void> _submitWithdraw() async {
  final staff = Provider.of<StaffProvider>(context, listen: false);
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isSubmitting = true);
  HapticFeedback.lightImpact();

  // ✅ Generate unique code
      final uniqueCode = generateUniqueCode(widget.customer.phoneNumber!);

  try {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final body = {
      "account_id": _selectedAccountId,
      "amount": amount,
      "transaction_type": "withdrawal",
      "staked_by": staff.id,
      "company_id": staff.companyId,
      "unique_code": uniqueCode,
    };

    final response = await http.post(
      Uri.parse("https://susu-pro-backend.onrender.com/api/transactions/stake"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    logs.d('Transaction return data: $data');

    if (response.statusCode == 201 || response.statusCode == 200) {
      

      // ✅ Send message to customer with code
      final messageBody = {
        "messageTo": widget.customer.phoneNumber,
        "message": "Your withdrawal request of GHS${_amountController.text}.00 has been submitted. Use this code to confirm at the office: $uniqueCode",
        "messageFrom": makeSuSuProName(staff.companyName),
      };
      final msgRes = await http.post(
        Uri.parse("https://susu-pro-backend.onrender.com/api/messages/send-customer"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(messageBody),
      );
      if (msgRes.statusCode == 200 || msgRes.statusCode == 201) {
        logs.d("Message sent successfully: ${msgRes.body}");
      } else {
        logs.e("Failed to send message: ${msgRes.body}");
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        _showSuccessDialog();
      }
    } else {
      throw data["message"] ?? "Failed to submit request";
    }
  } catch (e) {
    if (mounted) {
      HapticFeedback.heavyImpact();
      _showErrorSnackbar("Error: $e");
    }
  } finally {
    if (mounted) setState(() => _isSubmitting = false);
  }
}

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Success!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your withdrawal request has been submitted successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors().primaryColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          ),
        ),
        title: const Text(
          'Withdrawal Request',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Info
                      _buildGlassCard(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors().primaryColor,
                                        AppColors().primaryColor.withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Customer',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.customerName,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Balance Card
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        child: _buildGlassCard(
                          child: Container(
                            decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                const Text(
                                  'Available Balance',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: _balance),
                                  duration: const Duration(milliseconds: 1200),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) => Text(
                                    _formatCurrency(value),
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors().primaryColor,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                if (_selectedAccount != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors().primaryColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _selectedAccount!['account_type'] ?? 'Account',
                                      style: TextStyle(
                                        color: AppColors().primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Account Selection
                      const Text(
                        'Select Account',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGlassCard(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: DropdownButtonFormField<String>(
                            value: _selectedAccountId,
                            dropdownColor: Colors.grey[50],
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Choose an account',
                              hintStyle: TextStyle(color: Colors.black54),
                            ),
                            style: const TextStyle(color: Colors.black, fontSize: 16),
                            items: widget.accounts.map((acc) {
                              return DropdownMenuItem<String>(
                                value: acc["id"] as String,
                                child: Text(
                                  "${acc["account_type"]} • ${_formatCurrency(double.tryParse(acc["balance"].toString()) ?? 0.0)}",
                                  style: const TextStyle(color: Colors.black),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedAccountId = val;
                                _selectedAccount = widget.accounts.firstWhere(
                                  (acc) => acc["id"] == val,
                                  orElse: () => {"balance": "0"},
                                );
                                _balance = double.tryParse(
                                    _selectedAccount!["balance"].toString()) ?? 0.0;
                              });
                              HapticFeedback.selectionClick();
                            },
                            validator: (val) =>
                                val == null ? "Please select an account" : null,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Amount Input
                      const Text(
                        'Withdrawal Amount',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGlassCard(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(20),
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                color: Colors.black.withOpacity(0.5),
                                fontSize: 18,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors().primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '₵',
                                  style: TextStyle(
                                    color: AppColors().primaryColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            validator: (val) {
                              final amount = double.tryParse(val ?? "") ?? 0.0;
                              if (amount <= 0) return "Enter a valid amount";
                              if (amount > _balance) return "Insufficient balance";
                              return null;
                            },
                            onChanged: (value) {
                              HapticFeedback.selectionClick();
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitWithdraw,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors().primaryColor,
                            disabledBackgroundColor: Colors.grey.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      'Processing...',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.account_balance_wallet,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Request Withdrawal',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}