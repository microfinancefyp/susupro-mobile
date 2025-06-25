import 'package:flutter/material.dart';
import 'package:susu_micro/extensions/spacing.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/screen_measurement.dart';
import 'package:susu_micro/utils/text.dart';

class CustomerProfile extends StatefulWidget {
  const CustomerProfile({super.key});

  @override
  State<CustomerProfile> createState() => _CustomerProfileState();
}

class _CustomerProfileState extends State<CustomerProfile> {
  Widget rowWdiget(String label, String value) {
    return Padding(
        padding: const EdgeInsets.all(7.0),
        child: SizedBox(
          width: Screen.width(context) * 0.7,
          child: Row(
            children: [
              SizedBox(
                  width: Screen.width(context) * 0.3,
                  child: MyTexts().titleText("$label:",
                      fontSize: 16, textColor: AppColors().lightGrey)),
              MyTexts().titleText(value,
                  fontSize: 16, textColor: AppColors().blackColor)
            ],
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors().whiteColor,
          title: MyTexts().titleText("Angela Odoi"),
          centerTitle: true,
        ),
        backgroundColor: AppColors().whiteColor,
        body: Center(
          child: Column(
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                ),
              ),
              20.0.vSpace,
              rowWdiget("NAME", "Angela Odoi"),
              rowWdiget("AGE", "23"),
              rowWdiget("GENDER", "Female"),
              rowWdiget("GH CARD", "GH-720836144-2"),
              rowWdiget("DOB", "19-24-02"),
              rowWdiget("PHONE", "+233593528296"),
              rowWdiget("NOK", "Jerry"),
              rowWdiget("DOR", "01-01-25"),
              rowWdiget("DR", "GHC 20.00"),
            ],
          ),
        ));
  }
}
