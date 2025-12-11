// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:susu_micro/extensions/spacing.dart';
// import 'package:susu_micro/models/customer_model.dart';
// import 'package:susu_micro/route_transitions/route_transition_fade.dart';
// import 'package:susu_micro/utils/colors.dart';
// import 'package:susu_micro/utils/text.dart';
// import 'package:susu_micro/views/new_customer_two.dart';
// import 'package:susu_micro/widgets/page_indicator.dart';
// import 'package:susu_micro/widgets/textfomrfield.dart';
// import 'package:syncfusion_flutter_datepicker/datepicker.dart';

// class NewCustomerPageOne extends StatefulWidget {
//   const NewCustomerPageOne({super.key});

//   @override
//   State<NewCustomerPageOne> createState() => _NewCustomerPageOneState();
// }

// class _NewCustomerPageOneState extends State<NewCustomerPageOne> {
//   TextEditingController customerName = TextEditingController();
//   TextEditingController customerID = TextEditingController();

//   final _formKey = GlobalKey<FormState>();
//   String _selectedDate = '';
//   bool isValidated = false;

//   void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
//     final DateTime selectedDate = args.value;
//     final String formattedDate =
//         DateFormat('MMMM d, yyyy').format(selectedDate);
//     setState(() {
//       _selectedDate = formattedDate;
//       _validateForm();
//     });
//   }

//   void _validateForm() {
//     bool isFormValid = _formKey.currentState?.validate() ?? false;
//     bool isDateSelected = _selectedDate.isNotEmpty;
//     setState(() {
//       isValidated = isFormValid && isDateSelected;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors();

//     return Scaffold(
//       backgroundColor: colors.whiteColor,
//       appBar: AppBar(
//         backgroundColor: colors.whiteColor,
//         elevation: 0,
//         centerTitle: true,
//         iconTheme: IconThemeData(color: colors.primaryColor),
//         title: MyTexts().regularText(
//           "New Customer",
//           fontSize: 18,
//           textColor: colors.primaryColor,
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 24.0),
//         child: SingleChildScrollView(
//           child: Form(
//             key: _formKey,
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 10.0.vSpace,
//                 PageIndicator(selectedIndex: 1),
//                 30.0.vSpace,

//                 /// Title
//                 MyTexts().regularText(
//                   "Add a new customer",
//                   fontSize: 22,
//                   textColor: Colors.black87,
//                 ),
//                 8.0.vSpace,
//                 MyTexts().regularText(
//                   "Fill in the basic details to create a new customer profile.",
//                   fontSize: 14,
//                   textColor: Colors.grey[600]!,
//                 ),
//                 30.0.vSpace,

//                 /// Name Field
//                 MyTextFields().buildTextField(
//                   "Full Name",
//                   customerName,
//                   context,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Customer name is required";
//                     }
//                     return null;
//                   },
//                   onChanged: (value) => _validateForm(),
//                 ),
//                 20.0.vSpace,

//                 /// Date of Birth Picker
//                 MyTexts().regularText("Date of Birth",
//                     fontSize: 14, textColor: Colors.grey[800]!),
//                 10.0.vSpace,
//                 GestureDetector(
//                   onTap: () {
//                     showModalBottomSheet(
//                       context: context,
//                       backgroundColor: Colors.white,
//                       shape: const RoundedRectangleBorder(
//                         borderRadius:
//                             BorderRadius.vertical(top: Radius.circular(24)),
//                       ),
//                       builder: (_) => SizedBox(
//                         height: 400,
//                         child: SfDateRangePicker(
//                           view: DateRangePickerView.decade,
//                           onSelectionChanged: _onSelectionChanged,
//                           selectionMode:
//                               DateRangePickerSelectionMode.single,
//                         ),
//                       ),
//                     );
//                   },
//                   child: Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.symmetric(
//                         vertical: 16, horizontal: 14),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[50],
//                       border: Border.all(color: Colors.grey[300]!),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       _selectedDate.isEmpty
//                           ? "Select Date of Birth"
//                           : _selectedDate,
//                       style: TextStyle(
//                         fontSize: 15,
//                         color: _selectedDate.isEmpty
//                             ? Colors.grey[500]
//                             : Colors.black87,
//                       ),
//                     ),
//                   ),
//                 ),
//                 20.0.vSpace,

//                 /// ID Field
//                 MyTextFields().buildTextField(
//                   "ID Card Number",
//                   customerID,
//                   context,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "ID Card is required";
//                     }
//                     return null;
//                   },
//                   onChanged: (value) => _validateForm(),
//                 ),
//                 100.0.vSpace,
//               ],
//             ),
//           ),
//         ),
//       ),

//       /// Floating Next Button
//       floatingActionButton: AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//         child: FloatingActionButton.extended(
//           backgroundColor: isValidated ? colors.primaryColor : Colors.grey[400],
//           onPressed: isValidated
//               ? () {
//                   Navigator.of(context).push(FadeRoute(
//                     page: NewCustomerPageTwo(
//                       customer: CustomerModel(
//                         fullName: customerName.text.trim(),
//                         idCard: customerID.text.trim(),
//                         dob: _selectedDate,
//                       ),
//                     ),
//                   ));
//                 }
//               : null,
//           label: Text(
//             "Next",
//             style: TextStyle(color: isValidated ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
//           ),
//           icon: Icon(color: isValidated ? Colors.white : Colors.black, Icons.arrow_forward_ios, size: 18),
//         ),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//     );
//   }
// }
