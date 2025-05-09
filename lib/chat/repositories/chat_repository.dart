import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ktalk03/auth/models/user_model.dart';
import 'package:ktalk03/chat/models/message_model.dart';
import 'package:ktalk03/common/enum/message_enum.dart';
import 'package:ktalk03/common/models/chat_model.dart';
import 'package:ktalk03/common/utils/logger.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

// Repository Riverpod 전역 변수
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    firebaseFirestore: FirebaseFirestore.instance,
    firebaseAuth: FirebaseAuth.instance,
    firebaseStorage: FirebaseStorage.instance,
  );
});

// Repository Class
class ChatRepository {
  final FirebaseFirestore firebaseFirestore;
  final FirebaseAuth firebaseAuth;
  final FirebaseStorage firebaseStorage;

  // constructor
  const ChatRepository({
    required this.firebaseFirestore,
    required this.firebaseAuth,
    required this.firebaseStorage,
  });

  // 채팅방 생성
  Future<ChatModel> _createdChat({
    required List<UserModel> userModelList,
  }) async {
    try {
      // chats DocumentReference 얻기
      final DocumentReference<Map<String, dynamic>> chatDocRef =
          firebaseFirestore.collection('chats').doc();

      // ChatModel 생성
      final ChatModel chatExtModel = ChatModel(
        id: chatDocRef.id,
        userList: userModelList,
        lastMessage: '',
        createdAt: Timestamp.now(),
      );

      // 2가지 작업 : 트랜잭션 처리
      await firebaseFirestore.runTransaction((transaction) async {
        // 작업 1 : chats 컬렉션에 채팅방 정보 저장
        transaction.set(chatDocRef, chatExtModel.toMap());

        // 작업 2 : users 컬렉션 > uid > chats 컬렉션 > chats 컬렉션 id > chats 문서
        for (var userModel in userModelList) {
          final userChatsDocRef = firebaseFirestore
              .collection('users')
              .doc(userModel.uid)
              .collection('chats')
              .doc(chatDocRef.id);
          transaction.set(userChatsDocRef, chatExtModel.toMap());
        }
      });
      return chatExtModel;
    } catch (_) {
      rethrow;
    }
  }

  // 친구 목록 화면에서 친구를 클릭해서 채팅방 생성 후 DB 저장
  Future<ChatModel> enterChatFromFriendList({
    required Contact selectedContact,
  }) async {
    try {
      // 내가 터치한 친구의 전화번호 (폰코드가 붙어 있는 전화번호)
      // 예) +82 1011111111
      final String phoneNumber = selectedContact.phones.first.normalizedNumber;

      // 터치한 친구의 전화번호와 같은 phoneNumbers 컬렉션의 uid 가져옴
      // then() : get() 함수 로직이 끝날때까지 기다린 다음 반환환 데이터를 value에 대입
      // value.data() 함수를 호출하여 Map 중 uid 값만 받아옴
      final String userId = await firebaseFirestore
          .collection('phoneNumbers')
          .doc(phoneNumber)
          .get()
          .then((value) => value.data()!['uid']);

      // 현재 접속한 사용자 uid
      final String currentUserId = firebaseAuth.currentUser!.uid;

      // 현재 접속한 사용자와 친구를 묶어 사용자 배열(List) 만들고 : [현재접속자, 채팅상대방]
      final List<UserModel> userModelList = [
        // 현재 접속한 사용자 [모델]
        await firebaseFirestore
            .collection('users')
            .doc(currentUserId)
            .get()
            .then((value) => UserModel.fromMap(value.data()!)),

        // 터치한 친구 [모델]
        await firebaseFirestore
            .collection('users')
            .doc(userId)
            .get()
            .then((value) => UserModel.fromMap(value.data()!)),
      ];

      // 친구와의 채팅방이 기존에 존재 했는지 검사
      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await firebaseFirestore
              .collection('users')
              .doc(currentUserId)
              .collection('chats')
              .where('userList', arrayContains: userId)
              .limit(1)
              .get();

      // 상대방과의 채팅방이 없다면 채팅방 생성
      if (querySnapshot.docs.isEmpty) {
        return await _createdChat(userModelList: userModelList);
      }

      // 채팅방 정보가 있다면 현재 채팅방 정보 리턴
      return ChatModel.fromMap(
        map: querySnapshot.docs.first.data(),
        userList: userModelList,
      );
    } catch (_) {
      rethrow;
    }
  }

