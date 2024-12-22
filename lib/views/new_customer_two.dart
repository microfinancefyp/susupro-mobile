import 'package:flutter/material.dart';
import 'package:susu_micro/extensions/spacing.dart';
import 'package:susu_micro/route_transitions/route_transition_fade.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/text.dart';
import 'package:susu_micro/widgets/page_indicator.dart';
import 'package:susu_micro/widgets/textfomrfield.dart';

class NewCustomerPageTwo extends StatefulWidget {
  const NewCustomerPageTwo({super.key});

  @override
  State<NewCustomerPageTwo> createState() => _NewCustomerPageTwoState();
}

class _NewCustomerPageTwoState extends State<NewCustomerPageTwo> {
  final _emailController = TextEditingController(),
      _phoneController = TextEditingController(),
      _nextOfKin = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String gender = 'null';
  bool isValidated = false;

  List<DropdownMenuItem<String>> items = [
    DropdownMenuItem(
      value: 'null',
      child: MyTexts().regularText("Choose gender"),
    ),
    DropdownMenuItem(
      value: 'male',
      child: MyTexts().regularText("Male"),
    ),
    DropdownMenuItem(
      value: 'female',
      child: MyTexts().regularText("Female"),
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors().whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors().whiteColor,
        iconTheme: IconThemeData(color: AppColors().primaryColor),
      ),
      body: Center(
        child: Column(
          children: [
            PageIndicator(
              selectedIndex: 2,
            ),
            20.0.vSpace,
            MyTexts().regularText("Add a new customer"),
            20.0.vSpace,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      DropdownButtonFormField(
                          dropdownColor: AppColors().whiteColor,
                          value: gender,
                          hint: MyTexts().regularText("Gender"),
                          onChanged: (value) {
                            setState(() {
                              gender = value.toString();
                            });
                          },
                          items: items),
                      30.0.vSpace,
                      MyTextFields().buildTextField(
                        "example@gmail.com",
                        _emailController,
                        context,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Field is required";
                          }
                          return null;
                        },
                      ),
                      20.0.vSpace,
                      MyTextFields().buildTextField(
                        "02410000121",
                        _phoneController,
                        context,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Field is required";
                          }
                          return null;
                        },
                      ),
                      20.0.vSpace,
                      MyTextFields().buildTextField(
                        "Next of Kin",
                        _nextOfKin,
                        context,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Field is required";
                          }
                          return null;
                        },
                      ),
                    ],
                  )),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () {
                      isValidated
                          ? Navigator.of(context)
                              .push(FadeRoute(page: const NewCustomerPageTwo()))
                          : null;
                    },
                    child: MyTexts().regularText("Next",
                        textColor: isValidated ? Colors.blue : Colors.grey),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 20,
                    color: isValidated ? Colors.blue : Colors.grey,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
