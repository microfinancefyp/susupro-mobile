import 'package:flutter/material.dart';

class MyTexts {
  Text regularText(
    String text, {
    Color? textColor,
    double? fontSize,
  }) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize ?? 15,
        fontFamily: 'Poppins',
        color: textColor,
      ),
    );
  }

  Text titleText(
    String text, {
    Color? textColor,
    double? fontSize,
  }) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: fontSize ?? 25,
        fontFamily: 'Poppins',
        color: textColor,
      ),
    );
  }
}
