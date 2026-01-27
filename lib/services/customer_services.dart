import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:susu_micro/models/customer_model.dart';
import 'package:susu_micro/utils/helpers.dart';

class CustomerService {
  static const String baseUrl = "https://susu-pro-backend.onrender.com/api";
  static Future<List<CustomerModel>> fetchCustomers(String staffId) async {
    final response = await http.get(Uri.parse("$baseUrl/customers/staff/$staffId"));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> data = body["data"]; // assuming response has {status, data: [...]}
     return data.map((json) => CustomerModel.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load customers");
    }
  }
}
