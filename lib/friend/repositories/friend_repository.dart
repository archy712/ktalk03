import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extended_image/extended_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ktalk03/auth/models/user_model.dart';

// FriendRepositoryProvider [Riverpod] 전역변수 선언
final friendRepositoryProvider = Provider<FriendRepository>(
  (ref) => FriendRepository(
    firebaseFirestore: FirebaseFirestore.instance,
    firebaseAuth: FirebaseAuth.instance,
  ),
);

// FriendRepository
class FriendRepository {
  final FirebaseFirestore firebaseFirestore;
  final FirebaseAuth firebaseAuth;

  const FriendRepository({
    required this.firebaseFirestore,
    required this.firebaseAuth,
  });

  // 연락처 List 값들을 순회 하면서 Firestore에 저장된 값들과 비교
  // 나를 제외한 일치하는 연락처를 새로운 List<Contact> 에 저장
  Future<List<Contact>> getFriendList() async {
    try {
      // User? 상태관리 데이터에서 나의 전화번호 가져옴
      final String? myPhoneNumber = firebaseAuth.currentUser!.phoneNumber;

      // 새롭게 저장할 연락처 리스트
      List<Contact> result = [];

      // 핸드폰에 저장된 연락처를 List<Contact> 형태로 가져옴
      List<Contact> contacts = await FlutterContacts.getContacts(
        // Contact의 모든 요소를 다 가지고 오려면 아래 속성 추가
        withProperties: true,
      );

      // 가져온 연락처의 모든 요소를 순회 => 새롭게 저장할 연락처 리스트에 add
      for (final Contact contact in contacts) {
        // 연락처의 전화번호 가져오기 (첫번째 요소 null 가능성 존재)
        // normalizedNumber : 연락처의 전화번호1 저장되어 있는 속성
        final String? phoneNumber =
            contact.phones.firstOrNull?.normalizedNumber;

        // 전화번호가 null 이거나 내 전화번호이면 skip 처리
        if (phoneNumber == null || phoneNumber == myPhoneNumber) continue;

        // firestore 에서 같은 전화번호 검색
        final QuerySnapshot<Map<String, dynamic>> querySnapshot =
            await firebaseFirestore
                .collection('phoneNumbers')
                .where(FieldPath.documentId, isEqualTo: phoneNumber)
                .get();

        // 같은 전화번호가 없다면 skip
        if (querySnapshot.docs.isEmpty) continue;

        // 같은 전화번호가 있다면 첫번째 문서의 uid 얻기
        final String uid = querySnapshot.docs.first.data()['uid'];

        // users 컬렉션에서 uid 일치하는 문서 얻기
        final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
            await firebaseFirestore.collection('users').doc(uid).get();

        // 얻은 문서로부터 UserModel 객체 얻기
        final UserModel userModel = UserModel.fromMap(documentSnapshot.data()!);

        // 연락처 이름 업데이트
        contact.displayName = userModel.displayName;

        // 프로필 이미지도 회원가입 할 때 받은 이미지로 업데이트
        // photo : Uint8List? 타입
        if (userModel.photoURL != null) {
          contact.photo =
              await ExtendedNetworkImageProvider(
                userModel.photoURL!,
              ).getNetworkImageData();
        }

        // 연락처를 리턴할 List에 저장
        result.add(contact);
      }

      // 갱신된 연락처 리스트 리턴
      return result;
    } catch (_) {
      rethrow;
    }
  }
}
