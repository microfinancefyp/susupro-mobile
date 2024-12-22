import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:susu_micro/extensions/spacing.dart';
import 'package:susu_micro/route_transitions/route_transition_fade.dart';
import 'package:susu_micro/utils/appAssets.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/screen_measurement.dart';
import 'package:susu_micro/utils/text.dart';
import 'package:susu_micro/views/home_page.dart';
import 'package:susu_micro/widgets/textfomrfield.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  TextEditingController staffIdController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors().whiteColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MyTexts().titleText("Susu~Pro"),
              Image(
                image: AssetImage(AppAssets.appIcon),
                width: 130,
                height: 130,
              ),
              40.0.vSpace,
              20.0.vSpace,
              MyTextFields().buildTextField(
                  "Staff ID eg. CSE01001", staffIdController, context),
              10.0.vSpace,
              MyTextFields()
                  .buildTextField("Password", passwordController, context),
              20.0.vSpace,
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(FadeRoute(page: const HomePage()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors().primaryColor,
                  minimumSize: Size(Screen.width(context) * 0.4, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: MyTexts()
                    .regularText("SIGN IN", textColor: AppColors().whiteColor),
              ),
            ],
          ),
        ));
  }
}
