import 'dart:io';

import 'package:flutter_contacts/contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ktalk03/auth/models/user_model.dart';
import 'package:ktalk03/auth/providers/auth_provider.dart';
import 'package:ktalk03/chat/models/message_model.dart';
import 'package:ktalk03/chat/providers/chat_provider.dart';
import 'package:ktalk03/common/enum/message_enum.dart';
import 'package:ktalk03/common/providers/loader_provider.dart';
import 'package:ktalk03/group/models/group_model.dart';
import 'package:ktalk03/group/providers/group_state.dart';
import 'package:ktalk03/group/repositories/group_repository.dart';

// groupListProvider
// 채팅방 목록 조회는 실시간 스트림 기반이므로 별도 생성
final groupListProvider = StreamProvider.autoDispose<List<GroupModel>>((ref) {
  final currentUserModel = ref.watch(authProvider).userModel;
  return ref
      .watch(groupRepositoryProvider)
      .getGroupList(currentUserModel: currentUserModel);
});

// NotifierProvider 전역변수 선언
// final groupProvider = NotifierProvider<GroupNotifier, GroupState>(
//   GroupNotifier.new,
// );

final groupProvider = NotifierProvider<GroupNotifier, GroupState>(
  () => GroupNotifier(),
);

// Notifier 확장 클래스
class GroupNotifier extends Notifier<GroupState> {
  // 로딩 표시를 위해
  late LoaderNotifier loaderNotifier;

  // 그룹채팅방 Repository
  late GroupRepository groupRepository;

  // 현재 접속중인 사용자
  late UserModel currentUserModel;

  @override
  GroupState build() {
    loaderNotifier = ref.watch(loaderProvider.notifier);
    groupRepository = ref.watch(groupRepositoryProvider);
    currentUserModel = ref.watch(authProvider).userModel;

    return GroupState.init();
  }

  // 그룹 채팅방 생성
  Future<void> createGroup({
    required String groupName,
    required File? groupImage,
    required List<Contact> selectedFriendList,
  }) async {
    try {
      // 로딩 표시하고
      loaderNotifier.show();

      // Repository 처리 (프로필 이미지, 데이터베이스)
      final GroupModel groupModel = await groupRepository.createGroup(
        groupImage: groupImage,
        selectedFriendList: selectedFriendList,
        currentUserModel: currentUserModel,
        groupName: groupName,
      );

      // 상태관리 저장
      state = state.copyWith(model: groupModel);
    } catch (_) {
      rethrow;
    } finally {
      // 로딩 종료
      loaderNotifier.hide();
    }
  }

  // 메시지 전송
  Future<void> sendMessage({
    String? text,
    File? file,
    required MessageEnum messageType,
  }) async {
    try {
      await groupRepository.sendMessage(
        text: text,
        file: file,
        // state.model : baseModel 이므로 실제 받아야 할 값으로 캐스팅
        groupModel: state.model as GroupModel,
        currentUserModel: currentUserModel,
        messageType: messageType,
        replyMessageModel: ref.read(replyMessageModelProvider),
      );
    } catch (_) {
      rethrow;
    }

    // 일반 메시지는 해당사항 없고
    // 답글 메시지의 경우에는 답글을 달고 상태를 초기화 => 답글창 사라지게 하기 위해
    ref.read(replyMessageModelProvider.notifier).state = null;
  }

  // 그룹채팅방 목록 화면에서 그룹채팅방 들어가기
  void enterGroupChatFromGroupList({required GroupModel groupModel}) {
    try {
      loaderNotifier.show();
      state = state.copyWith(model: groupModel);
    } catch (_) {
      rethrow;
    } finally {
      loaderNotifier.hide();
    }
  }

  // 그룹채팅방 메시지 가져오기
  Future<void> getMessageList({
    String? lastMessageId,
    String? firstMessageId,
  }) async {
    try {
      final GroupModel groupModel = state.model as GroupModel;
      final messageList = await groupRepository.getMessageList(
        groupId: groupModel.id,
        lastMessageId: lastMessageId,
        firstMessageId: firstMessageId,
      );

      // 전체 메시지를 전달받을 경우 vs 기존의 메시지에 추가된 메시지만 받을 경우
      // 새롭게 추가된 메시지의 경우 기존 상태관리 데이터 뒤에 붙이기
      List<MessageModel> newMessageList = [
        if (lastMessageId != null) ...state.messageList,
        ...messageList,
        // firstMessageId 파라미터가 넘어 온다면 기존 메시지 붙이기
        if (firstMessageId != null) ...state.messageList,
      ];

      // 상태에 저장
      state = state.copyWith(
        messageList: newMessageList,
        // 더 가져올지 여부 결정
        // 새로운 메시지가 전송되었을 때 : lastMessageId != null
        // messageList.length : 20 // 현재 가져온 데이터가 20개, 더 가져올 데이터 있을 경우
        hasPrev: lastMessageId != null || messageList.length == 20,
      );
    } catch (_) {
      rethrow;
    }
  }

  // 채팅방 나가기
  Future<void> exitGroup({required GroupModel groupModel}) async {
    try {
      await groupRepository.exitGroup(
        groupModel: groupModel,
        currentUserId: currentUserModel.uid,
      );
    } catch (_) {
      rethrow;
    }
  }
}
