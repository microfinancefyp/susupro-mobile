import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:susu_micro/models/customer_model.dart';
import 'package:susu_micro/utils/helpers.dart';

class CustomerService {
  static Future<double> _fetchTotalAccountBalance(String customerId) async {
  final response = await http.get(
    Uri.parse("$baseUrl/accounts/customer/$customerId"),
  );

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    final List<dynamic> accounts = decoded['data'];

    return accounts.fold<double>(0.0, (sum, account) {
      final balance = double.tryParse(account['balance'].toString()) ?? 0.0;
      return sum + balance;
    });
  } else {
    return 0.0;
  }
}


  static const String baseUrl = "https://susu-pro-backend.onrender.com/api";
  static Future<List<CustomerModel>> fetchCustomers(String staffId) async {
  final response =
      await http.get(Uri.parse("$baseUrl/customers/staff/$staffId"));

  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);
    final List<dynamic> data = body["data"];

    List<CustomerModel> customers = [];

    for (var json in data) {
      final customer = CustomerModel.fromJson(json);
      final totalBalance = await _fetchTotalAccountBalance(customer.uid ?? '');

      customers.add(
        customer.copyWith(totalBalance: totalBalance),
      );
    }

    return customers;
  } else {
    throw Exception("Failed to load customers");
  }
}

}
