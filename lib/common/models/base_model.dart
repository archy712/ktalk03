import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ktalk03/auth/models/user_model.dart';

abstract class BaseModel {
  // 채팅방 ID
  final String id;

  // 채팅방에서 가장 최근에 작성된 메시지
  final String lastMessage;

  // 채팅방에 참여중인 사용자 리스트
  final List<UserModel> userList;

  // 채팅방이 생성되거나 업데이트 된 날짜 데이터
  final Timestamp createdAt;

  // 생성자
  const BaseModel({
    required this.id,
    this.lastMessage = '',
    required this.userList,
    required this.createdAt,
  });
}
