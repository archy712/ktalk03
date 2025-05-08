import 'package:flutter/cupertino.dart';
import 'package:ktalk03/common/models/dark_theme_color.dart';
import 'package:ktalk03/common/models/light_theme_color.dart';
import 'package:ktalk03/common/models/theme_color.dart';
import 'package:ktalk03/common/providers/theme_mode_enum.dart';

// 테마 상태관리 데이터를 담고 있는 상태 클래스
class CustomThemeState {
  // ThemeColor 가상 클래스 : 실제 구현클래스가 매핑되어 관리
  final ThemeColor themeColor;

  // 테마 모드를 구분하는 enum
  final ThemeModeEnum themeModeEnum;

  // constructor
  const CustomThemeState({
    required this.themeColor,
    required this.themeModeEnum,
  });

  // factory init method
  factory CustomThemeState.init() {
    // 현재 기기의 Theme 알아냄
    final Brightness brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    // 현재 기기의 Theme

    // 현재 기기의 Theme 설정에 따라서 상태관리 변수 설정
    return CustomThemeState(
      themeColor:
          brightness == Brightness.dark ? DarkThemeColor() : LightThemeColor(),
      themeModeEnum:
          brightness == Brightness.dark
              ? ThemeModeEnum.dark
              : ThemeModeEnum.light,
    );
  }

  // copyWith method
  CustomThemeState copyWith({
    ThemeColor? themeColor,
    ThemeModeEnum? themeModeEnum,
  }) {
    return CustomThemeState(
      themeColor: themeColor ?? this.themeColor,
      themeModeEnum: themeModeEnum ?? this.themeModeEnum,
    );
  }
}
