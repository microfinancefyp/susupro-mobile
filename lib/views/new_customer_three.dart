import 'package:flutter/material.dart';
import 'package:susu_micro/extensions/spacing.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/text.dart';
import 'package:susu_micro/widgets/page_indicator.dart';
import 'package:susu_micro/widgets/textfomrfield.dart';

class NewCustomerPageThree extends StatefulWidget {
  const NewCustomerPageThree({super.key});

  @override
  State<NewCustomerPageThree> createState() => _NewCustomerPageThreeState();
}

class _NewCustomerPageThreeState extends State<NewCustomerPageThree> {
  final TextEditingController _genderController = TextEditingController();
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
              selectedIndex: 3,
            ),
            20.0.vSpace,
            MyTexts().regularText("Add a new customer"),
            20.0.vSpace,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Form(
                  child: Column(
                children: [
                  30.0.vSpace,
                  MyTextFields()
                      .buildTextField("Location", _genderController, context),
                  20.0.vSpace,
                  MyTextFields()
                      .buildTextField("Area", _genderController, context),
                  20.0.vSpace,
                  MyTextFields()
                      .buildTextField("Daily Rate", _genderController, context),
                  20.0.vSpace,
                ],
              )),
            )
          ],
        ),
      ),
    );
  }
}
