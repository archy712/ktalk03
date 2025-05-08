import 'package:flutter_riverpod/flutter_riverpod.dart';

// riverpod 전역변수
final loaderProvider = NotifierProvider<LoaderNotifier, bool>(
  () => LoaderNotifier(),
);

// Notifier 확장 클래스
class LoaderNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void show() {
    state = true;
  }

  void hide() {
    state = false;
  }
}
