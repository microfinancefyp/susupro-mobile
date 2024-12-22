import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:susu_micro/views/new_customer_one.dart';
import 'package:susu_micro/views/new_customer_three.dart';
import 'package:susu_micro/views/new_customer_two.dart';

class AddCustomer extends StatefulWidget {
  const AddCustomer({super.key});

  @override
  State<AddCustomer> createState() => _AddCustomerState();
}

class _AddCustomerState extends State<AddCustomer> {
  final pages = [
    const NewCustomerPageOne(),
    const NewCustomerPageTwo(),
    const NewCustomerPageThree(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(builder: (context) => LiquidSwipe(pages: pages)),
    );
  }
}
