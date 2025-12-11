import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:susu_micro/extensions/spacing.dart';
import 'package:susu_micro/providers/staff_provider.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/screen_measurement.dart';
import 'package:susu_micro/utils/text.dart';
import 'package:susu_micro/views/customer_detail.dart';
import 'package:susu_micro/views/staking_page.dart';
import 'package:susu_micro/views/welcome_page.dart';
import 'package:susu_micro/widgets/settings_card.dart';

class UserProfile extends StatelessWidget {
  const UserProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final staffProvider = Provider.of<StaffProvider>(context);

    return Scaffold(
      backgroundColor: AppColors().whiteColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Profile",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors().primaryColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// --- Profile Avatar + Info ---
            Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.grey.shade200,
                  child: Center(child: Text(staffProvider.fullName?.substring(0, 1) ?? "U")),
                ),
                12.0.vSpace,
                Text(
                  staffProvider.fullName ?? "Unknown User",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                6.0.vSpace,
                Text(
                  staffProvider.staffId ?? "Staff ID",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            24.0.vSpace,

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildOption(
                    icon: Icons.person_outline,
                    label: "Account Info",
                    onTap: () {
                    
                    },
                  ),
                  Divider(height: 1, color: Colors.grey.shade300),
                  _buildOption(
                    icon: Icons.account_balance_wallet_outlined,
                    label: "Staking",
                    onTap: () {
                     
                    },
                  ),
                  Divider(height: 1, color: Colors.grey.shade300),
                  _buildOption(
                    icon: Icons.settings_outlined,
                    label: "Settings",
                  ),
                  Divider(height: 1, color: Colors.grey.shade300),
                  _buildOption(
                    icon: Icons.info_outline,
                    label: "About App",
                  ),
                ],
              ),
            ),

            40.0.vSpace,

            /// --- Logout Button ---
            ElevatedButton(
              onPressed: () {
                final staff = Provider.of<StaffProvider>(context, listen: false);
                staff.logout();
                Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (context) => WelcomePage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors().primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
                elevation: 0,
              ),
              child: const Text(
                "Log out",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
