import 'package:flutter/material.dart';
import 'package:susu_micro/utils/appAssets.dart';
import 'package:susu_micro/utils/colors.dart';

class MyAppBar {
  static AppBar buildAppBar(BuildContext context, String title) {
    return AppBar(
      elevation: 1,
      title: Text(title),
      centerTitle: true,
      backgroundColor: AppColors().whiteColor,
      leading: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppAssets.userProfile),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(100)),
        ),
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.chat_rounded),
          onPressed: () {},
        ),
      ],
    );
  }
}
