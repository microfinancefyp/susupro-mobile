import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:susu_micro/extensions/spacing.dart';
import 'package:susu_micro/route_transitions/route_transition_fade.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/text.dart';
import 'package:susu_micro/views/new_customer_two.dart';
import 'package:susu_micro/widgets/page_indicator.dart';
import 'package:susu_micro/widgets/textfomrfield.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class NewCustomerPageOne extends StatefulWidget {
  const NewCustomerPageOne({super.key});

  @override
  State<NewCustomerPageOne> createState() => NewCustomerPageOneState();
}

class NewCustomerPageOneState extends State<NewCustomerPageOne> {
  TextEditingController customerName = TextEditingController(),
      customerID = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedDate = '';
  bool isValidated = false;

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    final DateTime selectedDate = args.value;
    final String formattedDate =
        DateFormat('MMMM d, yyyy').format(selectedDate);
    setState(() {
      _selectedDate = formattedDate;
      _validateForm();
    });
  }

  void _validateForm() {
    bool isFormValid = _formKey.currentState?.validate() ?? false;
    bool isDateSelected = _selectedDate.isNotEmpty;

    setState(() {
      isValidated = isFormValid && isDateSelected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors().whiteColor,
        iconTheme: IconThemeData(color: AppColors().primaryColor),
      ),
      backgroundColor: AppColors().whiteColor,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              PageIndicator(
                selectedIndex: 1,
              ),
              20.0.vSpace,
              MyTexts().regularText("Add a new customer"),
              20.0.vSpace,
              Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    MyTextFields().buildTextField(
                      "Name",
                      customerName,
                      context,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Customer name is required";
                        }
                        return null;
                      },
                      onChanged: (value) => _validateForm(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30.0, vertical: 20),
                      child: SfDateRangePicker(
                        view: DateRangePickerView.month,
                        monthViewSettings:
                            const DateRangePickerMonthViewSettings(
                                firstDayOfWeek: 7),
                        onSelectionChanged: _onSelectionChanged,
                        selectionMode: DateRangePickerSelectionMode.single,
                      ),
                    ),
                    MyTexts().regularText(_selectedDate),
                    MyTextFields().buildTextField(
                      "ID Card",
                      customerID,
                      context,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "ID Card is required";
                        }
                        return null;
                      },
                      onChanged: (value) => _validateForm(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () {
                              isValidated
                                  ? Navigator.of(context).push(FadeRoute(
                                      page: const NewCustomerPageTwo()))
                                  : null;
                            },
                            child: MyTexts().regularText("Next",
                                textColor:
                                    isValidated ? Colors.blue : Colors.grey),
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
