import 'package:flutter/material.dart';
import 'package:ktalk03/main.dart';

class GlobalNavigator {
  static Future<void> showAlertDialog({required String msg}) async {
    await showDialog(
      // Dialog 위젯 바깥 부분을 터치해도 다이얼로그 위젯이 닫히지 않음
      barrierDismissible: false,
      // 다이얼로그 호출되는 화면의 context
      context: navigatorKey.currentContext!,
      builder: (context) {
        return AlertDialog(
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }
}
