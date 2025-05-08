import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ktalk03/auth/providers/auth_provider.dart';
import 'package:ktalk03/auth/screens/otp_screen.dart';
import 'package:ktalk03/common/utils/global_navigator.dart';
import 'package:ktalk03/common/utils/locale/generated/l10n.dart';
import 'package:ktalk03/common/utils/logger.dart';
import 'package:ktalk03/common/widgets/custom_button_widget.dart';

class PhoneNumberInputScreen extends ConsumerStatefulWidget {
  const PhoneNumberInputScreen({super.key});

  @override
  ConsumerState<PhoneNumberInputScreen> createState() =>
      _PhoneNumberInputScreenState();
}

class _PhoneNumberInputScreenState
    extends ConsumerState<PhoneNumberInputScreen> {
  // 국가선택 TextFormField 위한 TextEditingController
  final TextEditingController countryController = TextEditingController();

  // 국가번호 선택 TextEditingController
  final TextEditingController phoneCodeController = TextEditingController();

  // 전화번호 입력 TextEditingController
  final TextEditingController phoneNumberController = TextEditingController();

  // Form 유효성 검증을 위한 GlobalKey
  final GlobalKey<FormState> globalKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // 기기의 국가설정을 가지고 옴
    final String countryCode = Platform.localeName.split('_')[1];
    final Country country = CountryParser.parseCountryCode(countryCode);

    //logger.d('Platform.localName : ${Platform.localeName}');
    //logger.d('countryCode : $countryCode');
    //logger.d('country : ${country.toString()}');

    countryController.text = country.name;
    phoneCodeController.text = country.phoneCode;
  }

  @override
  void dispose() {
    countryController.dispose();
    phoneCodeController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  // PhoneCode + PhoneNumber 서버에 전달
  Future<void> sendOTP() async {
    final String phoneCode = phoneCodeController.text;
    final String phoneNumber = phoneNumberController.text;

    logger.d('+$phoneCode$phoneNumber');
    await ref
        .read(authProvider.notifier)
        .sendOTP(phoneNumber: '+$phoneCode$phoneNumber');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: Text(S.current.loginScreenText1)),
        body: Center(
          child: Column(
            children: [
              Text(
                S.current.loginScreenText2,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 250,
                child: TextFormField(
                  controller: countryController,
                  readOnly: true,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  onTap: () {
                    showCountryPicker(
                      context: context,
                      showPhoneCode: true,
                      onSelect: (Country country) {
                        countryController.text = country.name;
                        phoneCodeController.text = country.phoneCode;
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 250,
                child: Row(
                  children: [
                    // 국가번호 선택 TextFormField
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: phoneCodeController,
                        readOnly: true,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          isDense: true,
                          prefixIconConstraints: BoxConstraints(
                            maxWidth: 0,
                            minHeight: 0,
                          ),
                          prefixIcon: Text('+'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 전화번호 입력 TextFormField
                    Expanded(
                      flex: 2,
                      child: Form(
                        key: globalKey,
                        child: TextFormField(
                          controller: phoneNumberController,
                          decoration: const InputDecoration(
                            // 커서 입력칸과 밑줄 사이의 간격 줄이기
                            isDense: true,
                          ),
                          // 올라오는 키보드 타입
                          keyboardType: TextInputType.phone,
                          // 입력도 숫자만 가능하게
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return S.current.loginScreenText1;
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 남은 공간 차지
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: CustomButtonWidget(
                  text: S.current.next,
                  onPressed: () async {
                    try {
                      // 먼저 키보드가 올라와 있으면 키보드 내림
                      FocusScope.of(context).unfocus();

                      // Form 상태 데이터 얻어서 유효성 체크
                      final FormState? form = globalKey.currentState;
                      if (form == null || !form.validate()) {
                        return;
                      }

                      // navigator 얻음
                      final NavigatorState myNavigator = Navigator.of(context);

                      // phoneCode + phoneNumber 전송
                      await sendOTP();

                      // 화면 이동
                      myNavigator.pushNamed(OTPScreen.routeName);
                    } catch (e, stackTrace) {
                      GlobalNavigator.showAlertDialog(msg: e.toString());
                      logger.e(stackTrace.toString());
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
