import 'package:flutter/material.dart';
import 'package:susu_micro/extensions/spacing.dart';
import 'package:susu_micro/utils/appAssets.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/screen_measurement.dart';
import 'package:susu_micro/utils/text.dart';

class StakingPage extends StatefulWidget {
  final String customerName;
  const StakingPage({super.key, required this.customerName});

  @override
  State<StakingPage> createState() => _StakingPageState();
}

class _StakingPageState extends State<StakingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors().whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors().lightGrey,
      ),
      body: Column(
        children: [
          Container(
            width: Screen.width(context),
            height: Screen.width(context) * 0.7,
            decoration: BoxDecoration(
              color: AppColors().lightGrey,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 142,
                  height: 142,
                  decoration: BoxDecoration(
                    color: AppColors().primaryColor,
                    image: DecorationImage(
                      image: AssetImage(
                        AppAssets.userProfile,
                      ),
                      fit: BoxFit.cover,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                15.0.vSpace,
                MyTexts().titleText(
                  widget.customerName,
                  textColor: AppColors().blackColor,
                  fontSize: 20,
                ),
                5.0.vSpace,
                MyTexts().regularText("0593528296",
                    textColor: AppColors().blackColor, fontSize: 14),
              ],
            ),
          ),
          Form(
              child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextFormField(
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(hintText: "GHS20.0"),
                ),
              )
            ],
          ))
        ],
      ),
    );
  }
}
