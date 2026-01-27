import 'package:cloud_firestore/cloud_firestore.dart';

class Staff {
  final String id;
  final String name;
  final String role;
  final bool isOnline;
  final String? email;
  final String? phone;

  Staff({
    required this.id,
    required this.name,
    required this.role,
    this.isOnline = false,
    this.email,
    this.phone,
  });

  factory Staff.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Staff(
      id: doc.id,
      name: data['name'] ?? '',
      role: data['role'] ?? '',
      isOnline: data['isOnline'] ?? false,
      email: data['email'],
      phone: data['phone'],
    );
  }
}