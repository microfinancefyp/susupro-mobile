import 'package:flutter/material.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/screen_measurement.dart';

class MyTextFields {
  SizedBox buildTextField(
    String label,
    TextEditingController controller,
    BuildContext context, {
    Color? borderColor,
    double? formWidth,
    IconData? icon,
    Color? textColor,
    bool? obscureText,
    TextInputType? inputType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function()? obscureSwitch,
  }) {
    return SizedBox(
      width: formWidth ?? Screen.width(context) * 0.85,
      child: TextFormField(
        keyboardType: inputType ?? null,
        validator: validator,
        onChanged: onChanged,
        obscureText: obscureText ?? false,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: borderColor ?? AppColors().primaryColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: borderColor ?? AppColors().primaryColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          hintText: label,
          hintStyle:
              TextStyle(fontFamily: 'Poppins', color: textColor ?? Colors.grey),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: borderColor ?? AppColors().primaryColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          suffixIcon: InkWell(
            onTap: () {
              obscureSwitch;
            },
            child: Icon(
              icon,
              color: AppColors().lightGrey,
            ),
          ),
        ),
        controller: controller,
      ),
    );
  }
}
