import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:susu_micro/models/staff.dart';
import 'package:susu_micro/utils/helpers.dart';

Future<void> saveStaff(String companyId, Staff staff) async {
  final docRef = FirebaseFirestore.instance
      .collection('companies')
      .doc(companyId)
      .collection('staff')
      .doc(staff.id);

  final doc = await docRef.get();
  logs.d(doc);
  if (doc.exists) {
  logs.d("Document exists.");
}

  await docRef.set({
    'name': staff.name,
    'staffId': staff.id,
    'email': staff.email,
    'role': staff.role,
    'createdAt': FieldValue.serverTimestamp(),
  });

  await saveStaffToken(companyId, staff.id);
}


Future<void> saveStaffToken(String companyId, String staffId) async {
  String? token = await FirebaseMessaging.instance.getToken();

  if (token != null) {
    final staffRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('staff')
        .doc(staffId);
    
    await staffRef.update({
      'fcmToken': token,
    });
  }
} 

Future<void> sendMessage(String companyId, String staffId, String senderId, String text) async {
  final chatId = "${companyId}_$staffId"; // unique chat
  final messagesRef = FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('messages');

  await messagesRef.add({
    'senderId': senderId,
    'text': text,
    'timestamp': FieldValue.serverTimestamp(),
  });
}
