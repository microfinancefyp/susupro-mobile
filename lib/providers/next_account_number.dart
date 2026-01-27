import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:susu_micro/utils/helpers.dart';

class AccountNumberProvider extends ChangeNotifier {
  String? _nextAccountNumber;
  bool _loading = false;

  String? get nextAccountNumber => _nextAccountNumber;
  bool get loading => _loading;

  /// =========================
  /// Helpers
  /// =========================
  String _generateNextAccountNumber(String? last) {
    if (last == null || last.isEmpty) return 'BGSE001001';

    final match = RegExp(r'(\d+)$').firstMatch(last);
    if (match == null) return last;

    final number = match.group(1)!;
    final prefix = last.substring(0, last.length - number.length);

    final nextNumber = (int.parse(number) + 1)
        .toString()
        .padLeft(number.length, '0');

    return '$prefix$nextNumber';
  }

  /// =========================
  /// API Call
  /// =========================
  
  Future<void> refreshAccountNumber(String staffId) async {
    _loading = true;
    notifyListeners();

    try {
      final url = Uri.parse(
        'https://susu-pro-backend.onrender.com/api/accounts/last-customer-account-number/$staffId',
      );

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        logs.d('Last account number data: $data');
        final last = data?['lastCustomerAccountNumber'];
        logs.d('Last account number: $last');
        _nextAccountNumber = _generateNextAccountNumber(last);
      } else {
        _nextAccountNumber = null;
      }
    } catch (e) {
      debugPrint('Failed to fetch last account number: $e');
      _nextAccountNumber = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Optional reset (like staffId = null)
  void clear() {
    _nextAccountNumber = null;
    notifyListeners();
  }
}
