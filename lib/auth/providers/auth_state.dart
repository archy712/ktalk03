import 'package:ktalk03/auth/models/user_model.dart';

class AuthState {
  // 사용자 모델
  final UserModel userModel;

  // 생성자
  const AuthState({required this.userModel});

  // factory 생성자
  factory AuthState.init() {
    return AuthState(userModel: UserModel.init());
  }

  // copyWith
  AuthState copyWith({UserModel? userModel}) {
    return AuthState(userModel: userModel ?? this.userModel);
  }
}
