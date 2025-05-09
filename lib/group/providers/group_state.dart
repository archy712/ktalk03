import 'package:ktalk03/chat/models/message_model.dart';
import 'package:ktalk03/chat/providers/base_state.dart';
import 'package:ktalk03/group/models/group_model.dart';

class GroupState extends BaseState {
  GroupState({
    required super.model,
    required super.messageList,
    required super.hasPrev,
  });

  // factory init() method
  factory GroupState.init() {
    return GroupState(
      model: GroupModel.init(),
      messageList: [],
      hasPrev: false,
    );
  }

  // copyWith
  GroupState copyWith({
    GroupModel? model,
    List<MessageModel>? messageList,
    bool? hasPrev,
  }) {
    return GroupState(
      model: model ?? this.model,
      messageList: messageList ?? this.messageList,
      hasPrev: hasPrev ?? this.hasPrev,
    );
  }
}
