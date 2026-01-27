import 'package:flutter/material.dart';
import 'package:susu_micro/models/customer_model.dart';
import 'package:susu_micro/route_transitions/route_transition_fade.dart';
import 'package:susu_micro/utils/appAssets.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/text.dart';
import 'package:susu_micro/views/customer_detail.dart';
import 'package:susu_micro/views/staking_page.dart';

class CustomerWidget extends StatelessWidget {
  final String customerName;
  final String customerLocatoin;
  final String customerDailyRate;
  final CustomerModel customer;

  const CustomerWidget({
    super.key,
    required this.customerName,
    required this.customerLocatoin,
    required this.customerDailyRate,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: InkWell(
        // Tapping anywhere except the avatar goes to StakingPage
        onTap: () {
          Navigator.of(context).push(
            FadeRoute(page: StakingPage(customerName: customerName, customer: customer)),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors().lightGrey),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar / initials - goes to CustomerDetailsPage
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      FadeRoute(page: CustomerDetailsPage(customer: customer)),
                    );
                  },
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(AppAssets.userProfile),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + Location
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyTexts().regularText(customerName),
                    MyTexts().regularText(
                      customerLocatoin,
                      textColor: Colors.grey,
                      fontSize: 12,
                    ),
                  ],
                ),
                const Spacer(),
                // Daily Rate
                Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors().greenColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: MyTexts().regularText(
                        customerDailyRate,
                        textColor: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
