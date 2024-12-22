import 'package:flutter/material.dart';
import 'package:susu_micro/extensions/spacing.dart';
import 'package:susu_micro/utils/appAssets.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/screen_measurement.dart';
import 'package:susu_micro/utils/text.dart';
import 'package:susu_micro/widgets/settings_card.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors().whiteColor,
        body: Column(
          children: [
            Container(
              width: Screen.width(context),
              height: Screen.width(context) * 0.7,
              decoration: BoxDecoration(
                color: AppColors().primaryColor,
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
                  MyTexts().regularText("Comfort Cudjoe",
                      textColor: AppColors().whiteColor, fontSize: 16),
                  5.0.vSpace,
                  MyTexts().regularText("CSE01001",
                      textColor: AppColors().whiteColor, fontSize: 14),
                ],
              ),
            ),
            90.0.vSpace,
            InkWell(
              onTap: () {},
              child: const SettingsCard(
                icon: Icons.person,
                label: "Account info",
              ),
            ),
            const SettingsCard(
              icon: Icons.settings_outlined,
              label: "Settings",
            ),
            const SettingsCard(
              icon: Icons.info_outline,
              label: "Account info",
            ),
          ],
        ));
  }
}
