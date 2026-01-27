import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:susu_micro/extensions/spacing.dart';
import 'package:susu_micro/models/customer_model.dart';
import 'package:susu_micro/providers/customer_provider.dart';
import 'package:susu_micro/providers/staff_provider.dart';
import 'package:susu_micro/services/customer_services.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/helpers.dart';
import 'package:susu_micro/utils/text.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class CustomerProfile extends StatefulWidget {
  final CustomerModel? customer;
  
  const CustomerProfile({
    super.key,
    this.customer,
  });

  @override
  State<CustomerProfile> createState() => _CustomerProfileState();
}

class _CustomerProfileState extends State<CustomerProfile>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isEditing = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers for editing
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _nokController;
  late TextEditingController _dailyRateController;
  late TextEditingController _locationController;
  
  String _selectedGender = 'female';
  String _selectedDob = '';

  late CustomerModel _currentCustomer;
  
  @override
  void initState() {
    super.initState();

    getCustomer();
    _setupAnimations();
    _initializeControllers();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: _currentCustomer.fullName ?? '');
    _phoneController = TextEditingController(text: _currentCustomer.phoneNumber ?? '');
    _nokController = TextEditingController(text: _currentCustomer.nextOfKin ?? '');
    _dailyRateController = TextEditingController(text: _currentCustomer.dailyRate ?? '');
    _locationController = TextEditingController(text: _currentCustomer.location ?? '');
    _selectedGender = _currentCustomer.gender?.toLowerCase() ?? 'female';
    _selectedDob = _currentCustomer.dob ?? '';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _nokController.dispose();
    _dailyRateController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset values if canceling edit
        _initializeControllers();
      }
    });
  }

  void getCustomer() async {
    final customer = Provider.of<CustomerProvider>(context, listen: false);
    _currentCustomer = customer.getCustomerById(widget.customer?.uid ?? '')!;
  }

  Future<void> _saveChanges() async {
    final provider = Provider.of<CustomerProvider>(context, listen: false);
    provider.setLoading(true);
    final staff = Provider.of<StaffProvider>(context, listen: false);

  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final body = {
      "id": widget.customer?.uid ?? '',
      "name": _nameController.text.trim(),
      "phone_number": _phoneController.text.trim(),
      "next_of_kin": _nokController.text.trim(),
      "daily_rate": _dailyRateController.text.trim(),
      "location": _locationController.text.trim(),
      "gender": _selectedGender,
      "date_of_birth": _selectedDob,
    };
    final response = await http.put(
      Uri.parse("https://susu-pro-backend.onrender.com/api/customers/update-mobile"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final updatedCustomer = CustomerModel.fromJson(data);

  
      Provider.of<CustomerProvider>(context, listen: false)
          .updateCustomer(updatedCustomer);
          final customers = await CustomerService.fetchCustomers(staff.id ?? '');
          provider.setCustomers(customers);
      getCustomer();
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      _showSuccessSnackBar("Customer details updated successfully!");
    } else {
      logs.d(response.body);
      setState(() => _isLoading = false);
      _showErrorSnackBar("Failed to update customer");
    }
  } catch (e) {
    setState(() => _isLoading = false);
    _showErrorSnackBar("Error: $e");
  }
}


  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            8.0.hSpace,
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildProfileContent(colors),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(AppColors colors) {
    return SliverAppBar(
      iconTheme: IconThemeData(color: Colors.white),
      expandedHeight: 280,
      pinned: true,
      backgroundColor: colors.primaryColor,
      actions: [
        if (!_isEditing)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _toggleEdit,
          )
        else ...[
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _toggleEdit,
          ),
        ],
      ],
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                60.0.vSpace, // Space for app bar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        child: Text(
                          widget.customer?.fullName?.substring(0, 2).toUpperCase() ?? 'NA',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: colors.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: colors.primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                16.0.vSpace,
                Text(
                  widget.customer?.fullName ?? 'Unknown Customer',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                4.0.vSpace,
                Text(
                  widget.customer?.email ?? 'No email provided',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(AppColors colors) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildInfoCard(colors),
            20.0.vSpace,
            _buildContactCard(colors),
            20.0.vSpace,
            _buildAccountCard(colors),
            if (_isEditing) ...[
              20.0.vSpace,
              _buildActionButtons(colors),
            ],
            100.0.vSpace, // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: colors.primaryColor),
              12.0.hSpace,
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.primaryColor,
                ),
              ),
            ],
          ),
          20.0.vSpace,
          
          _isEditing
              ? _buildEditableField(
                  'Full Name',
                  _nameController,
                  Icons.person_outline,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Name is required' : null,
                )
              : _buildInfoRow('Full Name', widget.customer?.fullName ?? 'N/A', Icons.person_outline),
          
          16.0.vSpace,
          
          _isEditing
              ? _buildGenderSelector(colors)
              : _buildInfoRow('Gender', widget.customer?.gender ?? 'N/A', Icons.wc),
          
          16.0.vSpace,
          
          _isEditing
              ? _buildDateSelector(colors)
              : _buildInfoRow('Date of Birth', formatDate(widget.customer?.dob) ?? 'N/A', Icons.calendar_today),
          
          16.0.vSpace,
          
          _buildInfoRow('ID Card', widget.customer?.idCard ?? 'N/A', Icons.credit_card),
        ],
      ),
    );
  }

  Widget _buildContactCard(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_phone, color: colors.primaryColor),
              12.0.hSpace,
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.primaryColor,
                ),
              ),
            ],
          ),
          20.0.vSpace,
          
          _isEditing
              ? _buildEditableField(
                  'Phone Number',
                  _phoneController,
                  Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Phone number is required' : null,
                )
              : _buildInfoRow('Phone', widget.customer?.phoneNumber ?? 'N/A', Icons.phone),
          
          16.0.vSpace,
          
          _buildInfoRow('Email', widget.customer?.email ?? 'N/A', Icons.email),
          
          16.0.vSpace,
          
          _isEditing
              ? _buildEditableField(
                  'Next of Kin',
                  _nokController,
                  Icons.family_restroom,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Next of kin is required' : null,
                )
              : _buildInfoRow('Next of Kin', widget.customer?.nextOfKin ?? 'N/A', Icons.family_restroom),
          
          16.0.vSpace,
          
          _isEditing
              ? _buildEditableField(
                  'Location',
                  _locationController,
                  Icons.location_on,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Location is required' : null,
                )
              : _buildInfoRow('Location', widget.customer?.location ?? 'N/A', Icons.location_on),
        ],
      ),
    );
  }

  Widget _buildAccountCard(AppColors colors) {
    final registrationDate = DateFormat('MMM dd, yyyy').format(DateTime.now().subtract(const Duration(days: 30)));
    
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: colors.primaryColor),
              12.0.hSpace,
              Text(
                'Account Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.primaryColor,
                ),
              ),
            ],
          ),
          20.0.vSpace,
          
          _buildInfoRow('Registration Date', formatDate(widget.customer?.dateOfRegistration) ?? 'N/A', Icons.event),
          
          16.0.vSpace,
          
          _isEditing
              ? _buildEditableField(
                  'Daily Rate (₵)',
                  _dailyRateController,
                  Icons.monetization_on,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Daily rate is required';
                    if (double.tryParse(value!) == null) return 'Enter valid amount';
                    return null;
                  },
                )
              : _buildInfoRow('Daily Rate', '₵${widget.customer?.dailyRate ?? '0.00'}', Icons.monetization_on),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        12.0.hSpace,
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
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
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildGenderSelector(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        8.0.vSpace,
        Row(
          children: [
            Expanded(
              child: _buildGenderOption('Male', Icons.male, colors),
            ),
            16.0.hSpace,
            Expanded(
              child: _buildGenderOption('Female', Icons.female, colors),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String gender, IconData icon, AppColors colors) {
    final isSelected = _selectedGender == gender.toLowerCase();
    
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender.toLowerCase()),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryColor.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? colors.primaryColor : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? colors.primaryColor : Colors.grey[600],
              size: 18,
            ),
            8.0.hSpace,
            Text(
              gender,
              style: TextStyle(
                color: isSelected ? colors.primaryColor : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    16.0.vSpace,
                    Text(
                      'Select Date of Birth',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.primaryColor,
                      ),
                    ),
                    16.0.vSpace,
                    Expanded(
                      child: SfDateRangePicker(
                        view: DateRangePickerView.decade,
                        onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                          final DateTime selectedDate = args.value;
                          setState(() {
                            _selectedDob = DateFormat('MMMM d, yyyy').format(selectedDate);
                          });
                          Navigator.pop(context);
                        },
                        selectionMode: DateRangePickerSelectionMode.single,
                        selectionColor: colors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600], size: 18),
                12.0.hSpace,
                Text(
                  _selectedDob.isEmpty ? 'Select Date of Birth' : _selectedDob,
                  style: TextStyle(
                    color: _selectedDob.isEmpty ? Colors.grey[500] : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppColors colors) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : _toggleEdit,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        16.0.hSpace,
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                : const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}