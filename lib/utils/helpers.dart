import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final logs = Logger();


void sendCustomerSmS (String phoneNumber, String companyName, String? uniqueCode, String? message) async {
  final messageBody = {
    "messageTo": phoneNumber,
    "message": message ?? "Your withdrawal request has been submitted. Use this code to confirm at the office: $uniqueCode",
    "messageFrom": makeSuSuProName(companyName),
  };

  final msgRes = await http.post(
    Uri.parse("https://susu-pro-backend.onrender.com/api/messages/send-customer"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(messageBody),
  );

  if (msgRes.statusCode == 200 || msgRes.statusCode == 201) {
    logs.d("Message sent successfully: ${msgRes.body}");
  } else {
    logs.e("Failed to send message: ${msgRes.body}");
  }
}

String makeSuSuProName(String? companyName) {
  if (companyName == null || companyName.trim().isEmpty) return "SuSuPro";
  if(companyName.trim() == 'Big God Susu Enterprise') return "BigGod Susu";
  // Split words by spaces, hyphen, underscore, or dot
  final words = companyName
      .trim()
      .split(RegExp(r'[\s\-_.]+'))
      .where((w) => w.isNotEmpty)
      .toList();

  // Collect initials (letters only), uppercase
  final initials = words.map((w) {
    final match = RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]').firstMatch(w);
    return match != null ? match.group(0)! : '';
  }).join().toUpperCase();

  return "${initials}SuSu";
}


  String generateUniqueCode(String phoneNumber) {
  final now = DateTime.now();
  final phoneSuffix = phoneNumber.substring(phoneNumber.length - 4);

  // Add day + hour + minute for freshness
  final shortTime = "${now.day.toString().padLeft(2, '0')}"
      "${now.hour.toString().padLeft(2, '0')}"
      "${now.minute.toString().padLeft(2, '0')}";

  return "WD$shortTime$phoneSuffix";
}

Color getIconColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'deposit':
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'withdrawal':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

    String formatDate(String? dateString) {
    if (dateString == null) return "N/A";
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;
      
      if (difference == 0) return "Today";
      if (difference == 1) return "Yesterday";
      if (difference < 7) return "$difference days ago";
      
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return "Invalid date";
    }
  }