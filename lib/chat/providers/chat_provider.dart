import 'dart:io';

import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ktalk03/auth/models/user_model.dart';
import 'package:ktalk03/auth/providers/auth_provider.dart';
import 'package:ktalk03/chat/models/message_model.dart';
import 'package:ktalk03/chat/providers/chat_state.dart';
import 'package:ktalk03/chat/repositories/chat_repository.dart';
import 'package:ktalk03/common/enum/message_enum.dart';
import 'package:ktalk03/common/models/chat_model.dart';
import 'package:ktalk03/common/providers/loader_provider.dart';

// 답글 입력을 위한 MessageModel 저장 위해 Provider 선언
// 상태관리 데이터가 null 이면 일반 메시지, null 아니면 답글 메시지
final replyMessageModelProvider = AutoDisposeStateProvider<MessageModel?>(
  (ref) => null,
);

// 실시간 메시지 변경 시 채팅방 리스트를 반환하는 Provider : chatListProvider
// 반환 타입이 Stream<List<ChatModel>> 이므로 StreamProvider 사용
// 채팅방이 실시간 갱신되어야 해서 사용 후 자동 삭제되는 autoDispose 속성 사용
final chatListProvider = StreamProvider.autoDispose<List<ChatModel>>((ref) {
  final UserModel currentUserModel = ref.watch(authProvider).userModel;

  return ref
      .watch(chatRepositoryProvider)
      .getChatList(currentUserModel: currentUserModel);
});

// NotifierProvider 전역변수
final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  //ChatNotifier.new,
  () => ChatNotifier(),
);

// Notifier 확장 클래스
class ChatNotifier extends Notifier<ChatState> {
  // 로딩 화면을 보여주기 위함
  late LoaderNotifier loaderNotifier;

  // 채팅정보 데이터베이스 처리
  late ChatRepository chatRepository;

  // 현재 접속중인 사용자
  late UserModel currentUserModel;

  @override
  ChatState build() {
    // 클래스 멤버변수 초기화
    loaderNotifier = ref.watch(loaderProvider.notifier);
    chatRepository = ref.watch(chatRepositoryProvider);
    currentUserModel = ref.watch(authProvider).userModel;

    return ChatState.init();
  }

  // 채팅방 입장
  Future<void> enterChatFromFriendList({
    required Contact selectedContact,
  }) async {
    try {
      // 로딩화면 표시
      loaderNotifier.show();

      // ChatRepository 에서 채팅방 정보 반환
      final ChatModel chatModel = await chatRepository.enterChatFromFriendList(
        selectedContact: selectedContact,
      );

      // 상태관리 변수 (ChatState) 저장
      state = state.copyWith(model: chatModel);
    } catch (_) {
      rethrow;
    } finally {
      // 로딩화면 삭제
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
      await chatRepository.sendMessage(
        text: text,
        file: file,
        // state.model : baseModel 이므로 실제로 받아야 할 값으로 캐스팅
        chatModel: state.model as ChatModel,
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

  // 메시지 가져오기
  Future<void> getMessageList({
    String? lastMessageId,
    String? firstMessageId,
  }) async {
    try {
      final ChatModel chatModel = state.model as ChatModel;
      final List<MessageModel> messageList = await chatRepository
          .getMessageList(
            chatId: chatModel.id,
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

      // 상태관리 저장
      state = state.copyWith(
        messageList: newMessageList,
        // 더 가져올지 여부 결정
        // 새로운 메시지가 전송되었을 때 : lastMessageId != null
        // 현재 가져온 데이터가 20개, 더 가져올 데이터 있을 경우 : messageList.length 20
        hasPrev: lastMessageId != null || messageList.length == 20,
      );
    } catch (_) {
      rethrow;
    }
  }

  // 채팅방 목록에서 채팅방 입장
  void enterChatFromChatList({required ChatModel chatModel}) {
    try {
      loaderNotifier.show();
      state = state.copyWith(model: chatModel);
    } catch (_) {
      rethrow;
    } finally {
      loaderNotifier.hide();
    }
  }

  // 채팅방 삭제
  Future<void> exitChat({required ChatModel chatModel}) async {
    try {
      await chatRepository.exitChat(
        chatModel: chatModel,
        currentUserId: currentUserModel.uid,
      );
    } catch (_) {
      rethrow;
    }
  }
}
