import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ktalk03/auth/providers/auth_provider.dart';
import 'package:ktalk03/auth/screens/phone_number_input_screen.dart';
import 'package:ktalk03/auth/screens/user_information_screen.dart';
import 'package:ktalk03/common/providers/custom_theme_provider.dart';
import 'package:ktalk03/common/providers/custom_theme_state.dart';
import 'package:ktalk03/common/providers/loader_provider.dart';
import 'package:ktalk03/common/providers/locale_provider.dart';
import 'package:ktalk03/common/providers/theme_mode_enum.dart';
import 'package:ktalk03/common/screens/main_layout_screen.dart';
import 'package:ktalk03/common/utils/global_navigator.dart';
import 'package:ktalk03/common/utils/logger.dart';
import 'package:ktalk03/firebase_options.dart';
import 'package:ktalk03/router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:permission_handler/permission_handler.dart';

import 'common/utils/locale/generated/l10n.dart';

// showDialog() 함수를 화면 어디서나 쓰기 위해 GlobalKey 객체 선언
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 연락처 권한 요청 함수
Future<void> requestPermission() async {
  // 연락처 접근 권한 요청을 요청 상태에 담음
  final PermissionStatus contactPermissionStatus =
      await Permission.contacts.request();

  // isDenied : 계속 요청할 수 있음
  // isPermanentlyDenied : 영구 거부 상태 > 권한 요청 메시지가 뜨지 않음 : 앱 사용 불가 상태
  // 앱 정보 상태를 보여줘서 사용자가 직접 권한을 바꾸도록 앱 세팅 화면 보여줌
  if (contactPermissionStatus.isDenied ||
      contactPermissionStatus.isPermanentlyDenied) {
    // 현재 실행중인 앱 정보를 보여줌 (설정/제어판의 앱 정보)
    await openAppSettings();
    // 실행중인 앱은 종료 처리
    SystemNavigator.pop();
  }
}

void main() async {
  // main 함수에서 Native 기능을 사용하기 위한 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 에러 처리 테스트를 위해 임시로 로그아웃
  //await FirebaseAuth.instance.signOut();

  // 연락처 권한 요청
  await requestPermission();

  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 상태관리 데이터가 초기화 될 때 (init 메서드) 현재 기기의 테마모드를 알아냄
    final CustomThemeState customThemeState = ref.watch(customThemeProvider);

    // 상태관리 데이터에 따른 ThemeData 설정 (dark or light)
    final ThemeData themeData =
        customThemeState.themeModeEnum == ThemeModeEnum.dark
            ? ThemeData.dark()
            : ThemeData.light();

    // context 없이 로딩을 보여주기 위한 bool 상태 : riverpod listen
    ref.listen(loaderProvider, (previous, next) {
      //logger.d('previous: $previous // next: $next');
      next ? context.loaderOverlay.show() : context.loaderOverlay.hide();
    });

    // Locale 받아오기
    final Locale locale = ref.watch(localeProvider);

    return GlobalLoaderOverlay(
      //useDefaultLoading: false,
      overlayColor: const Color.fromRGBO(0, 0, 0, 0.4),
      overlayWidgetBuilder:
          (_) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        onGenerateRoute: (settings) => generateRoute(settings),
        theme: themeData.copyWith(
          scaffoldBackgroundColor: customThemeState.themeColor.background1Color,
          appBarTheme: AppBarTheme(
            backgroundColor: customThemeState.themeColor.background1Color,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: customThemeState.themeColor.text1Color,
            ),
          ),
          tabBarTheme: TabBarTheme(
            indicatorColor: Colors.transparent,
            labelColor: customThemeState.themeColor.text1Color,
            unselectedLabelColor: Colors.grey.withValues(alpha: 0.7),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: customThemeState.themeColor.text1Color,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.yellow,
            foregroundColor: Colors.black,
          ),
          dividerTheme: DividerThemeData(
            color: Colors.grey.withValues(alpha: 0.2),
            indent: 15,
            endIndent: 15,
          ),
        ),
        home: Main(),
      ),
    );
  }
}

// Main 클래스
class Main extends ConsumerWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 사용자 인증을 하는 StreamProvider 호출
    final AsyncValue<User?> auth = ref.watch(authStateProvider);

    return Scaffold(
      body: auth.when(
        data: (User? user) {
          // 로딩화면 삭제
          context.loaderOverlay.hide();

          if (user == null) {
            // 현재 로그아웃 상태 => 전화번호 입력 화면으로 이동 처리
            return const PhoneNumberInputScreen();
          }

          // init() 상태일 경우 => DB 회원가입 + 프로필 등록 페이지로 분기
          if (user.displayName == null || user.displayName!.isEmpty) {
            return const UserInformationScreen();
          }

          //return const Center(child: Text('메인화면'));
          return MainLayoutScreen();
        },
        error: (error, stackTrace) {
          // 로딩화면 제거 + 터치 가능
          context.loaderOverlay.hide();
          GlobalNavigator.showAlertDialog(msg: error.toString());

          logger.e(error);
          logger.e(stackTrace);
          return null;
        },
        loading: () {
          // User 정보를 가져오는 동안 표시
          context.loaderOverlay.show();
          return null;
        },
      ),
    );
  }
}
