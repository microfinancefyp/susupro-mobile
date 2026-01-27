import 'package:flutter/material.dart';
import 'package:susu_micro/models/customer_model.dart';

class CustomerProvider extends ChangeNotifier {
  List<CustomerModel> _allCustomers = [];
  List<CustomerModel> _filteredCustomers = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedLocation = 'All';

  List<CustomerModel> get customers => _filteredCustomers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedLocation => _selectedLocation;

  void setCustomers(List<CustomerModel> customers) {
    _allCustomers = customers;
    _filteredCustomers = customers;
    notifyListeners();
  }

  CustomerModel? getCustomerById(String id) {
  try {
    return _allCustomers.firstWhere((c) => c.uid == id);
  } catch (e) {
    return null; // If not found
  }
}

  void addCustomer(CustomerModel customer) {
    _allCustomers.add(customer);
    _filteredCustomers = _allCustomers;
    notifyListeners();
  }

  void clearCustomers() {
    _allCustomers.clear();
    _filteredCustomers.clear();
    notifyListeners();
  }

  void filterByLocation(String location) {
    _selectedLocation = location;
    if (location == 'All') {
      _filteredCustomers = _allCustomers;
    } else {
      _filteredCustomers =
          _allCustomers.where((c) => c.location == location).toList();
    }
    notifyListeners();
  }

  void search(String query) {
    if (query.isEmpty) {
      _filteredCustomers = _allCustomers;
    } else {
      _filteredCustomers = _allCustomers
          .where((c) =>
              (c.fullName ?? '').toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void updateCustomer(CustomerModel updated) {
  final index = _allCustomers.indexWhere((c) => c.uid == updated.uid);
  if (index != -1) {
    _allCustomers[index] = updated;
  }

  final fIndex = _filteredCustomers.indexWhere((c) => c.uid == updated.uid);
  if (fIndex != -1) {
    _filteredCustomers[fIndex] = updated;
  }

  notifyListeners();
}

}
