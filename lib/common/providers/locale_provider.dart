import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// NotifierProvider 전역변수 선언
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  () => LocaleNotifier(),
);

// Notifier 확장 클래스
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    // 초기값은 안드로이드 기기에 설정된 지역 정보를 가져와서 설정 : 예) ko_KR
    final String languageCode = Platform.localeName.split('_')[0];
    return Locale(languageCode);
  }

  // Locale 변경
  void changeLocale({required Locale locale}) {
    state = locale;
  }
}
