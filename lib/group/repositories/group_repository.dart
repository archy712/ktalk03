import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ktalk03/auth/models/user_model.dart';
import 'package:ktalk03/chat/models/message_model.dart';
import 'package:ktalk03/common/enum/message_enum.dart';
import 'package:ktalk03/group/models/group_model.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

// Provider
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(
    firebaseAuth: FirebaseAuth.instance,
    firebaseFirestore: FirebaseFirestore.instance,
    firebaseStorage: FirebaseStorage.instance,
  );
});

// Repository
class GroupRepository {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;
  final FirebaseStorage firebaseStorage;

  const GroupRepository({
    required this.firebaseAuth,
    required this.firebaseFirestore,
    required this.firebaseStorage,
  });

  // 그룹 채팅방 생성
  Future<GroupModel> createGroup({
    // 그룹 채팅방 프로필 이미지
    required File? groupImage,
    // 그룹 채팅방 생성을 위한 선택한 사용자 리스트
    required List<Contact> selectedFriendList,
    // 현재 사용자
    required UserModel currentUserModel,
    // 채팅방 이름
    required String groupName,
  }) async {
    // 그룹 채팅방 프로필 이미지 경로
    String? photoUrl;

    try {
      // 그룹 채팅방 컬렉션 레퍼런스
      final DocumentReference<Map<String, dynamic>> groupDocRef =
          firebaseFirestore.collection('groups').doc();

      // 그룹 채팅방 프로필 이미지 저장
      if (groupImage != null) {
        // 파일 유형을 정하기 위한 작업
        final String? mimeType = lookupMimeType(groupImage.path);
        final SettableMetadata metadata = SettableMetadata(
          contentType: mimeType,
        );

        final TaskSnapshot taskSnapshot = await firebaseStorage
            .ref()
            .child('group')
            .child(groupDocRef.id)
            .putFile(groupImage, metadata);

        // 다운로드 경로 저장
        photoUrl = await taskSnapshot.ref.getDownloadURL();
      }

      // 채팅에 참여하는 유저의 데이터를 UserModel 객체로 만들어 리스트 추가
      final List<UserModel> userList = await Future.wait(
        selectedFriendList.map((contact) async {
          // 내가 터치한 친구의 전화번호 (폰코드가 붙어 있는 전화번호)
          final String phoneNumber = contact.phones.first.normalizedNumber;

          // 터치한 친구의 전화번호와 같은 phoneNumbers 컬렉션의 uid 가져옴
          // then() : get() 함수 로직이 끝날때까지 기다린 다음 반환된 데이터를 value에 대입
          // value.data() 함수를 호출하여 Map 중 uid 값만 받아옴
          final userId = await firebaseFirestore
              .collection('phoneNumbers')
              .doc(phoneNumber)
              .get()
              .then((value) => value.data()!['uid']);

          // 터치한 친구 [모델]
          return await firebaseFirestore
              .collection('users')
              .doc(userId)
              .get()
              .then((value) => UserModel.fromMap(value.data()!));
        }).toList(),
      );

      // 선택한 사용자와 '나'를 추가로 포함
      userList.add(currentUserModel);

      // 그룹 채팅방 저장을 위한 모델 생성
      final GroupModel groupModel = GroupModel(
        id: groupDocRef.id,
        userList: userList,
        lastMessage: '',
        groupName: groupName,
        groupImageUrl: photoUrl,
        createdAt: Timestamp.now(),
      );

      // 트랜잭션으로 데이터베이스 처리 (groups, users > groups)
      await firebaseFirestore.runTransaction((transaction) async {
        // groups 컬렉션 저장
        transaction.set(groupDocRef, groupModel.toMap());

        // users 컬렉션 > groups 컬렉션 저장
        for (final UserModel userModel in userList) {
          final usersGroupDocRef = firebaseFirestore
              .collection('users')
              .doc(userModel.uid)
              .collection('groups')
              .doc(groupModel.id);

          transaction.set(usersGroupDocRef, groupModel.toMap());
        }
      });

      return groupModel;
    } catch (_) {
      // 저장된 그룹채팅방 프로필 이미지 존재한다면 삭제
      if (photoUrl != null) {
        await firebaseStorage.refFromURL(photoUrl).delete();
      }

      rethrow;
    }
  }

