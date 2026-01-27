import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:susu_micro/extensions/spacing.dart';
import 'package:susu_micro/models/customer_model.dart';
import 'package:susu_micro/providers/next_account_number.dart';
import 'package:susu_micro/providers/staff_provider.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/helpers.dart';
import 'package:susu_micro/utils/text.dart';
import 'package:susu_micro/views/customers_page.dart';
import 'package:susu_micro/views/home_page.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CustomerRegistration extends StatefulWidget {
  const CustomerRegistration({super.key});

  @override
  State<CustomerRegistration> createState() => _CustomerRegistrationState();
}

class _CustomerRegistrationState extends State<CustomerRegistration>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _currentStep = 0;
  bool _isLoading = false;
  String _toBeUsedAccountNumber = '';

  // Form Keys
  final _stepOneFormKey = GlobalKey<FormState>();
  final _stepTwoFormKey = GlobalKey<FormState>();
  final _stepThreeFormKey = GlobalKey<FormState>();

  // Step 1 Controllers
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  String _selectedDate = '';

  // Step 2 Controllers
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _momoNumberController = TextEditingController();
  final _nextOfKinController = TextEditingController();
  String _selectedGender = '';
  String _selectedAccount = '';

  // Step 3 Controllers
  final _locationController = TextEditingController();
  final _areaController = TextEditingController();
  final _dailyRateController = TextEditingController();
  final _accountNumberController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    // Dispose all controllers
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nextOfKinController.dispose();
    _locationController.dispose();
    _areaController.dispose();
    _dailyRateController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      final staff = Provider.of<StaffProvider>(context, listen: false);
      if(_currentStep == 0){
        Provider.of<AccountNumberProvider>(context, listen: false).refreshAccountNumber(staff.id!);
      }
      if(_currentStep == 1){
        final nextAccountNumber = Provider.of<AccountNumberProvider>(context, listen: false).nextAccountNumber;
        if(nextAccountNumber != null){
          _accountNumberController.text = nextAccountNumber;
          setState(() {
            _toBeUsedAccountNumber = nextAccountNumber;
          });
        }
      }
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _stepOneFormKey.currentState?.validate() ?? false && _selectedDate.isNotEmpty;
      case 1:
        return _stepTwoFormKey.currentState?.validate() ?? false && _selectedGender.isNotEmpty;
      case 2:
        return _stepThreeFormKey.currentState?.validate() ?? false;
      default:
        return false;
    }
  }

  void _onDateSelection(DateRangePickerSelectionChangedArgs args) {
    final DateTime selectedDate = args.value;
    final String formattedDate = DateFormat('MMMM d, yyyy').format(selectedDate);
    setState(() {
      _selectedDate = formattedDate;
    });
    Navigator.pop(context);
  }
  
  Future<void> _submitCustomer() async {
    if (!_validateCurrentStep()) return;


    setState(() => _isLoading = true);
    
    final staff = Provider.of<StaffProvider>(context, listen: false);
    final customerData = {
      "name": _nameController.text.trim(),
      "id_card": _idController.text.trim(),
      "date_of_registration": DateTime.now().toIso8601String(),
      "gender": _selectedGender,
      "email": _emailController.text.trim(),
      "phone_number": _phoneController.text.trim(),
      "momo_number": _momoNumberController.text.trim(),
      "account_number": _accountNumberController.text.trim(),
      "next_of_kin": _nextOfKinController.text.trim(),
      "location": _locationController.text.trim(),
      "daily_rate": double.tryParse(_dailyRateController.text) ?? 0.0,
      "date_of_birth": _selectedDate,
      "company_id": staff.companyId,
      "registered_by": staff.id,
      "city": _areaController.text.trim()
    };

    logs.d("Selected account: $_selectedAccount");
    if(_selectedAccount.isNotEmpty){
      try {
      final response = await http.post(
        Uri.parse("https://susu-pro-backend.onrender.com/api/customers/create"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(customerData),
      );

      if (response.statusCode == 201) {
        final staff = Provider.of<StaffProvider>(context, listen: false);
        Provider.of<AccountNumberProvider>(context, listen: false).refreshAccountNumber(staff.id!);
        try {
          final newCustomerBody = jsonDecode(response.body);
          logs.d('New customer data $newCustomerBody');
          String accountNumberSuffix = '';
          if(_selectedAccount.toLowerCase() == 'susu'){
            accountNumberSuffix = 'SU1';
          } else if(_selectedAccount.toLowerCase() == 'savings'){
            accountNumberSuffix = 'SA1';
          }
          final accountData = {
            "customer_id": newCustomerBody['data']['id'],
            "account_type": _selectedAccount,
            "created_by": staff.id,
            "company_id": staff.companyId,
            "account_number": '$_toBeUsedAccountNumber$accountNumberSuffix',
          };

          final res = await http.post(
            Uri.parse('https://susu-pro-backend.onrender.com/api/accounts/create'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(accountData),
          );
          logs.d(response.body);
          logs.d(res.body);
          sendCustomerSmS(_phoneController.text.trim(), staff.companyName!, 
          generateUniqueCode(_phoneController.text.trim()),
          'Dear ${_nameController.text.trim()}, you have successfully opened a $_selectedAccount account with ${staff.companyName}. Your customer account number is, $_toBeUsedAccountNumber. \nYour secret withdrawal code is ${newCustomerBody['data']['withdrawal_code']}. Please do not share this code with anyone. \nThank you for choosing us!'
          );
        } catch (e) {
          logs.e('Error creating customer: $e');
        }
        if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 8),
          Text("Customer & Account created successfully!"),
        ],
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  // Instead of popping, go to Customers list/dashboard
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const HomePage()),
    (route) => false,
  );
}

      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed: ${response.body}"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select an account type."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors();
    
    return Scaffold(
      backgroundColor: colors.whiteColor,
      appBar: AppBar(
        backgroundColor: colors.whiteColor,
        elevation: 0,
        centerTitle: true,
        leading: _currentStep > 0 
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios, color: colors.primaryColor),
              onPressed: _previousStep,
            )
          : null,
        title: MyTexts().regularText(
          "New Customer",
          fontSize: 18,
          textColor: colors.primaryColor,
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(colors),
          
          // Content
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStepOne(colors),
                  _buildStepTwo(colors),
                  _buildStepThree(colors),
                ],
              ),
            ),
          ),
          
          // Bottom Actions
          _buildBottomActions(colors),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: List.generate(3, (index) {
          bool isActive = index <= _currentStep;
          bool isCurrent = index == _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? colors.primaryColor : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 2) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepOne(AppColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _stepOneFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              "Personal Information",
              "Let's start with the basic details",
              Icons.person_outline,
              colors,
            ),
            32.0.vSpace,
            
            _buildModernTextField(
              label: "Full Name",
              controller: _nameController,
              icon: Icons.person_outline,
              validator: (value) => value?.isEmpty ?? true ? "Full name is required" : null,
            ),
            24.0.vSpace,
            
            _buildDateSelector(colors),
            24.0.vSpace,
            
            _buildModernTextField(
              label: "ID Card Number",
              controller: _idController,
              icon: Icons.credit_card,
              validator: (value) => value?.isEmpty ?? true ? "ID card number is required" : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTwo(AppColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _stepTwoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              "Contact Details",
              "How can we reach them?",
              Icons.contact_phone,
              colors,
            ),
            32.0.vSpace,
            
            _buildGenderSelector(colors),
            24.0.vSpace,
            
            _buildModernTextField(
              label: "Email Address",
              controller: _emailController,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
             
            ),
            24.0.vSpace,
            
            _buildModernTextField(
              label: "Phone Number",
              controller: _phoneController,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) => value?.isEmpty ?? true ? "Phone number is required" : null,
            ),
            24.0.vSpace,

            _buildModernTextField(
              label: "Momo Number",
              controller: _momoNumberController,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) => value?.isEmpty ?? true ? "Momo number is required" : null,
            ),
            24.0.vSpace,
            
            _buildModernTextField(
              label: "Next of Kin",
              controller: _nextOfKinController,
              icon: Icons.family_restroom,
              validator: (value) => value?.isEmpty ?? true ? "Next of kin is required" : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepThree(AppColors colors) {
    final nextAccountNumber = Provider.of<AccountNumberProvider>(context).nextAccountNumber;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _stepThreeFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              "Location & Rate",
              "Final details to complete registration",
              Icons.location_on_outlined,
              colors,
            ),
            32.0.vSpace,
            
            _buildModernTextField(
              label: "Town/City",
              controller: _areaController,
              icon: Icons.map_outlined,
              validator: (value) => value?.isEmpty ?? true ? "Town/City is required" : null,
            ),
            24.0.vSpace,

            _buildModernTextField(
              label: "Location/Area",
              controller: _locationController,
              icon: Icons.location_on_outlined,
              validator: (value) => value?.isEmpty ?? true ? "Location is required" : null,
            ),
            24.0.vSpace,
            
            _buildModernTextField(
              label: "Daily Rate (₵)",
              controller: _dailyRateController,
              icon: Icons.monetization_on_outlined,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return "Daily rate is required";
                if (double.tryParse(value!) == null) return "Enter a valid amount";
                return null;
              },
            ),
            24.0.vSpace,
            _buildModernTextField(
              label: "Account Number",
              controller: nextAccountNumber != null ? TextEditingController(text: nextAccountNumber) : _accountNumberController,
              icon: Icons.account_box,
              validator: (value) {
                if (value?.isEmpty ?? true) return "Account number is required";
                return null;
              },
            ),
            32.0.vSpace,
            _buildAccountSelector(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle, IconData icon, AppColors colors) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colors.primaryColor, size: 24),
        ),
        16.0.hSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyTexts().regularText(
                title,
                fontSize: 20,
                textColor: Colors.black87,
              ),
              4.0.vSpace,
              MyTexts().regularText(
                subtitle,
                fontSize: 14,
                textColor: Colors.grey[600]!,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors().primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDateSelector(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Date of Birth",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        8.0.vSpace,
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => Container(
                height: 400,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    16.0.vSpace,
                    Text(
                      "Select Date of Birth",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.primaryColor,
                      ),
                    ),
                    16.0.vSpace,
                    Expanded(
                      child: SfDateRangePicker(
                        backgroundColor: Colors.white,
                        view: DateRangePickerView.decade,
                        onSelectionChanged: _onDateSelection,
                        selectionMode: DateRangePickerSelectionMode.single,
                        selectionColor: colors.primaryColor,
                        todayHighlightColor: colors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: _selectedDate.isEmpty ? Colors.grey[300]! : colors.primaryColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: Colors.grey[600]),
                12.0.hSpace,
                Text(
                  _selectedDate.isEmpty ? "Select Date of Birth" : _selectedDate,
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedDate.isEmpty ? Colors.grey[500] : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedDate.isEmpty && _stepOneFormKey.currentState?.validate() == false)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              "Date of birth is required",
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildGenderSelector(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gender",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        8.0.vSpace,
        Row(
          children: [
            Expanded(
              child: _buildGenderOption("Male", Icons.male, colors),
            ),
            16.0.hSpace,
            Expanded(
              child: _buildGenderOption("Female", Icons.female, colors),
            ),
          ],
        ),
      ],
    );
  }
  Widget _buildAccountSelector(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Account",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        8.0.vSpace,
        Row(
          children: [
            Expanded(
              child: _buildAccountOption("Susu", Icons.male, colors),
            ),
            16.0.hSpace,
            Expanded(
              child: _buildAccountOption("Savings", Icons.female, colors),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String gender, IconData icon, AppColors colors) {
    bool isSelected = _selectedGender == gender;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryColor.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? colors.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? colors.primaryColor : Colors.grey[600],
            ),
            8.0.hSpace,
            Text(
              gender,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? colors.primaryColor : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAccountOption(String account, IconData icon, AppColors colors) {
    bool isSelected = _selectedAccount == account;

    return GestureDetector(
      onTap: () => setState(() => _selectedAccount = account),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryColor.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? colors.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? colors.primaryColor : Colors.grey[600],
            ),
            8.0.hSpace,
            Text(
              account,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? colors.primaryColor : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: colors.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Previous",
                    style: TextStyle(
                      color: colors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) 16.0.hSpace,
            Expanded(
              flex: _currentStep == 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (_currentStep == 2 ? _submitCustomer : _nextStep),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == 2 ? "Create Customer" : "Next",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_currentStep < 2) ...[
                            8.0.hSpace,
                            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}