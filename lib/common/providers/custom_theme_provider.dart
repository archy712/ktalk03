import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ktalk03/common/models/dark_theme_color.dart';
import 'package:ktalk03/common/models/light_theme_color.dart';
import 'package:ktalk03/common/models/theme_color.dart';
import 'package:ktalk03/common/providers/custom_theme_state.dart';
import 'package:ktalk03/common/providers/theme_mode_enum.dart';

// riverpod 변수 선언
// 타입 : NotifierProviderImpl<CustomThemeNotifier, CustomThemeState>
final customThemeProvider =
    NotifierProvider<CustomThemeNotifier, CustomThemeState>(
      () => CustomThemeNotifier(),
    );

// Notifier 확장 클래스 선언
class CustomThemeNotifier extends Notifier<CustomThemeState> {
  // 필수 override 메서드
  @override
  CustomThemeState build() {
    return CustomThemeState.init();
  }

  // 테마 변경 메서드
  void toggleThemeMode() {
    // ThemeModeEnum
    final ThemeModeEnum themeModeEnum =
        state.themeModeEnum == ThemeModeEnum.dark
            ? ThemeModeEnum.light
            : ThemeModeEnum.dark;

    // ThemeColor
    final ThemeColor themeColor =
        state.themeModeEnum == ThemeModeEnum.dark
            ? LightThemeColor()
            : DarkThemeColor();

    // 상태관리 변경
    state = state.copyWith(
      themeColor: themeColor,
      themeModeEnum: themeModeEnum,
    );
  }
}
