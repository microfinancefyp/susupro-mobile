import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:susu_micro/route_transitions/route_transition_fade.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/views/add_customer_page.dart';
import 'package:susu_micro/views/customers_page.dart';
import 'package:susu_micro/views/new_customer_one.dart';
import 'package:susu_micro/views/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const CustomersPage(),
    const UserProfile(),
    const UserProfile(),
  ];

  void onNavBarTap(int index) async {
    if (index == 1) {
      await Navigator.of(context).push(
        FadeRoute(page: const NewCustomerPageOne()),
      );

      setState(() {
        _currentIndex = 0;
      });
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors().whiteColor,
      body: _pages[_currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: AppColors().primaryColor,
        color: AppColors().whiteColor,
        buttonBackgroundColor: AppColors().primaryColor,
        height: 60,
        index:
            _currentIndex, // This ensures the index matches the current state
        items: [
          Icon(
            Icons.home,
            size: 30,
            color: _currentIndex == 0
                ? AppColors().whiteColor
                : AppColors().primaryColor,
          ),
          Icon(
            Icons.add,
            size: 30,
            color: AppColors().primaryColor, // Static color for the button
          ),
          Icon(
            Icons.person,
            size: 30,
            color: _currentIndex == 2
                ? AppColors().whiteColor
                : AppColors().primaryColor,
          ),
        ],
        onTap: onNavBarTap,
      ),
    );
  }
}
