import 'package:flutter/material.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/text.dart';

class MyButtons {
  Container myPrimaryButton(String label) {
    return Container(
      width: 157,
      height: 53,
      decoration: BoxDecoration(
        color: AppColors().primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: MyTexts().regularText(label, textColor: AppColors().whiteColor),
      ),
    );
  }

  Container mySecondaryButton(String label) {
    return Container(
      width: 157,
      height: 53,
      decoration: BoxDecoration(
        color: AppColors().secondaryCOlor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: MyTexts().regularText(label, textColor: AppColors().whiteColor),
      ),
    );
  }
}
