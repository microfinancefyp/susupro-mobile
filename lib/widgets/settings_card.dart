import 'package:flutter/material.dart';
import 'package:susu_micro/extensions/spacing.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/screen_measurement.dart';
import 'package:susu_micro/utils/text.dart';

class SettingsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  Function()? function;
  SettingsCard({super.key, required this.icon, required this.label, this.function});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: function,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Column(children: [
            Container(
                height: 75,
                width: Screen.width(context),
                decoration: BoxDecoration(
                    color: AppColors().whiteColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors().whiteColor),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.4),
                          blurRadius: 1,
                          spreadRadius: 1,
                          offset: const Offset(0, 2))
                    ]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child:
                      Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                    Icon(icon),
                    10.0.hSpace,
                    MyTexts().regularText(label),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios)
                  ]),
                )),
          ])),
    );
  }
}
