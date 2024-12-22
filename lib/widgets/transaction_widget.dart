import 'package:flutter/material.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/text.dart';

class TransactionWidget extends StatelessWidget {
  final String transactionDate;
  final String transactionAmount;
  final String transactionStatus;
  final int transactionID;
  const TransactionWidget({
    super.key,
    required this.transactionDate,
    required this.transactionAmount,
    required this.transactionStatus,
    required this.transactionID,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: (transactionID % 2 == 0)
              ? AppColors().lightGrey
              : AppColors().whiteColor,
          border: Border.all(
              color: (transactionID % 2 == 0)
                  ? AppColors().whiteColor
                  : AppColors().lightGrey),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 21.0, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors().primaryColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyTexts().regularText(transactionDate),
                    MyTexts().regularText(transactionStatus),
                  ],
                ),
                MyTexts().regularText(transactionAmount,
                    textColor: AppColors().greenColor),
              ],
            ),
          ),
        ));
  }
}
