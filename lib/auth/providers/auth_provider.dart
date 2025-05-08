import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ktalk03/auth/models/user_model.dart';
import 'package:ktalk03/auth/providers/auth_state.dart';
import 'package:ktalk03/auth/repositories/auth_repository.dart';
import 'package:ktalk03/common/providers/loader_provider.dart';
import 'package:ktalk03/common/utils/logger.dart';

// 사용자 인증을 위한 Provider
final StreamProvider<User?> authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

// riverpod 전역변수 선언
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);

// Notifier 확장 클래스
class AuthNotifier extends Notifier<AuthState> {
  // 인증 Repository
  late AuthRepository authRepository;

  // 로딩 Notifier 확장 클래스
  late LoaderNotifier loaderNotifier;

  // 상태 초기화 리턴
  @override
  AuthState build() {
    authRepository = ref.watch(authRepositoryProvider);
    loaderNotifier = ref.watch(loaderProvider.notifier);
    return AuthState.init();
  }

  // OTP 전송
  Future<void> sendOTP({required String phoneNumber}) async {
    try {
      loaderNotifier.show();

      await authRepository.sendOTP(phoneNumber: phoneNumber);
    } catch (_) {
      rethrow;
    } finally {
      loaderNotifier.hide();
    }
  }

  // OTP 인증
  Future<void> verifyOTP({required String userOTP}) async {
    try {
      loaderNotifier.show();

      await authRepository.verifyOTP(userOTP: userOTP);
    } catch (_) {
      rethrow;
    } finally {
      loaderNotifier.hide();
    }
  }

  // 사용자 정보 저장
  Future<void> saveUserData({
    required String name,
    required File? profileImage,
  }) async {
    try {
      loaderNotifier.show();

      final UserModel userModel = await authRepository.saveUserData(
        name: name,
        profileImage: profileImage,
      );

      // 로그인이 되면 상태정보를 저장
      state = state.copyWith(userModel: userModel);
    } catch (_) {
      rethrow;
    } finally {
      loaderNotifier.hide();
    }
  }

  // 현재 접속중인 사용자 정보 얻기
  Future<void> getCurrentUserData() async {
    try {
      final UserModel userModel = await authRepository.getCurrentUserData();

      state = state.copyWith(userModel: userModel);
    } catch (_) {
      rethrow;
    }
  }
}
