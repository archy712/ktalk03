import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ktalk03/chat/models/message_model.dart';
import 'package:ktalk03/chat/providers/chat_provider.dart';
import 'package:ktalk03/chat/providers/chat_state.dart';
import 'package:ktalk03/chat/providers/message_provider.dart';
import 'package:ktalk03/chat/widgets/message_card_widget.dart';
import 'package:ktalk03/common/models/base_model.dart';
import 'package:ktalk03/common/models/chat_model.dart';
import 'package:ktalk03/common/providers/base_provider.dart';
import 'package:ktalk03/common/utils/logger.dart';
import 'package:ktalk03/group/providers/group_provider.dart';

class MessageListWidget extends ConsumerStatefulWidget {
  const MessageListWidget({super.key});

  @override
  ConsumerState<MessageListWidget> createState() => _MessageListWidgetState();
}

class _MessageListWidgetState extends ConsumerState<MessageListWidget> {
  // 메시지를 페이징 처리하기 위한 ScrollController
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _getMessageList();
    scrollController.addListener(scrollListener);
  }

  @override
  void dispose() {
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  // ScrollController Listener 적용 함수
  void scrollListener() {
    // final ChatState baseState = ref.read(chatProvider);

    final baseModel = ref.read(baseProvider);
    final provider = baseModel is ChatModel ? chatProvider : groupProvider;
    final baseState = ref.read(provider);

    // 얼만큼 스크롤 했는지 : scrollController.offset
    // 스크롤 가능한 최대 위치 : scrollController.maxScrollExtent
    if (baseState.hasPrev &&
        scrollController.offset >= scrollController.position.maxScrollExtent) {
      // ref
      //     .read(chatProvider.notifier)
      //     .getMessageList(
      //       firstMessageId: baseState.messageList.first.messageId,
      //     );
      baseModel is ChatModel
          ? ref
              .read(chatProvider.notifier)
              .getMessageList(
                firstMessageId: baseState.messageList.first.messageId,
              )
          : ref
              .read(groupProvider.notifier)
              .getMessageList(
                firstMessageId: baseState.messageList.first.messageId,
              );
    }
  }

  // 메시지 가져오는 함수
  // DB에서 정보를 가지고 와서 채팅정보 상태를 업데이트
  Future<void> _getMessageList() async {
    final baseModel = ref.read(baseProvider);

    baseModel is ChatModel
        ? await ref.read(chatProvider.notifier).getMessageList()
        : await ref.read(groupProvider.notifier).getMessageList();
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch 갯수를 줄이기 위해
    //final ChatState chatState = ref.watch(chatProvider);

    // 현재 들어와 있는 채팅방 정보 받아오기 (chatProvider, ChatState)
    //final BaseModel baseModel = ref.watch(chatProvider).model;
    //final BaseModel baseModel = chatState.model;

    // initState() 함수에서 페이지 로딩 시 상태관리 데이터로 저장을 했으므로
    // 상태관리 데이터를 가져온다.
    // final List<MessageModel> messageList = ref.watch(chatProvider).messageList;
    //final List<MessageModel> messageList = chatState.messageList;

    final baseModel = ref.read(baseProvider);
    final provider = baseModel is ChatModel ? chatProvider : groupProvider;
    final messageList = ref.watch(provider).messageList;

    final streamListProvider =
        baseModel is ChatModel ? chatListProvider : groupListProvider;

    // 지정된 Provider 가 업데이트 되었을 때 콜백 함수가 실행
    // 실시간 메시지가 업데이트 되었을 때 콜백함수 실행
    ref.listen(streamListProvider, (previous, next) {
      // 업데이트 후의 상태
      final List<BaseModel>? updateModelList = next.value;

      // 업데이트 후 상태의 속성 (List<ChatModel>) 중 첫번째 요소 (null 가능)
      // 첫번째 요소는 채팅방 중 최근에 업데이트 된 채팅방을 받을 수 있음 (orderby 날짜 내림차순)
      final BaseModel? updatedModel = updateModelList?.first;

      // 마지막 추가된 메시지
      final lastMessageId =
          messageList.isNotEmpty ? messageList.last.messageId : null;

      // updatedModelList 가 null 아니고
      // 최신 updatedModel 의 채팅방 ID가 현재 접속한 채팅방 ID와 같다면
      if (updateModelList != null && updatedModel!.id == baseModel.id) {
        //logger.d('참여중인 채팅방이 업데이트 됨');

        // 채팅 상태정보 ChatState 업데이트
        // ref
        //     .read(chatProvider.notifier)
        //     .getMessageList(lastMessageId: lastMessageId);
        baseModel is ChatModel
            ? ref
                .read(chatProvider.notifier)
                .getMessageList(lastMessageId: lastMessageId)
            : ref
                .read(groupProvider.notifier)
                .getMessageList(lastMessageId: lastMessageId);
      }
    });

    // 메시지 리스트 보여주기
    // return ListView.builder(
    //   controller: scrollController,
    //   reverse: true,
    //   itemCount: messageList.length,
    //   itemBuilder: (context, index) {
    //     final List<MessageModel> reverseMessageList =
    //         messageList.reversed.toList();
    //
    //     // return MessageCardWidget(
    //     //   messageModel: reverseMessageList[index],
    //     // );
    //
    //     // MessageCardWidget 내에서 사용하기 위해 ProviderScope 선언
    //     return ProviderScope(
    //       overrides: [
    //         // 파라미터에 상태관리 데이터로 등록할 MessageModel 전달
    //         messageProvider.overrideWithValue(reverseMessageList[index]),
    //       ],
    //       child: const MessageCardWidget(),
    //     );
    //   },
    // );

    return SingleChildScrollView(
      controller: scrollController,
      // 처음 위치를 밑으로 지정하지만, 순서를 뒤집지는 않는다.
      reverse: true,
      child: Column(
        children: [
          for (final item in messageList)
            ProviderScope(
              overrides: [
                // 파라미터에 상태관리 데이터로 등록할 MessageModel 전달
                messageProvider.overrideWithValue(item),
              ],
              child: const MessageCardWidget(),
            ),
        ],
      ),
    );
  }
}