  // 그룹 메시지 전송
  Future<void> sendMessage({
    // 메시지 내용 : nullable 이유 > 이미지/동영상 데이터 일때
    String? text,
    // 전송할 파일
    File? file,
    // 채팅방 모델
    required GroupModel groupModel,
    // 메시지 작성한 유저의 정보
    required UserModel currentUserModel,
    // 메시지 타입
    required MessageEnum messageType,
    // 답변 시 답변 대상 Message
    required MessageModel? replyMessageModel,
  }) async {
    try {
      // 이미지/비디오일 경우 마지막 내용 표시
      if (messageType != MessageEnum.text) {
        text = messageType.toText();
      }

      // 먼저, 메시지를 전송하려고 하는 채팅방의 정보를 업데이트
      groupModel = groupModel.copyWith(
        createdAt: Timestamp.now(),
        // 채팅 목록 화면에 보여줄 마지막 메시지
        lastMessage: text,
      );

      // 1> firestore 루트의 groups 정보 업데이트 준비
      final DocumentReference<Map<String, dynamic>> groupDocRef =
          firebaseFirestore.collection('groups').doc(groupModel.id);

      // 2> firestore 에 message 컬렉션 저장을 위한 DocumentReference
      final DocumentReference<Map<String, dynamic>> messageDocRef =
          firebaseFirestore
              .collection('groups')
              .doc(groupModel.id)
              .collection('messages')
              .doc();

      // 텍스트가 아니라 이미지나 동영상 전송시에는 파일을 스토리지에 저장
      if (messageType != MessageEnum.text) {
        // mimeType 알아내서
        final String? mimeType = lookupMimeType(file!.path);
        // mimeType 전달
        final SettableMetadata metadata = SettableMetadata(
          contentType: mimeType,
        );
        // 저장할 파일 이름 + . + 확장자 : 예) image/png
        final String filename =
            '${const Uuid().v1()}.${mimeType!.split('/')[1]}';

        // 스토리지에 저장
        TaskSnapshot taskSnapshot = await firebaseStorage
            .ref()
            .child('group')
            .child(groupModel.id)
            .child(filename)
            .putFile(file, metadata);

        // 파일에 접근할 수 있는 경로 받아옴
        // 이미지/동영상의 경우 텍스트 메시지를 위한 text 파라미터 값에 대입
        text = await taskSnapshot.ref.getDownloadURL();
      }

      // 2> messages 컬렉션에 들어갈 MessageModel 데이터
      final MessageModel messageModel = MessageModel(
        userId: currentUserModel.uid,
        text: text!,
        type: messageType,
        createdAt: Timestamp.now(),
        messageId: messageDocRef.id,
        // 입력할 때 UserModel은 빈 값, 메시지 보여줄 때 담을 예정
        userModel: UserModel.init(),
        replyMessageModel: replyMessageModel,
      );

      // logger.d('messageModel : ${messageModel.toString()}');

      // firestore 데이터 저장 : 트랜잭션 처리
      await firebaseFirestore.runTransaction((transaction) async {
        // 1> 최상단 groups 컬렉션
        transaction.set(groupDocRef, groupModel.toMap());

        // 2> groups 컬렉션 > id > messages 컬렉션 > id > messageModel.toMap()
        transaction.set(messageDocRef, messageModel.toMap());

        // 3> users 컬렉션 > id > groups 컬렉션 > id > groupModel.toMap()
        for (final UserModel userModel in groupModel.userList) {
          if (userModel.uid != '') {
            transaction.set(
              firebaseFirestore
                  .collection('users')
                  .doc(userModel.uid)
                  .collection('groups')
                  .doc(groupModel.id),
              groupModel.toMap(),
            );
          }
        }
      });
    } catch (_) {
      rethrow;
    }
  }

