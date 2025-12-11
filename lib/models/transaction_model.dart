import 'package:flutter/material.dart';

class Transaction {
  final String id;
  final String accountId;
  final double amount;
  final String type;
  final String? description;
  final DateTime transactionDate;
  final String createdBy;
  final String companyId;
  final String status;
  final String? uniqueCode;
  String? accountType;
  String? companyName;
  String? staffName;
  String? customerLocation;
  String? customerName;

  Transaction({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.type,
    this.description,
    required this.transactionDate,
    required this.createdBy,
    required this.companyId,
    required this.status,
    this.uniqueCode,
    this.accountType,
    this.companyName,
    this.staffName,
    this.customerLocation,
    this.customerName,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      accountId: json['account_id'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      type: json['type'] ?? '',
      description: json['description'],
      transactionDate: DateTime.parse(json['transaction_date']),
      createdBy: json['created_by'] ?? '',
      companyId: json['company_id'] ?? '',
      status: json['status'] ?? '',
      uniqueCode: json['unique_code'] ?? '',
      accountType: json['account_type'] ?? '',
      companyName: json['company_name'] ?? '',
      staffName: json['full_name'] ?? '',
      customerLocation: json['customer_location'] ?? '',
      customerName: json['customer_name'] ?? ''
    );
  }
}

class FilterOption {
  final String value;
  final String label;
  final IconData icon;

  FilterOption(this.value, this.label, this.icon);
}