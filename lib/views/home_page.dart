import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/views/customers_page.dart';
import 'package:susu_micro/views/new_customer_one.dart';
import 'package:susu_micro/views/new_customer_three.dart';
import 'package:susu_micro/views/profile_page.dart';
import 'package:susu_micro/route_transitions/route_transition_fade.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const CustomersPage(),
    const CustomerRegistration(),
    const UserProfile(),
  ];

  void onNavBarTap(int index) async {
      setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors().whiteColor,
      body: _pages[_currentIndex],

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors().whiteColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: GNav(
              rippleColor: AppColors().primaryColor.withOpacity(0.1),
              hoverColor: AppColors().primaryColor.withOpacity(0.05),
              haptic: true,
              tabBorderRadius: 16,
              curve: Curves.easeOutExpo,
              duration: const Duration(milliseconds: 400),
              gap: 8,
              color: Colors.grey[600],
              activeColor: AppColors().primaryColor,
              iconSize: 26,
              tabBackgroundColor: AppColors().primaryColor.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              selectedIndex: _currentIndex,
              onTabChange: onNavBarTap,
              tabs: const [
                GButton(
                  icon: Icons.home_rounded,
                  text: 'Home',
                ),
                GButton(
                  icon: Icons.add_circle_rounded,
                  text: 'New',
                ),
                GButton(
                  icon: Icons.person_rounded,
                  text: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