  // 그룹 채팅방 조회 (Stream 방식)
  // 데이터를 가져올 때 asyncMap() 함수를 사용해서
  // Stream 에서 비동기 작업을 하고 새로운 Stream 생성을 해서 반환.
  Stream<List<GroupModel>> getGroupList({required UserModel currentUserModel}) {
    try {
      return firebaseFirestore
          .collection('users')
          .doc(currentUserModel.uid)
          .collection('groups')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .asyncMap((QuerySnapshot<Map<String, dynamic>> snapshot) async {
            // 채팅 정보를 담을 리스트
            List<GroupModel> groupModelList = [];

            // 문서를 순회하면서 ChatModel 변환 후 add
            for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
                in snapshot.docs) {
              // 채팅 상대방 UserModel 구하기 위해 변수 초기화
              UserModel opponentUserModel = UserModel.init();

              // 순회할 문서를 하나 받아서 변수에 저장
              final Map<String, dynamic> groupData = doc.data();

              // map 형태의 userId 리스트를 List<String> 형태로 반환
              List<String> userIdList = List<String>.from(
                groupData['userList'],
              );

              // 현재 접속중인 사용자의 UserModel은 파라미터로 받았기 때문에
              // 채팅 상대방의 UserModel 만들면 된다.
              final String opponentUserId = userIdList.firstWhere(
                (element) => element != currentUserModel.uid,
              );

              // 채팅 상대방의 UserModel 구해서
              if (opponentUserId.isNotEmpty) {
                opponentUserModel = await firebaseFirestore
                    .collection('users')
                    .doc(opponentUserId)
                    .get()
                    .then((value) => UserModel.fromMap(value.data()!));
              }

              // 채팅 모델을 생성
              final GroupModel groupModel = GroupModel.fromMap(
                map: groupData,
                userList: [currentUserModel, opponentUserModel],
              );

              // 채팅 모델을 반환할 List에 담음
              groupModelList.add(groupModel);
            }

            return groupModelList;
          });
    } catch (_) {
      rethrow;
    }
  }

  // 그룹채팅방에 메시지 가져오기
  Future<List<MessageModel>> getMessageList({
    required String groupId,
    String? lastMessageId,
    // 가장 상단의 메시지, 처음 20개 중에서 맨 마지막 메시지
    String? firstMessageId,
  }) async {
    try {
      // 전체 메시지를 날짜순으로 정렬해서 가져온 다음
      Query<Map<String, dynamic>> query = firebaseFirestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .orderBy('createdAt') // 날짜 순
          .limitToLast(20); // 20개씩 끊어서

      // 마지막 이후 작성된 메시지만 가져오기
      if (lastMessageId != null) {
        final lastDocRef =
            await firebaseFirestore
                .collection('groups')
                .doc(groupId)
                .collection('messages')
                .doc(lastMessageId)
                .get();
        // 기존 쿼리 조건에 추가
        // 마지막 문자 이후 데이터 20개 가져오기
        query = query.startAfterDocument(lastDocRef);
      } else if (firstMessageId != null) {
        // 첫번째 메시지에 해당하는 문서 객체를 가지고 와서
        final firstDocRef =
            await firebaseFirestore
                .collection('groups')
                .doc(groupId)
                .collection('messages')
                .doc(firstMessageId)
                .get();
        // 기존 쿼리 조건에 추가
        // 첫번째 메시지 이후 20개(위의 limit 조건) 데이터 가져오기
        query = query.endBeforeDocument(firstDocRef);
      }

      // 데이터 가져오기
      final snapshot = await query.get();

      // Future.wait() 함수 내부의 값이 List<Future<MessageModel>> 형태로 반환되는 이유
      // map() 함수 내부에서 async ~ await 사용해서
      // 해결 방안 : map() 함수 순회의 모든 요소들의 async ~ await 처리를 기다림
      // 기다리는 방법 : await Future.wait(작업);
      return await Future.wait(
        // 메시지들을 순회하면서 처리
        snapshot.docs.map((messageDoc) async {
          // 사용자 정보 받아오고
          final userModel = await firebaseFirestore
              .collection('users')
              .doc(messageDoc.data()['userId'])
              .get()
              .then((value) => UserModel.fromMap(value.data()!));
          // 메시지 모델로 변환 후 리턴
          return MessageModel.fromMap(messageDoc.data(), userModel);
        }).toList(),
      );
    } catch (_) {
      rethrow;
    }
  }

  // 그룹채팅방 나가기
  Future<void> exitGroup({
    required GroupModel groupModel,
    required String currentUserId,
  }) async {
    try {
      // groups : 맨 바깥의 채팅방 참조 얻기
      final groupsDocRef = firebaseFirestore
          .collection('groups')
          .doc(groupModel.id);

      // users > groups 참조 얻기
      final usersGroupsDocRef = firebaseFirestore
          .collection('users')
          .doc(currentUserId)
          .collection('groups')
          .doc(groupModel.id);

      // 트랜잭션 처리 (원본 소스 상에는 await 빠져 있음)
      await firebaseFirestore.runTransaction((transaction) async {
        // 맨 바깥의 chats 컬렉션에서 내 ID 삭제
        transaction.update(groupsDocRef, {
          'userList': FieldValue.arrayRemove([currentUserId]),
        });

        // 채팅 상대방 ID의 채팅방에서 내 ID 삭제
        for (final userModel in groupModel.userList) {
          // 현재 접속중인 유저가 (나?) 라면 건너뛰기
          if (userModel.uid == currentUserId || userModel.uid.isEmpty) continue;
          // 상대방 ID 참여 채팅방 참조 얻어서
          final usersGroupsDocRef = firebaseFirestore
              .collection('users')
              .doc(userModel.uid)
              .collection('groups')
              .doc(groupModel.id);
          // 내 ID 삭제
          transaction.update(usersGroupsDocRef, {
            'userList': FieldValue.arrayRemove([currentUserId]),
          });
          // 내 ID 대신 빈 문자열, 날짜 업데이트
          transaction.update(usersGroupsDocRef, {
            'userList': FieldValue.arrayUnion(['']),
            'createdAt': Timestamp.now(),
          });
        }

        // 2>번 내가 참여중인 채팅방 삭제 : users > chats
        transaction.delete(usersGroupsDocRef);
      });
    } catch (_) {
      rethrow;
    }
  }
}
