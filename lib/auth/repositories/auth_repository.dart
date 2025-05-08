import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ktalk03/auth/models/user_model.dart';
import 'package:ktalk03/common/utils/logger.dart';
import 'package:mime/mime.dart';

// Provider 선언
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    firebaseAuth: FirebaseAuth.instance,
    firebaseStorage: FirebaseStorage.instance,
    firebaseFirestore: FirebaseFirestore.instance,
  ),
);

// AuthRepository
class AuthRepository {
  // FirebaseAuth : 생성 시 인자로 받음
  final FirebaseAuth firebaseAuth;

  // FirebaseStorage
  final FirebaseStorage firebaseStorage;

  // FirebaseFirestore
  final FirebaseFirestore firebaseFirestore;

  AuthRepository({
    required this.firebaseAuth,
    required this.firebaseStorage,
    required this.firebaseFirestore,
  });

  // 인증 ID
  String? _verificationId;

  // OTP 전송
  Future<void> sendOTP({required String phoneNumber}) async {
    try {
      await firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        // 인증번호 전송 후 실행할 로직
        // 1번째 인자 verificationId : 전송받은 인증번호를 제대로 화면에 입력했는지 확인할 때 필요 변수
        // 2번째 인자 forceResendingToken : 인증번호 재전송 시 필요 변수
        codeSent: (verificationId, _) {
          // 클래스 내부 변수에 저장
          _verificationId = verificationId;
        },
        // 전달받은 인증번호를 자동으로 입력하는 기능 (여기서는 사용 안함)
        verificationCompleted: (_) {},
        // 인증 실패 시 실행할 로직
        verificationFailed: (error) {
          logger.e(error.message);
          logger.e(error.stackTrace);
        },
        // 코드입력 제한시간 초과 시 실행할 로직
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (_) {
      rethrow;
    }
  }

  // OTP 인증
  Future<void> verifyOTP({required String userOTP}) async {
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: userOTP,
      );

      await firebaseAuth.signInWithCredential(credential);
    } catch (_) {
      rethrow;
    }
  }

  // 사용자 정보 저장
  Future<UserModel> saveUserData({
    required String name,
    required File? profileImage,
  }) async {
    // 업로드 후 [프로필 이미지] 다운로드 경로
    String? photoUrl;

    try {
      // DB 트랜잭션 처리를 위해 WriteBatch 선언
      WriteBatch writeBatch = firebaseFirestore.batch();

      // 로그인 상태에서 진행하기 때문에 null 아님
      final String uid = firebaseAuth.currentUser!.uid;

      // 프로필 이미지 저장
      if (profileImage != null) {
        final String? mimeType = lookupMimeType(profileImage.path);
        final SettableMetadata metaData = SettableMetadata(
          contentType: mimeType,
        );

        // 프로필 이미지 스토리지 저장
        final TaskSnapshot taskSnapshot = await firebaseStorage
            .ref()
            .child('profile')
            .child(uid)
            .putFile(profileImage, metaData);

        // 다운로드 경로 변수 저장
        photoUrl = await taskSnapshot.ref.getDownloadURL();
      }

      // Firestore 저장 처리
      final UserModel userModel = UserModel(
        displayName: name,
        uid: uid,
        photoURL: photoUrl,
        phoneNumber: firebaseAuth.currentUser!.phoneNumber!,
      );

      // [users] DocumentReference
      final DocumentReference<Map<String, dynamic>> currentUserDocRef =
          firebaseFirestore.collection('users').doc(uid);

      // [phoneNumbers] DocumentReference
      final DocumentReference<Map<String, dynamic>> currentPhoneNumbersDocRef =
          firebaseFirestore
              .collection('phoneNumbers')
              .doc(firebaseAuth.currentUser!.phoneNumber!);

      // DocumentReference 사용하여 각각의 Collection 저장
      // await currentUserDocRef.set(userModel.toMap());
      // await currentPhoneNumbersDocRef.set({'uid': uid});

      // 2개의 컬렉션 작업을 해야 하므로 트랜잭션 처리
      // 1번째 인자 : 저장하려고 하는 컬렉션의 DocumentReference
      // 2번째 인자 : 저장하려고 하는 Map 타입 데이터
      writeBatch.set(currentUserDocRef, userModel.toMap());
      writeBatch.set(currentPhoneNumbersDocRef, {'uid': uid});
      await writeBatch.commit();

      // FirebaseAuth 정보 업데이트
      // 메인화면에서 인증값에 따라 분기를 할 때 이 값을 사용 예정
      await firebaseAuth.currentUser!.updateDisplayName(name);

      return userModel;
    } catch (_) {
      // 데이터 저장 중에 오류가 발생할 경우 이미지가 저장 되었다면 삭제
      if (photoUrl != null) {
        await firebaseStorage.refFromURL(photoUrl).delete();
      }

      rethrow;
    }
  }

  // 현재 접속중인 사용자 정보 얻기
  Future<UserModel> getCurrentUserData() async {
    try {
      final UserModel userModel = await firebaseFirestore
          .collection('users')
          .doc(firebaseAuth.currentUser!.uid)
          .get()
          .then((value) => UserModel.fromMap(value.data()!));

      return userModel;
    } catch (_) {
      rethrow;
    }
  }
}
