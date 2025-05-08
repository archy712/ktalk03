import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ktalk03/auth/providers/auth_provider.dart';
import 'package:ktalk03/chat/screens/chat_list_screen.dart';
import 'package:ktalk03/common/providers/custom_theme_provider.dart';
import 'package:ktalk03/common/providers/locale_provider.dart';
import 'package:ktalk03/common/providers/theme_mode_enum.dart';
import 'package:ktalk03/common/utils/global_navigator.dart';
import 'package:ktalk03/common/utils/locale/generated/l10n.dart';
import 'package:ktalk03/common/utils/logger.dart';
import 'package:ktalk03/friend/screens/friend_list_screen.dart';

class MainLayoutScreen extends ConsumerStatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen> {
  @override
  void initState() {
    super.initState();
    // 화면이 처음 실행될 때 현재 접속중인 사용자 정보 받아옴
    _getCurrentUserData();
  }

  // 현재 사용자 정보 얻기
  Future<void> _getCurrentUserData() async {
    try {
      await ref.read(authProvider.notifier).getCurrentUserData();
    } catch (e, stackTrace) {
      logger.e(e);
      logger.d(stackTrace);
      GlobalNavigator.showAlertDialog(msg: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    // localeProvider 가져와서 사용
    final Locale locale = ref.watch(localeProvider);

    // 현재 테마 조회
    final ThemeModeEnum themeModeEnum =
        ref.watch(customThemeProvider).themeModeEnum;

    return DefaultTabController(
      // 탭 전환 애니메이션 => 삭제
      animationDuration: Duration.zero,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.current.mainLayoutScreenText1),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.person, size: 30),
                iconMargin: EdgeInsets.only(bottom: 1),
                text: S.current.mainLayoutScreenText2,
              ),
              Tab(
                icon: Icon(Icons.chat_bubble_rounded, size: 30),
                iconMargin: EdgeInsets.only(bottom: 1),
                text: S.current.mainLayoutScreenText3,
              ),
              Tab(
                icon: Icon(Icons.wechat_rounded, size: 30),
                iconMargin: EdgeInsets.only(bottom: 1),
                text: S.current.mainLayoutScreenText4,
              ),
            ],
          ),
        ),
        endDrawer: Drawer(
          child: Column(
            children: [
              SizedBox(
                height: 100,
                child: DrawerHeader(
                  child: Text(
                    S.current.mainLayoutScreenText5,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // 로그아웃
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(S.current.mainLayoutScreenText6),
                onTap: () => FirebaseAuth.instance.signOut(),
              ),
              // 테마 선택 (스위치 버튼)
              SwitchListTile(
                secondary: const Icon(Icons.brightness_6),
                title: Text(S.current.mainLayoutScreenText7),
                activeColor: Colors.grey,
                value: themeModeEnum == ThemeModeEnum.light,
                onChanged: (value) {
                  ref.read(customThemeProvider.notifier).toggleThemeMode();
                },
              ),
              ListTile(
                leading: Icon(Icons.language),
                title: Text(S.current.language),
              ),
              RadioListTile(
                title: const Text('한국어'),
                value: const Locale('ko'),
                groupValue: locale,
                onChanged: (value) {
                  ref
                      .read(localeProvider.notifier)
                      .changeLocale(locale: value!);
                },
              ),
              RadioListTile(
                title: const Text('English'),
                value: const Locale('en'),
                groupValue: locale,
                onChanged: (value) {
                  ref
                      .read(localeProvider.notifier)
                      .changeLocale(locale: value!);
                },
              ),
              RadioListTile(
                title: const Text('日本語'),
                value: const Locale('ja'),
                groupValue: locale,
                onChanged: (value) {
                  ref
                      .read(localeProvider.notifier)
                      .changeLocale(locale: value!);
                },
              ),
            ],
          ),
        ),
        body: const TabBarView(
          // 화면 스와이프 금지
          physics: NeverScrollableScrollPhysics(),
          children: [
            FriendListScreen(),
            ChatListScreen(),
            Center(child: Text('3번')),
          ],
        ),
      ),
    );
  }
}