  // 메시지 전송
  Future<void> sendMessage({
    // 메시지 내용 : nullable 이유 > 이미지/동영상 데이터 일때
    String? text,
    // 전송할 파일
    File? file,
    // 채팅방 모델
    required ChatModel chatModel,
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
      chatModel = chatModel.copyWith(
        createdAt: Timestamp.now(),
        // 채팅 목록 화면에 보여줄 마지막 메시지
        lastMessage: text,
      );

      // 1> firestore 루트의 chats 정보 업데이트 준비
      final DocumentReference<Map<String, dynamic>> chatDocRef =
          firebaseFirestore.collection('chats').doc(chatModel.id);

      // 2> firestore 에 message 컬렉션 저장을 위한 DocumentReference
      final DocumentReference<Map<String, dynamic>> messageDocRef =
          firebaseFirestore
              .collection('chats')
              .doc(chatModel.id)
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
            .child('chat')
            .child(chatModel.id)
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
        // 1> 최상단 chats 컬렉션
        transaction.set(chatDocRef, chatModel.toMap());

        // 2> chats 컬렉션 > id > messages 컬렉션 > id > messageModel.toMap()
        transaction.set(messageDocRef, messageModel.toMap());

        // 3> users 컬렉션 > id > chats 컬렉션 > id > chatModel.toMap()
        for (final UserModel userModel in chatModel.userList) {
          transaction.set(
            firebaseFirestore
                .collection('users')
                .doc(userModel.uid)
                .collection('chats')
                .doc(chatModel.id),
            chatModel.toMap(),
          );
        }
      });
    } catch (_) {
      rethrow;
    }
  }

  // 채팅방 메시지 가져오기
  Future<List<MessageModel>> getMessageList({
    required String chatId,
    // 새로운 메시지 추가
    String? lastMessageId,
    // 화면에 보여줄 첫번째 메시지
    String? firstMessageId,
  }) async {
    try {
      // 생성된 메시지의 생성일 기준 끝에서 20개
      // query, snapshot 작성을 나눠서 한 이유 : 추후 조건 추가 위함
      Query<Map<String, dynamic>> messagesQuery = firebaseFirestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt')
          .limitToLast(20); // 20개씩 끊어서

      // 마지막 이후 작성된 메시지만 가져오기
      if (lastMessageId != null) {
        final DocumentSnapshot<Map<String, dynamic>> lastDocSnapshot =
            await firebaseFirestore
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .doc(lastMessageId)
                .get();

        messagesQuery = messagesQuery.startAfterDocument(lastDocSnapshot);
      } else if (firstMessageId != null) {
        // 첫번째 메시지에 해당하는 문서 객체를 가지고 와서
        final DocumentSnapshot<Map<String, dynamic>> firstDocSnapshot =
            await firebaseFirestore
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .doc(firstMessageId)
                .get();

        // 기존 쿼리 조건에 추가
        // 첫번쨰 메시지 이후 20개 (위의 limitToLast 조건) 데이터 가져오기
        messagesQuery = messagesQuery.endBeforeDocument(firstDocSnapshot);
      }

      // 데이터 가져오기
      final QuerySnapshot<Map<String, dynamic>> messagesSnapshot =
          await messagesQuery.get();

      // Future.wait() 함수 내부의 값이 List<Future<MessageModel>> 형태로 반환되는 이유
      // => map() 함수 내부에서 async ~ await 사용해서
      //
      // 해결 방안 : map() 함수 순회의 모든 요소들의 async ~ await 처리를 기다림
      // 기다리는 방법 : await Future.wait(작업들);
      // 최종 리턴 타입 : Future<List<MessageModel>>
      return await Future.wait(
        // 메시지들을 순회 하면서 처리
        messagesSnapshot.docs.map((messageDoc) async {
          // 사용자 정보 받아오고
          final UserModel userModel = await firebaseFirestore
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

  // 채팅방 리스트 가져오기 (Stream 방식)
  // 데이터를 가져올 때 asyncMap() 함수를 사용해서
  // Stream 에서 비동기 작업을 하고 새로운 Stream 생성을 해서 반환.
  Stream<List<ChatModel>> getChatList({required UserModel currentUserModel}) {
    try {
      return firebaseFirestore
          .collection('users')
          .doc(currentUserModel.uid)
          .collection('chats')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .asyncMap((QuerySnapshot<Map<String, dynamic>> snapshot) async {
            // 채팅 정보를 담을 리스트
            List<ChatModel> chatModelList = [];

            // 문서를 순회하면서 ChatModel 변환 후 add
            for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
                in snapshot.docs) {
              // 채팅 상대방 UserModel 구하기 위해 변수 초기화
              UserModel opponentUserModel = UserModel.init();

              // 순회할 문서를 하나 받아서 변수에 저장
              final Map<String, dynamic> chatData = doc.data();

              // map 형태의 userId 리스트를 List<String> 형태로 반환
              List<String> userIdList = List<String>.from(chatData['userList']);

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
              final ChatModel chatModel = ChatModel.fromMap(
                map: chatData,
                userList: [currentUserModel, opponentUserModel],
              );

              // 채팅 모델을 반환할 List에 담음
              chatModelList.add(chatModel);
            }

            return chatModelList;
          });
    } catch (_) {
      rethrow;
    }
  }

  // 채팅방 나가기
  Future<void> exitChat({
    required ChatModel chatModel,
    required String currentUserId,
  }) async {
    try {
      // chats : 맨 바깥의 채팅방 참조 얻기
      final DocumentReference<Map<String, dynamic>> chatsDocRef =
          firebaseFirestore.collection('chats').doc(chatModel.id);

      // users > chats 참조 얻기
      final DocumentReference<Map<String, dynamic>> usersChatsDocRef =
          firebaseFirestore
              .collection('users')
              .doc(currentUserId)
              .collection('chats')
              .doc(chatModel.id);

      // 트랜잭션 처리
      await firebaseFirestore.runTransaction((transaction) async {
        // 1-1> 맨 바깥의 chats 컬렉션에서 내 ID 삭제
        transaction.update(chatsDocRef, {
          'userList': FieldValue.arrayRemove([currentUserId]),
        });

        // 채팅 상대방의 ID의 채팅방에서 내 ID 삭제
        for (final UserModel userModel in chatModel.userList) {
          // 현재 접속중인 유저가 (나?) 라면 건너뛰기
          if (userModel.uid == currentUserId || userModel.uid.isEmpty) continue;

          // 상대방 ID 참여 채팅방 참조 얻어서
          final DocumentReference<Map<String, dynamic>> opponentChatDocRef =
              firebaseFirestore
                  .collection('users')
                  .doc(userModel.uid)
                  .collection('chats')
                  .doc(chatModel.id);

          // 1-2> 내 ID 삭제
          transaction.update(opponentChatDocRef, {
            'userList': FieldValue.arrayRemove([currentUserId]),
          });

          // 삭제된 내 ID 대신 빈 문자열, 날짜 업데이트
          transaction.update(opponentChatDocRef, {
            'userList': FieldValue.arrayUnion(['']),
            'createdAt': Timestamp.now(),
          });
        }

        // 2>번 내가 참여중인 채팅방 삭제 : users > chats
        transaction.delete(usersChatsDocRef);
      });
    } catch (_) {
      rethrow;
    }
  }
}
