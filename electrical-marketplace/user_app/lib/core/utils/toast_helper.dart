import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastHelper {
  static void success(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.green.shade600,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  static void error(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.red.shade600,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );
  }

  static void info(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.blueGrey.shade600,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }
}
