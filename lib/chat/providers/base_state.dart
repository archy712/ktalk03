import 'package:ktalk03/chat/models/message_model.dart';
import 'package:ktalk03/common/models/base_model.dart';

// 1:1 채팅방, 그룹 채팅방에서 공통적으로 사용하는 속성
abstract class BaseState {
  // 채팅방 기본 정보
  final BaseModel model;

  // 메시지 리스트
  final List<MessageModel> messageList;

  // 메시지를 더 가져올지 여부
  final bool hasPrev;

  const BaseState({
    required this.model,
    required this.messageList,
    required this.hasPrev,
  });
}
