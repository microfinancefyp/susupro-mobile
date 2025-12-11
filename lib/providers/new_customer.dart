import 'package:flutter/material.dart';

class NewCustomerProvider with ChangeNotifier {
  String? name;
  String? idCard;
  String? dob;

  void setBasicInfo(String name, String idCard, String dob) {
    this.name = name;
    this.idCard = idCard;
    this.dob = dob;
    notifyListeners();
  }
}
