import 'package:flutter/material.dart';
import 'package:susu_micro/extensions/spacing.dart';
import 'package:susu_micro/utils/appAssets.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/text.dart';
import 'package:susu_micro/widgets/transaction_widget.dart';

class CustomerDetailsPage extends StatefulWidget {
  const CustomerDetailsPage({super.key});

  @override
  State<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  List<Map<String, dynamic>> transactions = [
    {
      "date": "August 21st",
      "status": "Checked",
      "amount": "20",
    },
    {
      "date": "September 21st",
      "status": "Checked",
      "amount": "10",
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors().whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors().whiteColor,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyTexts().titleText("Odai Angela"),
            10.0.vSpace,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 270,
                  height: 213,
                  decoration: BoxDecoration(
                    color: AppColors().primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MyTexts().regularText(
                          'Current Balance:',
                          textColor: AppColors().lightGrey,
                        ),
                        MyTexts().titleText('GH\$ 1524.00',
                            textColor: AppColors().whiteColor),
                        50.0.vSpace,
                        MyTexts().regularText(
                          'AC NO: 00 612 23214 215',
                          textColor: AppColors().lightGrey,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage(
                            AppAssets.userProfile,
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    20.0.vSpace,
                    Container(
                        decoration: BoxDecoration(
                          color: AppColors().greenColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4.0, vertical: 6),
                          child: Center(
                              child: MyTexts().regularText(
                            'GH\$10',
                            textColor: AppColors().whiteColor,
                          )),
                        )),
                  ],
                ),
              ],
            ),
            30.0.vSpace,
            MyTexts().titleText("Recent Transactions"),
            Expanded(
              child: ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return TransactionWidget(
                      transactionDate: "${transaction['date']}",
                      transactionAmount: "${transaction['amount']}",
                      transactionStatus: "${transaction['status']}",
                      transactionID: index,
                    );
                  }),
            )
          ],
        ),
      ),
    );
  }
}
