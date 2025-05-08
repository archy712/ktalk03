import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ktalk03/auth/providers/auth_provider.dart';
import 'package:ktalk03/common/utils/global_navigator.dart';
import 'package:ktalk03/common/utils/locale/generated/l10n.dart';
import 'package:ktalk03/common/utils/logger.dart';

class OTPScreen extends ConsumerWidget {
  // 라우팅을 위한 routeName
  static const routeName = '/otp-screen';

  const OTPScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: Text(S.current.otpScreenText1)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(S.current.otpScreenText2, style: TextStyle(fontSize: 16)),
              Container(
                width: 240,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.green)),
                ),
                child: OtpTextField(
                  margin: EdgeInsets.zero,
                  numberOfFields: 6,
                  fieldWidth: 35,
                  textStyle: const TextStyle(fontSize: 20),
                  hasCustomInputDecoration: true,
                  decoration: const InputDecoration(
                    hintText: '-',
                    counterText: '',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onSubmit: (value) async {
                    try {
                      // 비동기 작업 전에 context 얻는 Navigator 선언해 주고
                      final NavigatorState myNavigator = Navigator.of(context);

                      // OTP 인증
                      await ref
                          .read(authProvider.notifier)
                          .verifyOTP(userOTP: value);

                      // 로그인 후 첫번째 화면만 남기고 나머지 화면들은 전부 다 삭제 처리
                      // if (context.mounted) {
                      //   Navigator.popUntil(context, (route) => route.isFirst);
                      // }

                      // 비동기 로직이 끝나고 나서 위에서 선언한 myNavigator 사용
                      myNavigator.popUntil((route) => route.isFirst);
                    } catch (e, stackTrace) {
                      GlobalNavigator.showAlertDialog(msg: e.toString());
                      logger.e(stackTrace);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
