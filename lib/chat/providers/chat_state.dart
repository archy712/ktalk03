import 'package:ktalk03/chat/models/message_model.dart';
import 'package:ktalk03/chat/providers/base_state.dart';
import 'package:ktalk03/common/models/chat_model.dart';

class ChatState extends BaseState {
  // 부모 클래스 인자로 초기화
  ChatState({
    required super.model,
    required super.messageList,
    required super.hasPrev,
  });

  // factory 생성자
  factory ChatState.init() {
    return ChatState(model: ChatModel.init(), messageList: [], hasPrev: false);
  }

  // copyWith
  ChatState copyWith({
    ChatModel? model,
    List<MessageModel>? messageList,
    bool? hasPrev,
  }) {
    return ChatState(
      model: model ?? this.model,
      messageList: messageList ?? this.messageList,
      hasPrev: hasPrev ?? this.hasPrev,
    );
  }
}
