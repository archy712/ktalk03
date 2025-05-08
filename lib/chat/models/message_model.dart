import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ktalk03/auth/models/user_model.dart';
import 'package:ktalk03/common/enum/message_enum.dart';

class MessageModel {
  // 메시지 작성자
  final String userId;

  // 메시지 내용
  final String text;

  // 메시지 타입
  final MessageEnum type;

  // 메시지 작성 시간
  final Timestamp createdAt;

  // 메시지 ID
  final String messageId;

  // 메시지 작성자 모델
  final UserModel userModel;

  // 답변 시 원본 메시지
  final MessageModel? replyMessageModel;

  // constructor
  const MessageModel({
    required this.userId,
    required this.text,
    required this.type,
    required this.createdAt,
    required this.messageId,
    required this.userModel,
    required this.replyMessageModel,
  });

  // toMap()
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'text': text,
      'type': type.name,
      'createdAt': createdAt,
      'messageId': messageId,
      'replyMessageModel': replyMessageModel?.toMap(),
    };
  }

  // fromMap()
  factory MessageModel.fromMap(Map<String, dynamic> map, UserModel userModel) {
    return MessageModel(
      userId: map['userId'],
      text: map['text'],
      type: (map['type'] as String).toEnum(),
      createdAt: map['createdAt'],
      messageId: map['messageId'],
      userModel: userModel,
      replyMessageModel:
          map['replyMessageModel'] == null
              ? null
              : MessageModel.fromMap(
                map['replyMessageModel'],
                // 답변 시 작성자는 필요치 않음 (위의 userId가 작성자)
                UserModel.init(),
              ),
    );
  }

  // copyWith()
  MessageModel copyWith({
    String? userId,
    String? text,
    MessageEnum? type,
    Timestamp? createdAt,
    String? messageId,
    UserModel? userModel,
    MessageModel? replyMessageModel,
  }) {
    return MessageModel(
      userId: userId ?? this.userId,
      text: text ?? this.text,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      messageId: messageId ?? this.messageId,
      userModel: userModel ?? this.userModel,
      //replyMessageModel: replyMessageModel ?? this.replyMessageModel,
      replyMessageModel: this.replyMessageModel,
    );
  }

  @override
  String toString() {
    return 'MessageModel{userId: $userId, text: $text, type: $type, createdAt: $createdAt, messageId: $messageId, userModel: $userModel, replyMessageModel: $replyMessageModel}';
  }
}
