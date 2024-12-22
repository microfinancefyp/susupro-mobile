import 'package:flutter/material.dart';
import 'package:susu_micro/route_transitions/route_transition_fade.dart';
import 'package:susu_micro/utils/appAssets.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/text.dart';
import 'package:susu_micro/views/customer_detail.dart';

class CustomerWidget extends StatelessWidget {
  final String customerName;
  final String customerLocatoin;
  final String customerDailyRate;
  const CustomerWidget(
      {super.key,
      required this.customerName,
      required this.customerLocatoin,
      required this.customerDailyRate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context)
                            .push(FadeRoute(page: const CustomerDetailsPage()));
                      },
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
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyTexts().regularText(customerName),
                  MyTexts().regularText(customerLocatoin,
                      textColor: Colors.grey, fontSize: 12),
                ],
              ),
              const Spacer(),
              Container(
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors().greenColor,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MyTexts().regularText(customerDailyRate,
                        textColor: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
