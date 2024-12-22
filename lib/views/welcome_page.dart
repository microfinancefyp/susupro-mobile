import 'package:flutter/material.dart';
import 'package:susu_micro/extensions/spacing.dart';
import 'package:susu_micro/route_transitions/route_transition_fade.dart';
import 'package:susu_micro/utils/appAssets.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/text.dart';
import 'package:susu_micro/views/signin_page.dart';
import 'package:susu_micro/widgets/buttons.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors().whiteColor,
      body: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.03),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image(image: AssetImage(AppAssets.appIcon)),
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.95,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors().primaryColor,
                            blurRadius: 2.5,
                            spreadRadius: 2.5,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyTexts().titleText('Welcome!'),
                            MyTexts().regularText(
                                'Sign in to continue with us. Credentials are to be provided by the office'),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                        FadeRoute(page: const SignInPage()));
                                  },
                                  child: MyButtons().myPrimaryButton(
                                    "SIGN IN",
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
