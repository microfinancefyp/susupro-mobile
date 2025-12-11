// import 'package:flutter/material.dart';
// import 'package:susu_micro/extensions/spacing.dart';
// import 'package:susu_micro/models/customer_model.dart';
// import 'package:susu_micro/route_transitions/route_transition_fade.dart';
// import 'package:susu_micro/utils/colors.dart';
// import 'package:susu_micro/utils/text.dart';
// import 'package:susu_micro/views/new_customer_three.dart';
// import 'package:susu_micro/widgets/page_indicator.dart';
// import 'package:susu_micro/widgets/textfomrfield.dart';

// class NewCustomerPageTwo extends StatefulWidget {
//   final CustomerModel customer;

//   const NewCustomerPageTwo({
//     super.key,
//     required this.customer,
//   });

//   @override
//   State<NewCustomerPageTwo> createState() => _NewCustomerPageTwoState();
// }

// class _NewCustomerPageTwoState extends State<NewCustomerPageTwo> {
//   final _emailController = TextEditingController(),
//       _phoneController = TextEditingController(),
//       _nextOfKin = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   String gender = 'null';
//   bool isValidated = false;

//   final List<DropdownMenuItem<String>> items = [
//     DropdownMenuItem(
//       value: 'null',
//       child: MyTexts().regularText("Choose gender"),
//     ),
//     DropdownMenuItem(
//       value: 'male',
//       child: MyTexts().regularText("Male"),
//     ),
//     DropdownMenuItem(
//       value: 'female',
//       child: MyTexts().regularText("Female"),
//     ),
//   ];

//   void _validateForm() {
//     if (_formKey.currentState!.validate() && gender != 'null') {
//       setState(() => isValidated = true);
//     } else {
//       setState(() => isValidated = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors().whiteColor,
//       appBar: AppBar(
//         backgroundColor: AppColors().whiteColor,
//         iconTheme: IconThemeData(color: AppColors().primaryColor),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             PageIndicator(selectedIndex: 2),
//             20.0.vSpace,
//             MyTexts().regularText("Add a new customer"),
//             20.0.vSpace,
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 30.0),
//               child: Form(
//                 key: _formKey,
//                 onChanged: _validateForm,
//                 autovalidateMode: AutovalidateMode.onUserInteraction,
//                 child: Column(
//                   children: [
//                     DropdownButtonFormField<String>(
//                       dropdownColor: AppColors().whiteColor,
//                       value: gender,
//                       onChanged: (value) {
//                         setState(() {
//                           gender = value!;
//                         });
//                         _validateForm();
//                       },
//                       items: items,
//                       decoration: const InputDecoration(
//                         border: OutlineInputBorder(),
//                         contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                       ),
//                       validator: (value) {
//                         if (value == 'null') {
//                           return "Please select gender";
//                         }
//                         return null;
//                       },
//                     ),
//                     30.0.vSpace,
//                     MyTextFields().buildTextField(
//                       "example@gmail.com",
//                       _emailController,
//                       context,
//                       validator: (value) =>
//                           value == null || value.isEmpty ? "Field is required" : null,
//                     ),
//                     20.0.vSpace,
//                     MyTextFields().buildTextField(
//                       "02410000121",
//                       _phoneController,
//                       context,
//                       validator: (value) =>
//                           value == null || value.isEmpty ? "Field is required" : null,
//                     ),
//                     20.0.vSpace,
//                     MyTextFields().buildTextField(
//                       "Next of Kin",
//                       _nextOfKin,
//                       context,
//                       validator: (value) =>
//                           value == null || value.isEmpty ? "Field is required" : null,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(30.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   InkWell(
//                     onTap: () {
//                       if (isValidated) {
//                         Navigator.of(context).push(
//                           FadeRoute(
//                             page: NewCustomerPageThree(
//                                 customerData: CustomerModel(
//                                   fullName: widget.customer.fullName,
//                                   idCard: widget.customer.idCard,
//                                   dob: widget.customer.dob,
//                                   gender: gender,
//                                   phoneNumber: _phoneController.text.trim(),
//                                   email: _emailController.text.trim(),
//                                   nextOfKin: _nextOfKin.text.trim(),
//                                 ),
//                             ),
//                           ),
//                         );
//                       }
//                     },
//                     child: MyTexts().regularText(
//                       "Next",
//                       textColor: isValidated ? Colors.blue : Colors.grey,
//                     ),
//                   ),
//                   Icon(
//                     Icons.arrow_forward_ios,
//                     size: 20,
//                     color: isValidated ? Colors.blue : Colors.grey,
//                   ),
//                 ],
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
